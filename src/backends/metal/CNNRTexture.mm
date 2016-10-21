#import "CNNRTexture.h"
#import "CNNRDevice.h"

@implementation CNNRTextureArray

-(instancetype)initWithParams:(const texture_array_params *)params
                   withDevice:(CNNRDevice *)device
{
    self = [super init];
    if (self)
    {
        _streaming = params->streaming;
        _isPixelArt = params->pixel_art;
        _spriteCount = params->sprite_count;
        _width = params->sprite_width;
        _height = params->sprite_height;
        
        auto textures = [NSMutableArray array];
        for (uint32_t i = 0; i < _spriteCount; ++i)
        {
            auto entry = [CNNRTexture newForIndex:i
                                        withArray:self];
            [textures addObject:entry];
        }
        _textures = textures;
        
        auto desc = [MTLTextureDescriptor new];
        desc.textureType = MTLTextureType2DArray;
        desc.pixelFormat = MTLPixelFormatRGBA8Unorm;
        desc.arrayLength = _spriteCount;
        desc.width = _width;
        desc.height = _height;
        desc.resourceOptions = kResourceOptions;
        desc.cpuCacheMode = MTLCPUCacheModeWriteCombined;
        desc.storageMode = kStorageMode;
        desc.usage = MTLTextureUsageShaderRead;
        _textureArray = [device.device newTextureWithDescriptor:desc];
        if (!_textureArray)
            return set_error_and_ret(nil, "Failed to create TextureArray");
        
        if (params->buffers)
        {
            for (uint32_t i = 0; i < _spriteCount; ++i)
            {
                auto data = params->buffers[i];
                [self updateTextureAt:i
                             withData:data];
            }
        }
    }
    return self;
}

-(void)updateTextureAt:(uint32_t)index
              withData:(const void *)data
{
    MTLRegion region =
    {
        { 0, 0, 0 },
        { _width, _height, 1 },
    };
    
    [_textureArray replaceRegion:region
                     mipmapLevel:0
                           slice:index
                       withBytes:data
                     bytesPerRow:_width * 4
                   bytesPerImage:_width * _height * 4];
}

@end

@implementation CNNRTexture

+(instancetype) newForIndex:(uint32_t)index
                  withArray:(CNNRTextureArray *)array
{
    return [[CNNRTexture alloc] initForIndex:index
                                   withArray:array];
}
-(instancetype) initForIndex:(uint32_t)index
                   withArray:(CNNRTextureArray *)array
{
    self = [super init];
    _index = index;
    _array = array;
    return self;
}

@end

texture_array *rd_create_texture_array(device *dev, const texture_array_params *params)
{
    auto device = ref_objc<CNNRDevice>(dev);
    auto texture = [[CNNRTextureArray alloc] initWithParams:params
                                                 withDevice:device];
    return from_objc<texture_array>(texture);
}

void rd_free_texture_array(texture_array *set)
{
    drop(into_objc<CNNRTextureArray>(set));
}

void rd_get_texture_array_size(const texture_array *set, uint32_t *width, uint32_t *height)
{
    auto texture = ref_objc<CNNRTextureArray>(set);
    *width = texture.width;
    *height = texture.height;
}

uint32_t rd_get_texture_array_count(const texture_array *set)
{
    auto texture = ref_objc<CNNRTextureArray>(set);
    return texture.spriteCount;
}

bool rd_is_texture_array_streaming(const texture_array *set)
{
    auto texture = ref_objc<CNNRTextureArray>(set);
    return texture.streaming;
}

bool rd_is_texture_array_pixel_art(const texture_array *set)
{
    auto texture = ref_objc<CNNRTextureArray>(set);
    return texture.isPixelArt;
}

void rd_set_texture_array_pixel_art(texture_array *set, bool pa)
{
    auto texture = ref_objc<CNNRTextureArray>(set);
    texture.isPixelArt = pa;
}

texture *rd_get_texture(texture_array *set, uint32_t index)
{
    auto texture = ref_objc<CNNRTextureArray>(set);
    if (index >= texture.spriteCount)
        return nullptr;
    CNNRTexture *entry = texture.textures[index];
    return ref_objc<struct texture>(entry);
}

texture_array *rd_get_texture_array(texture *tex)
{
    auto texture = ref_objc<CNNRTexture>(tex);
    return ref_objc<texture_array>(texture.array);
}

bool rd_update_texture(device *, texture *tex, const uint8_t *data, size_t len)
{
    auto texture = ref_objc<CNNRTexture>(tex);
    assert(len == texture.array.width * texture.array.height * 4);
    [texture.array updateTextureAt:texture.index withData:data];
    return true;
}
