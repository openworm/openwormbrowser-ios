#import "OWMetalViewController.h"
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "OWAppDelegate.h"
#import "OWResource.h"
#import "OWEntityInfo.h"
#import "OWVector.h"
#import "OWNavigate.h"
#import "OWLayer.h"
#import "OWDrawGroup.h"
#import "OWDraw.h"
#import "OWInterpolant.h"

typedef struct {
    vector_float3 position;
    vector_float3 normal;
    vector_float2 texCoord;
} MetalVertex;

typedef struct {
    matrix_float4x4 mvp;
    vector_float4 color;
    vector_float3 lightDir;
    float ambient;
} Uniforms;

static inline matrix_float4x4 matrix_perspective(float fovyRadians, float aspect, float nearZ, float farZ) {
    float yScale = 1.0f / tanf(fovyRadians * 0.5f);
    float xScale = yScale / aspect;
    float zRange = nearZ - farZ;
    matrix_float4x4 m;
    m.columns[0] = (vector_float4){ xScale, 0, 0, 0 };
    m.columns[1] = (vector_float4){ 0, yScale, 0, 0 };
    m.columns[2] = (vector_float4){ 0, 0, (farZ + nearZ) / zRange, -1 };
    m.columns[3] = (vector_float4){ 0, 0, (2 * farZ * nearZ) / zRange, 0 };
    return m;
}

static inline matrix_float4x4 matrix_look_at(vector_float3 eye, vector_float3 center, vector_float3 up) {
    vector_float3 f = simd_normalize(center - eye);
    vector_float3 s = simd_normalize(simd_cross(f, up));
    vector_float3 u = simd_cross(s, f);

    matrix_float4x4 m;
    m.columns[0] = (vector_float4){ s.x, u.x, -f.x, 0 };
    m.columns[1] = (vector_float4){ s.y, u.y, -f.y, 0 };
    m.columns[2] = (vector_float4){ s.z, u.z, -f.z, 0 };
    m.columns[3] = (vector_float4){ -simd_dot(s, eye), -simd_dot(u, eye), simd_dot(f, eye), 1 };
    return m;
}

@interface OWMetalViewController ()
@property(nonatomic,strong) MTKView *mtkView;
@property(nonatomic,strong) id<MTLDevice> device;
@property(nonatomic,strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic,strong) id<MTLRenderPipelineState> shadingPipelineState;
@property(nonatomic,strong) id<MTLRenderPipelineState> pickingPipelineState;
@property(nonatomic,strong) id<MTLBuffer> uniformBuffer;
@property(nonatomic,strong) id<MTLBuffer> vertexBuffer;
@property(nonatomic,strong) id<MTLDepthStencilState> depthState;
@property(nonatomic,assign) float bodyOpacity;
@property(nonatomic,assign) BOOL cameraPill;

@property(nonatomic,assign) CGPoint lastPoint;
@property(nonatomic,assign) CGPoint lastPointDrag;
@property(nonatomic,assign) BOOL sliderIsVertical;
@property(nonatomic,assign) renderSetting currentRenderSetting;

@property(nonatomic,strong) OWNavigate *mNavigate;
@property(nonatomic,strong) NSMutableArray *mLayerOpacityInterpolants;
@property(nonatomic,strong) NSMutableArray *mLayers;
@property(nonatomic,strong) UIView *mLabelView;
@property(nonatomic,strong) UILabel *mSelectedLabel;
@property(nonatomic,strong) UIButton *mShowMetadata;
@property(nonatomic,strong) NSMutableArray *selectedObjects;
@property(nonatomic,assign) float globalOpacity;
@property(nonatomic,assign) BOOL paused;
@property(nonatomic,assign) matrix_float4x4 mvpMatrix;
@end

@implementation OWMetalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.device = MTLCreateSystemDefaultDevice();
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:self.device];
    self.mtkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mtkView.delegate = self;
    self.mtkView.preferredFramesPerSecond = 60;
    self.mtkView.clearColor = MTLClearColorMake(0.6, 0.8, 0.2, 1.0);  // kWormGreen background
    [self.view addSubview:self.mtkView];
    [self.view sendSubviewToBack:self.mtkView];  // Ensure MTKView is behind UI elements
    
    self.sliderIsVertical = YES;
    self.currentRenderSetting = renderSettingLow;
    self.globalOpacity = 1.0f;
    self.mvpMatrix = matrix_identity_float4x4;

    self.mNavigate = [[OWNavigate alloc] init];
    self.mLayers = [[NSMutableArray alloc] init];
    self.mLayerOpacityInterpolants = [[NSMutableArray alloc] init];
    self.selectedObjects = [[NSMutableArray alloc] init];
    for (int i = 0; i < NUMBER_OF_LAYERS; i++) {
        OWInterpolant *interp = [[OWInterpolant alloc] initWithValue:1.0f];
        [self.mLayerOpacityInterpolants addObject:interp];
    }

    [self loadLayers];

    self.mLabelView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, kBarThickness)];
    self.mLabelView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.mSelectedLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, self.view.frame.size.width - 20 - 30, kBarThickness)];
    self.mSelectedLabel.textColor = kSelectedLabelFontColor;
    self.mSelectedLabel.font = kMenuFontIphone;
    self.mSelectedLabel.textAlignment = NSTextAlignmentRight;
    self.mSelectedLabel.backgroundColor = [UIColor clearColor];
    [self.mLabelView addSubview:self.mSelectedLabel];
    [self.view addSubview:self.mLabelView];

    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(updatePan:)];
    panRecognizer.maximumNumberOfTouches = 1;
    panRecognizer.delegate = self;
    [self.view addGestureRecognizer:panRecognizer];

    UIPanGestureRecognizer *dragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragGesture:)];
    dragRecognizer.minimumNumberOfTouches = 2;
    dragRecognizer.delegate = self;
    [self.view addGestureRecognizer:dragRecognizer];

    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleZoomFromGestureRecognizer:)];
    pinchRecognizer.delegate = self;
    [self.view addGestureRecognizer:pinchRecognizer];

    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapRecognizer.numberOfTapsRequired = 3;
    [self.view addGestureRecognizer:doubleTapRecognizer];

    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTapRecognizer];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLayerOpacity:) name:kUpdateHorizontalSlider object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLayerOpacity:) name:kUpdateVerticalSlider object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSliderMode:) name:kToggleSliderMode object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectSingleObject:) name:kNotificationSelectSingleObject object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMetaDataForItem:) name:kNotificationShowMetaDataForItem object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearSelection:) name:kNotificationClearSelection object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetView:) name:kResetAllNotification object:nil];

    [self setupMetal];

    // Set aspect ratio before initial animation so zoom calculation works
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    self.mNavigate.aspectRatio = aspect;

    [self performSelector:@selector(animateToBaseEntity:) withObject:nil afterDelay:0.1];
}

- (void)setupMetal {
    self.commandQueue = [self.device newCommandQueue];
    self.mtkView.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    static const MetalVertex verts[] = {
        { { 0.0,  0.5, 0.0}, {0,0,1}, {0.5,1} },
        { {-0.5, -0.5,0.0}, {0,0,1}, {0,0} },
        { { 0.5, -0.5,0.0}, {0,0,1}, {1,0} }
    };
    self.vertexBuffer = [self.device newBufferWithBytes:verts length:sizeof(verts) options:MTLResourceStorageModeShared];

    NSError *error = nil;
    id<MTLLibrary> lib = [self.device newDefaultLibrary];
    id<MTLFunction> vert = [lib newFunctionWithName:@"lighting_vertex"];
    id<MTLFunction> frag = [lib newFunctionWithName:@"lighting_fragment"];
    MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.vertexFunction = vert;
    desc.fragmentFunction = frag;
    desc.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    // Enable alpha blending for layer transparency
    desc.colorAttachments[0].blendingEnabled = YES;
    desc.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    desc.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    desc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    desc.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    desc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    desc.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    desc.depthAttachmentPixelFormat = self.mtkView.depthStencilPixelFormat;

    MTLVertexDescriptor *vd = [[MTLVertexDescriptor alloc] init];
    vd.attributes[0].format = MTLVertexFormatFloat3;
    vd.attributes[0].offset = offsetof(MetalVertex, position);
    vd.attributes[0].bufferIndex = 0;
    vd.attributes[1].format = MTLVertexFormatFloat3;
    vd.attributes[1].offset = offsetof(MetalVertex, normal);
    vd.attributes[1].bufferIndex = 0;
    vd.attributes[2].format = MTLVertexFormatFloat2;
    vd.attributes[2].offset = offsetof(MetalVertex, texCoord);
    vd.attributes[2].bufferIndex = 0;
    vd.layouts[0].stride = sizeof(MetalVertex);
    desc.vertexDescriptor = vd;

    self.shadingPipelineState = [self.device newRenderPipelineStateWithDescriptor:desc error:&error];
    if(!self.shadingPipelineState) {
        NSLog(@"Failed to create pipeline state: %@", error);
    }

    id<MTLFunction> pickVert = [lib newFunctionWithName:@"picking_vertex"];
    id<MTLFunction> pickFrag = [lib newFunctionWithName:@"picking_fragment"];
    MTLRenderPipelineDescriptor *pdesc = [[MTLRenderPipelineDescriptor alloc] init];
    pdesc.vertexFunction = pickVert;
    pdesc.fragmentFunction = pickFrag;
    pdesc.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA8Unorm;
    pdesc.depthAttachmentPixelFormat = self.mtkView.depthStencilPixelFormat;
    pdesc.vertexDescriptor = vd;
    self.pickingPipelineState = [self.device newRenderPipelineStateWithDescriptor:pdesc error:&error];
    if(!self.pickingPipelineState) {
        NSLog(@"Failed to create picking pipeline state: %@", error);
    }

    MTLDepthStencilDescriptor *ds = [[MTLDepthStencilDescriptor alloc] init];
    ds.depthCompareFunction = MTLCompareFunctionLess;
    ds.depthWriteEnabled = YES;
    self.depthState = [self.device newDepthStencilStateWithDescriptor:ds];

    self.uniformBuffer = [self.device newBufferWithLength:sizeof(Uniforms) options:MTLResourceStorageModeShared];
}

- (OWLayer *)createLayerWithInfo:(int)info {
    OWLayer *layer = [[OWLayer alloc] initWithInfo:info];
    float initialOpacity = (info == layerCuticle) ? 1.0f : 0.0f;
    OWInterpolant *interp = [[OWInterpolant alloc] initWithValue:initialOpacity];
    [self.mLayerOpacityInterpolants addObject:interp];
    layer.opacity = interp;
    layer.renderOpacity = initialOpacity;
    return layer;
}

- (void)loadLayers {
    for (int i = 0; i < NUMBER_OF_LAYERS; i++) {
        OWLayer *layer = [self createLayerWithInfo:i];
        [self.mLayers addObject:layer];
    }

#if TARGET_IPHONE_SIMULATOR
    [self loadLayersAsync:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAllLayersLoaded object:nil];
#else
    [self performSelectorInBackground:@selector(loadLayersAsync:) withObject:nil];
#endif
}

- (void)loadLayersAsync:(id)sender {
    for (OWLayer *layer in self.mLayers) {
        [layer loadDrawGroups];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAllLayersLoaded object:nil];
}

- (void)prepareDrawForLayer:(OWLayer *)layer {
    for (OWDrawGroup *group in layer.drawGroups) {
        if (!group.mtlVertexBuffer && group.vertexBufferData) {
            uint16_t maxIndex = 0;
            for (uint32_t i = 0; i < group.numIndices; i++) {
                if (group.indexBufferData[i] > maxIndex) maxIndex = group.indexBufferData[i];
            }
            group.vertexCount = (NSUInteger)maxIndex + 1;
            size_t vlen = sizeof(vertexDataTextured) * group.vertexCount;
            group.mtlVertexBuffer = [self.device newBufferWithBytes:group.vertexBufferData length:vlen options:MTLResourceStorageModeShared];
            free(group.vertexBufferData);
            group.vertexBufferData = NULL;
        }
        if (!group.mtlIndexBuffer && group.indexBufferData) {
            size_t ilen = sizeof(uint16_t) * group.numIndices;
            group.mtlIndexBuffer = [self.device newBufferWithBytes:group.indexBufferData length:ilen options:MTLResourceStorageModeShared];
            free(group.indexBufferData);
            group.indexBufferData = NULL;
        }
    }
}

- (void)drawElementsForGroup:(OWDrawGroup *)group encoder:(id<MTLRenderCommandEncoder>)enc offset:(uint32_t)offset count:(uint32_t)count uniforms:(Uniforms)uniforms {
    if (!group.mtlVertexBuffer || !group.mtlIndexBuffer) return;
    [enc setVertexBuffer:group.mtlVertexBuffer offset:0 atIndex:0];
    // Use setBytes for uniforms - copies data inline, ensuring per-draw-call isolation
    // This fixes the issue where modifying a shared buffer in a loop causes all draws to see the last value
    [enc setVertexBytes:&uniforms length:sizeof(Uniforms) atIndex:1];
    [enc setFragmentBytes:&uniforms length:sizeof(Uniforms) atIndex:1];
    [enc drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:count indexType:MTLIndexTypeUInt16 indexBuffer:group.mtlIndexBuffer indexBufferOffset:offset * 2];
}

- (void)drawOneGeometryOnly:(OWLayer *)layer withGeometry:(NSString *)geometry encoder:(id<MTLRenderCommandEncoder>)enc {
    for (OWDrawGroup *dg in layer.drawGroups) {
        Uniforms uniforms;
        uniforms.mvp = self.mvpMatrix;
        uniforms.lightDir = (vector_float3){-1, 0.3, 0.5};
        uniforms.ambient = 0.4f;
        uniforms.color = (vector_float4){dg.diffuseColor.x, dg.diffuseColor.y, dg.diffuseColor.z, 1.0f};

        for (OWDraw *draw in dg.draws) {
            if ([draw.geometry isEqualToString:geometry]) {
                [self drawElementsForGroup:dg encoder:enc offset:draw.offset count:draw.count uniforms:uniforms];
            }
        }
    }
}

- (void)drawOWLayer:(OWLayer *)layer withOpacity:(float)opacity encoder:(id<MTLRenderCommandEncoder>)enc {
    if (!layer.isLoaded) return;

    for (OWDrawGroup *dg in layer.drawGroups) {
        // Create uniforms struct for each draw group with its specific color
        Uniforms uniforms;
        uniforms.mvp = self.mvpMatrix;
        uniforms.lightDir = (vector_float3){-1, 0.3, 0.5};  // Light from camera direction
        uniforms.ambient = 0.4f;  // Moderate ambient for visible shading
        // Use diffuse color from materials (resource loader provides fallback for missing materials)
        uniforms.color = (vector_float4){dg.diffuseColor.x, dg.diffuseColor.y, dg.diffuseColor.z, opacity};

        for (OWDraw *draw in dg.draws) {
            [self drawElementsForGroup:dg encoder:enc offset:draw.offset count:draw.count uniforms:uniforms];
        }
    }
}

- (void)drawFadedLayer:(OWLayer *)layer encoder:(id<MTLRenderCommandEncoder>)enc {
    [self drawOWLayer:layer withOpacity:0.1f encoder:enc];
}

- (void)drawSelectOWLayer:(OWLayer *)layer withOpacity:(float)opacity encoder:(id<MTLRenderCommandEncoder>)enc {
    [self drawOWLayer:layer withOpacity:opacity encoder:enc];
}

- (void)drawSelectOWLayerCorrected:(OWLayer *)layer withOpacity:(float)opacity encoder:(id<MTLRenderCommandEncoder>)enc {
    [self drawSelectOWLayer:layer withOpacity:opacity encoder:enc];
}

- (NSUInteger)findObjectByPoint:(CGPoint)point {
    NSUInteger result = NSNotFound;
    MTLTextureDescriptor *td = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:1 height:1 mipmapped:NO];
    td.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    id<MTLTexture> tex = [self.device newTextureWithDescriptor:td];
    MTLRenderPassDescriptor *rpd = [MTLRenderPassDescriptor renderPassDescriptor];
    rpd.colorAttachments[0].texture = tex;
    rpd.colorAttachments[0].loadAction = MTLLoadActionClear;
    rpd.colorAttachments[0].storeAction = MTLStoreActionStore;
    rpd.colorAttachments[0].clearColor = MTLClearColorMake(1,1,1,1);
    id<MTLCommandBuffer> cmd = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> enc = [cmd renderCommandEncoderWithDescriptor:rpd];
    [enc setRenderPipelineState:self.pickingPipelineState];
    [enc setDepthStencilState:self.depthState];

    for (NSUInteger li = 0; li < self.mLayers.count; li++) {
        OWLayer *layer = self.mLayers[li];
        if(!layer.isLoaded) continue;
        for (NSUInteger gi = 0; gi < layer.drawGroups.count; gi++) {
            OWDrawGroup *dg = layer.drawGroups[gi];
            for (NSUInteger di = 0; di < dg.draws.count; di++) {
                OWDraw *draw = dg.draws[di];
                Uniforms uniforms;
                uniforms.mvp = self.mvpMatrix;
                uniforms.lightDir = (vector_float3){0,0,1};
                uniforms.ambient = 0.0f;
                uniforms.color = (vector_float4){draw.selectColor.x, draw.selectColor.y, draw.selectColor.z, 1.0};
                [self drawElementsForGroup:dg encoder:enc offset:draw.offset count:draw.count uniforms:uniforms];
            }
        }
    }
    [enc endEncoding];
    [cmd commit];
    [cmd waitUntilCompleted];

    uint8_t pixel[4] = {0};
    MTLRegion reg = MTLRegionMake2D(0,0,1,1);
    [tex getBytes:pixel bytesPerRow:4 fromRegion:reg mipmapLevel:0];
    if(pixel[0] != 255) {
        NSUInteger layerIdx = pixel[0];
        NSUInteger dgIdx = pixel[1];
        NSUInteger dIdx = pixel[2];
        if(layerIdx < self.mLayers.count) {
            OWLayer *layer = self.mLayers[layerIdx];
            OWDrawGroup *dg = layer.drawGroups[dgIdx];
            OWDraw *draw = dg.draws[dIdx];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSelectSingleObject object:draw.geometry];
            result = layerIdx;
        }
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationClearSelection object:nil];
    }
    return result;
}

- (void)renderNormal:(id<MTLRenderCommandEncoder>)enc {
    for (NSUInteger idx = 0; idx < self.mLayers.count; idx++) {
        OWLayer *layer = self.mLayers[idx];
        float opacity = 1.0f;
        if (idx < self.mLayerOpacityInterpolants.count) {
            opacity = ((OWInterpolant *)self.mLayerOpacityInterpolants[idx]).present;
        }
        opacity *= self.globalOpacity;
        [self drawOWLayer:layer withOpacity:opacity encoder:enc];
    }
}

- (void)renderSelect:(id<MTLRenderCommandEncoder>)enc {
    [self renderNormal:enc];
}

- (void)drawInMTKView:(MTKView *)view {
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if(!drawable) return;
    MTLRenderPassDescriptor *rpd = view.currentRenderPassDescriptor;
    if(!rpd) return;

    [self update];

    id<MTLCommandBuffer> cmd = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> enc = [cmd renderCommandEncoderWithDescriptor:rpd];
    [enc setRenderPipelineState:self.shadingPipelineState];
    [enc setDepthStencilState:self.depthState];

    Uniforms *uni = (Uniforms *)self.uniformBuffer.contents;
    uni->mvp = self.mvpMatrix;

    // Layer indices - must match enum in OWDefines.h
    const NSUInteger layerCuticle = 0;  // Outermost skin layer
    const NSUInteger layerNeurons = 1;  // Nervous system (innermost)
    const NSUInteger layerMuscle = 2;   // Muscle/reproductive
    const NSUInteger layerOrgans = 3;   // Digestive system

    if (self.sliderIsVertical && self.mLayers.count >= 4) {
        // Staged opacity: slider progressively reveals inner layers
        // Render order: neurons (innermost) → muscles → organs → cuticle (outermost)
        OWLayer *cuticleLayer = self.mLayers[layerCuticle];
        OWLayer *organLayer = self.mLayers[layerOrgans];
        OWLayer *neuronLayer = self.mLayers[layerNeurons];
        OWLayer *muscleLayer = self.mLayers[layerMuscle];

        [self prepareDrawForLayer:neuronLayer];
        [self prepareDrawForLayer:muscleLayer];
        [self prepareDrawForLayer:organLayer];
        [self prepareDrawForLayer:cuticleLayer];

        float go = self.globalOpacity;

        // Match original GL behavior with smooth layer transitions
        if (go >= 0.95f) {
            // Very top of slider: just organs peek through under cuticle
            [self drawOWLayer:organLayer withOpacity:1.0f encoder:enc];
            [self drawOWLayer:cuticleLayer withOpacity:(go - 0.75f) * 4.0f encoder:enc];
        } else if (go >= 0.75f) {
            // All layers visible, cuticle fading (0.95→0.75 = cuticle fades to 0)
            [self drawOWLayer:neuronLayer withOpacity:1.0f encoder:enc];
            [self drawOWLayer:muscleLayer withOpacity:1.0f encoder:enc];
            [self drawOWLayer:organLayer withOpacity:1.0f encoder:enc];
            [self drawOWLayer:cuticleLayer withOpacity:(go - 0.75f) * 4.0f encoder:enc];
        } else if (go >= 0.5f) {
            // Neurons + muscles visible, organs fading
            [self drawOWLayer:neuronLayer withOpacity:1.0f encoder:enc];
            [self drawOWLayer:muscleLayer withOpacity:1.0f encoder:enc];
            [self drawOWLayer:organLayer withOpacity:(go - 0.5f) * 4.0f encoder:enc];
        } else if (go >= 0.25f) {
            // Neurons visible, muscles fading
            [self drawOWLayer:neuronLayer withOpacity:1.0f encoder:enc];
            [self drawOWLayer:muscleLayer withOpacity:(go - 0.25f) * 4.0f encoder:enc];
        } else {
            // Bottom of slider: neurons at full opacity (innermost layer stays visible)
            [self drawOWLayer:neuronLayer withOpacity:1.0f encoder:enc];
        }
    } else {
        // Horizontal slider mode: individual layer opacities via interpolants
        for (NSUInteger idx = 0; idx < self.mLayers.count; idx++) {
            OWLayer *layer = self.mLayers[idx];
            [self prepareDrawForLayer:layer];
            float opacity = 1.0f;
            if (idx < self.mLayerOpacityInterpolants.count) {
                OWInterpolant *interp = self.mLayerOpacityInterpolants[idx];
                opacity = interp.present;
            }
            [self drawOWLayer:layer withOpacity:opacity encoder:enc];
        }
    }

    [enc endEncoding];
    [cmd presentDrawable:drawable];
    [cmd commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        BOOL isLandscape = size.width > size.height;
        if (isLandscape) {
            [self.mNavigate setAspectRatio:fabs(size.height / size.width)];
        } else {
            [self.mNavigate setAspectRatio:fabs(size.width / size.height)];
        }
        [self.mNavigate recalculate];
    } completion:nil];
}

- (void)update {
    [self.mNavigate recalculate];
    [OWInterpolant tweenAll:self.mLayerOpacityInterpolants];

    OWCamera *cam = [self.mNavigate getCamera];
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    self.mNavigate.aspectRatio = aspect;  // Set aspect ratio for zoom calculations
    matrix_float4x4 proj = matrix_perspective(OWDegreesToRadians(40.0f), aspect, 0.1f, 250.0f);
    vector_float3 eye = {cam.eye.x, cam.eye.y, cam.eye.z};
    vector_float3 target = {cam.target.x, cam.target.y, cam.target.z};
    vector_float3 up = {cam.up.x, cam.up.y, cam.up.z};
    matrix_float4x4 view = matrix_look_at(eye, target, up);
    self.mvpMatrix = matrix_multiply(proj, view);
}

#pragma mark - Public API
- (void)setBodyOpacity:(float)opac {
    self.bodyOpacity = opac;
}

- (void)toggleCameraMode {
    self.cameraPill = !self.cameraPill;
}

- (BOOL)isCameraPill {
    return self.cameraPill;
}

- (void)setPaused:(BOOL)paused {
    _paused = paused;
    self.mtkView.paused = paused;
}

#pragma mark - Notification handlers
- (void)resetView:(NSNotification *)n {
    [self animateToBaseEntity:nil];
}

- (void)animateToBaseEntity:(id)sender {
    OWAppDelegate *delegate = AppDelegate;
    OWResource *resource = delegate.resource;
    OWEntityInfo *info = [resource getInfoForEntityName:@"cuticle"];
    [self.mNavigate goToForEntity:info withUrgency:0.12];
    [self.mNavigate.mRotateLocalY setFuture:0 withUrgency:0.12];
    [self.mNavigate.mRotateLocalX setFuture:0 withUrgency:0.12];
    [self.mNavigate.mTranslateLocalX setFuture:0 withUrgency:0.12];
    [self.mNavigate.mTranslateLocalY setFuture:0 withUrgency:0.12];
    [self.mNavigate.mTranslateLocalZ setFuture:0 withUrgency:0.12];
}

- (void)selectSingleObject:(NSNotification *)notification {
    NSString *nameToSelect = [notification object];
    if (!nameToSelect) return;
    OWAppDelegate *delegate = AppDelegate;
    OWResource *resource = delegate.resource;
    OWEntityInfo *info = [resource getInfoForEntityName:nameToSelect];
    [self.selectedObjects removeAllObjects];
    [self.selectedObjects addObject:info];
    self.mSelectedLabel.text = nameToSelect;
}

- (void)showMetaDataForItem:(NSNotification *)notification {
    // placeholder for metadata handling
    (void)notification;
}

- (void)clearSelection:(NSNotification *)notification {
    (void)notification;
    [self.selectedObjects removeAllObjects];
}

- (void)updateLayerOpacity:(NSNotification *)notification {
    if ([notification.name isEqualToString:kUpdateVerticalSlider]) {
        NSNumber *val = notification.object;
        self.globalOpacity = 1 - val.floatValue;
    } else {
        // Horizontal slider: values come in order [cuticle, organs, muscle, neurons]
        // but need to map to interpolant indices that match layer enum order
        NSArray *vals = notification.object;
        for (int i = 0; i < vals.count && i < self.mLayerOpacityInterpolants.count; i++) {
            NSNumber *val = vals[i];
            int interpolantIndex;
            switch (i) {
                case 0: interpolantIndex = 0; break;  // cuticle → 0
                case 1: interpolantIndex = 3; break;  // organs → 3
                case 2: interpolantIndex = 2; break;  // muscle → 2
                case 3: interpolantIndex = 1; break;  // neurons → 1
                default: interpolantIndex = i; break;
            }
            OWInterpolant *interp = self.mLayerOpacityInterpolants[interpolantIndex];
            [interp setFuture:[val floatValue] withUrgency:0.25];
        }
    }
}

- (void)updateSliderMode:(NSNotification *)notification {
    (void)notification;
    self.sliderIsVertical = !self.sliderIsVertical;
}

#pragma mark - Gesture handlers
- (void)updatePan:(UIPanGestureRecognizer *)r {
    CGPoint translatedPoint = [r translationInView:self.view];
    CGPoint deltaPoint = CGPointMake(translatedPoint.x - self.lastPoint.x, translatedPoint.y - self.lastPoint.y);
    if (r.state == UIGestureRecognizerStateChanged) {
        if (hypotf(deltaPoint.x, deltaPoint.y) > 3.0f) {
            self.lastPoint = translatedPoint;
            [self.mNavigate handlePrimaryTouchDelta:deltaPoint withAbsolute:translatedPoint];
        }
    } else if (r.state == UIGestureRecognizerStateBegan) {
        self.lastPoint = translatedPoint;
    }
}

- (void)handleDragGesture:(UIPanGestureRecognizer *)r {
    CGPoint translatedPoint = [r translationInView:self.view];
    CGPoint deltaPoint = CGPointMake(translatedPoint.x - self.lastPointDrag.x, translatedPoint.y - self.lastPointDrag.y);
    if (r.state == UIGestureRecognizerStateChanged) {
        if (hypotf(deltaPoint.x, deltaPoint.y) > 3.0f) {
            self.lastPointDrag = translatedPoint;
            [self.mNavigate handleSecondaryTouchDelta:deltaPoint withAbsolute:translatedPoint];
        }
    } else if (r.state == UIGestureRecognizerStateBegan) {
        self.lastPointDrag = translatedPoint;
    }
}

- (void)handleZoomFromGestureRecognizer:(UIPinchGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self.mNavigate setZoomStart];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        [self.mNavigate handleZoomScale:sender.scale];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint tapLocation = [recognizer locationInView:recognizer.view];
    NSLog(@"Tap at %@", NSStringFromCGPoint(tapLocation));
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    (void)recognizer;
    [self animateToBaseEntity:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateCameraSetting object:nil];
}

@end
