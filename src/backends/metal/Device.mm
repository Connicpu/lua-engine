#include "Device.h"
#include "Sprite.h"

static const long kInFlightCommandBuffers = 3;

static const sprite_vertex kQuadVertices[] =
{
    { vec2{ -0.5f, 0.5f }, vec2{ 0, 0 } },
    { vec2{ -0.5f, -0.5f }, vec2{ 0, 1 } },
    { vec2{ 0.5f, -0.5f }, vec2{ 1, 1 } },

    { vec2{ -0.5f, 0.5f }, vec2{ 0, 0 } },
    { vec2{ 0.5f, -0.5f }, vec2{ 1, 1 } },
    { vec2{ 0.5f, 0.5f }, vec2{ 1, 0 } },
};

@implementation CNNRDevice
{
    // Device state
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLLibrary> _shaders;
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLBuffer> _quadVertexBuffer;
}

-(instancetype)initWithParams:(const device_params *)params {
    drop(params); // I don't know what to do with these yet
    
    self = [super init];
    if (self)
    {
        if (![self initDeviceState] ||
            ![self initShaders] ||
            ![self initBuffers])
            return nil;
    }
    return self;
}

-(bool)initDeviceState {
    self._device = MTLCreateSystemDefaultDevice();
    if (self._device == nil)
        return set_error_and_ret(false, "Failed to create Metal device");

    self._commandQueue = [self._device makeCommandQueue];
}

-(bool)initShaders {
    self._shaders = [self._device newDefaultLibrary];

    auto pipeDesc = [MTLRenderPipelineDescriptor new];
    pipeDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipeDesc.vertexFunction = [self._shaders newFunctionWithName:@"SpriteVertex"];
    pipeDesc.fragmentFunction = [self._shaders newFunctionWithName:@"SpriteFragment"];

    NSError *error = [[NSError alloc] init];
    self._pipelineState = [self._device newRenderPipelineState:pipeDesc,
                                                         error:&error];
    
}

-(bool)initBuffers {
    #ifdef MACOS
    auto storage = MTLResourceStorageModeShared;
    #else
    auto storage = MTLResourceStorageModeManaged;
    #endif

    self._quadVertexBuffer = [self._device newBufferWithBytesNoCopy:kQuadVertices,
                                                             length:sizeof(kQuadVertices),
                                                            options:storage,
                                                        deallocator:nil];
    if (self._quadVertexBuffer == nil)
        return set_error_and_ret(false, "Failed to create Vertex Buffer");
}

@end

device *rd_create_device(const device_params *params)
{
    id dev = [[CNNRDevice alloc] initWithParams: params];
    return from_objc<device>(dev);
}

void rd_free_device(device *dev)
{
    drop(into_objc<CNNRDevice>(dev));
}
