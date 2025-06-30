#import "OWMetalViewController.h"
#import <Metal/Metal.h>
#import <simd/simd.h>

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
    [self setupMetal];
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

- (void)drawInMTKView:(MTKView *)view {
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if(!drawable) return;
    MTLRenderPassDescriptor *rpd = view.currentRenderPassDescriptor;
    if(!rpd) return;

    id<MTLCommandBuffer> cmd = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> enc = [cmd renderCommandEncoderWithDescriptor:rpd];
    [enc setRenderPipelineState:self.pipelineState];
    [enc setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [enc endEncoding];
    [cmd presentDrawable:drawable];
    [cmd commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
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

@end
