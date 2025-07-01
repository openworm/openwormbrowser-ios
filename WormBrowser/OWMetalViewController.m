#import "OWMetalViewController.h"
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "OWAppDelegate.h"
#import "OWResource.h"
#import "OWEntityInfo.h"

typedef struct {
    vector_float3 position;
    vector_float3 normal;
    vector_float2 texCoord;
} MetalVertex;

@interface OWMetalViewController ()
@property(nonatomic,strong) MTKView *mtkView;
@property(nonatomic,strong) id<MTLDevice> device;
@property(nonatomic,strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic,strong) id<MTLRenderPipelineState> pipelineState;
@property(nonatomic,strong) id<MTLBuffer> vertexBuffer;
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
@end

@implementation OWMetalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.device = MTLCreateSystemDefaultDevice();
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:self.device];
    self.mtkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mtkView.delegate = self;
    self.mtkView.preferredFramesPerSecond = 60;
    [self.view addSubview:self.mtkView];
    
    self.sliderIsVertical = YES;
    self.currentRenderSetting = renderSettingLow;
    self.globalOpacity = 1.0f;

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

    [self performSelector:@selector(animateToBaseEntity:) withObject:nil afterDelay:0.1];
}

- (void)setupMetal {
    self.commandQueue = [self.device newCommandQueue];
    static const MetalVertex verts[] = {
        { { 0.0,  0.5, 0.0}, {0,0,1}, {0.5,1} },
        { {-0.5, -0.5,0.0}, {0,0,1}, {0,0} },
        { { 0.5, -0.5,0.0}, {0,0,1}, {1,0} }
    };
    self.vertexBuffer = [self.device newBufferWithBytes:verts length:sizeof(verts) options:MTLResourceStorageModeShared];

    NSError *error = nil;
    id<MTLLibrary> lib = [self.device newDefaultLibrary];
    id<MTLFunction> vert = [lib newFunctionWithName:@"basic_vertex"];
    id<MTLFunction> frag = [lib newFunctionWithName:@"basic_fragment"];
    MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.vertexFunction = vert;
    desc.fragmentFunction = frag;
    desc.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;

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

    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:desc error:&error];
    if(!self.pipelineState) {
        NSLog(@"Failed to create pipeline state: %@", error);
    }
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

- (void)drawElementsForGroup:(OWDrawGroup *)group encoder:(id<MTLRenderCommandEncoder>)enc offset:(uint32_t)offset count:(uint32_t)count {
    if (!group.mtlVertexBuffer || !group.mtlIndexBuffer) return;
    [enc setVertexBuffer:group.mtlVertexBuffer offset:0 atIndex:0];
    [enc drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:count indexType:MTLIndexTypeUInt16 indexBuffer:group.mtlIndexBuffer indexBufferOffset:offset * 2];
}

- (void)drawOneGeometryOnly:(OWLayer *)layer withGeometry:(NSString *)geometry encoder:(id<MTLRenderCommandEncoder>)enc {
    for (OWDrawGroup *dg in layer.drawGroups) {
        for (OWDraw *draw in dg.draws) {
            if ([draw.geometry isEqualToString:geometry]) {
                [self drawElementsForGroup:dg encoder:enc offset:draw.offset count:draw.count];
            }
        }
    }
}

- (void)drawOWLayer:(OWLayer *)layer withOpacity:(float)opacity encoder:(id<MTLRenderCommandEncoder>)enc {
    if (!layer.isLoaded) return;
    for (OWDrawGroup *dg in layer.drawGroups) {
        for (OWDraw *draw in dg.draws) {
            [self drawElementsForGroup:dg encoder:enc offset:draw.offset count:draw.count];
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
    NSLog(@"Selection at %@ not implemented", NSStringFromCGPoint(point));
    return NSNotFound;
}

- (void)renderNormal:(id<MTLRenderCommandEncoder>)enc {
    for (NSUInteger idx = 0; idx < self.mLayers.count; idx++) {
        OWLayer *layer = self.mLayers[idx];
        float opacity = 1.0f;
        if (idx < self.mLayerOpacityInterpolants.count) {
            opacity = ((OWInterpolant *)self.mLayerOpacityInterpolants[idx]).present;
        }
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
    [enc setRenderPipelineState:self.pipelineState];

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
            [self.mNavigate setAspectRatio:fabsf(size.height / size.width)];
        } else {
            [self.mNavigate setAspectRatio:fabsf(size.width / size.height)];
        }
        [self.mNavigate recalculate];
    } completion:nil];
}

- (void)update {
    [self.mNavigate recalculate];
    [OWInterpolant tweenAll:self.mLayerOpacityInterpolants];
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
    self.paused = paused;
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
        NSArray *vals = notification.object;
        for (int i = 0; i < vals.count && i < self.mLayerOpacityInterpolants.count; i++) {
            OWInterpolant *interp = self.mLayerOpacityInterpolants[i];
            [interp setFuture:[vals[i] floatValue] withUrgency:0.25];
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
