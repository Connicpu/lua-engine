#import "CNDevice.h"
#import "Sprite.h"

static sprite_vertex kQuadVertices[] =
{
    { vec2{ -0.5f, 0.5f }, vec2{ 0, 0 } },
    { vec2{ -0.5f, -0.5f }, vec2{ 0, 1 } },
    { vec2{ 0.5f, -0.5f }, vec2{ 1, 1 } },

    { vec2{ -0.5f, 0.5f }, vec2{ 0, 0 } },
    { vec2{ 0.5f, -0.5f }, vec2{ 1, 1 } },
    { vec2{ 0.5f, 0.5f }, vec2{ 1, 0 } },
};

@implementation CNDevice
{
    // Device state
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLLibrary> _shaders;
    id<MTLRenderPipelineState> _normalPipeline;
    id<MTLRenderPipelineState> _pixelArtPipeline;
    id<MTLBuffer> _quadVertexBuffer;
    
    id<MTLCommandBuffer> _currentCmdBuffer;
}

-(void)startCommands
{
}

-(void)useNormalShader
{
    
}

-(void)usePixelArtShader
{
    
}

-(void)setTexture:(CNTextureArray *)array
{
    drop(array);
}

-(void)drawWithInstances:(id<MTLBuffer>)instances
{
    drop(instances);
}

-(void)commitCommands
{
    
}

-(instancetype)initWithParams:(const device_params *)params
{
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

-(bool)initDeviceState
{
    _device = MTLCreateSystemDefaultDevice();
    if (_device == nil)
        return set_error_and_ret(false, "Failed to create Metal device");

    _commandQueue = [_device newCommandQueue];
    
    return true;
}

-(bool)initShaders
{
    _shaders = [_device newDefaultLibrary];

    auto pipeDesc = [MTLRenderPipelineDescriptor new];
    pipeDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipeDesc.vertexFunction = [_shaders newFunctionWithName:@"SpriteVertex"];
    pipeDesc.fragmentFunction = [_shaders newFunctionWithName:@"SpriteFragment"];

    NSError *error = [[NSError alloc] init];
    _normalPipeline = [_device newRenderPipelineStateWithDescriptor:pipeDesc
                                                              error:&error];
    
    pipeDesc.fragmentFunction = [_shaders newFunctionWithName:@"SpritePixelFragment"];
    
    error = [[NSError alloc] init];
    _pixelArtPipeline = [_device newRenderPipelineStateWithDescriptor:pipeDesc
                                                                error:&error];
    
    return true;
    
}

-(bool)initBuffers
{
    _quadVertexBuffer = [_device newBufferWithBytesNoCopy:kQuadVertices
                                                   length:sizeof(kQuadVertices)
                                                  options:kResourceOptions
                                              deallocator:nil];
    if (_quadVertexBuffer == nil)
        return set_error_and_ret(false, "Failed to create Vertex Buffer");
    
    return true;
}

@end

device *rd_create_device(const device_params *params)
{
    id dev = [[CNDevice alloc] initWithParams: params];
    return from_objc<device>(dev);
}

void rd_free_device(device *dev)
{
    drop(into_objc<CNDevice>(dev));
}
