#import "platform.h"

@class CNDevice;

@interface CNTextureArray : NSObject 

@property bool isPixelArt;
@property (readonly) uint32_t spriteCount;
@property (readonly) uint32_t width;
@property (readonly) uint32_t height;
@property (readonly) bool streaming;
@property (readonly) id<MTLTexture> textureArray;
@property (readonly) NSArray *textures;

@end

@interface CNTexture : NSObject 

@property (readonly) uint32_t index;
@property (readonly, unsafe_unretained) CNTextureArray *array;

+(instancetype) newForIndex:(uint32_t)index
                  withArray:(CNTextureArray *)array;
-(instancetype) initForIndex:(uint32_t)index
                   withArray:(CNTextureArray *)array;

@end
