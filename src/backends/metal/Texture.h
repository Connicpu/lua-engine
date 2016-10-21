#pragma once

#include "platform.h"

@class CNNRDevice;

@interface CNNRTextureArray : NSObject 

@property bool isPixelArt;
@property (readonly) uint32_t spriteCount;
@property (readonly) uint32_t width;
@property (readonly) uint32_t height;
@property (readonly) bool streaming;
@property (readonly) id<MTLTexture> textureArray;
@property (readonly) NSArray *textures;

@end

@interface CNNRTexture : NSObject 

@property (readonly) uint32_t index;
@property (readonly, unsafe_unretained) CNNRTextureArray *array;

+(instancetype) newForIndex:(uint32_t)index
                  withArray:(CNNRTextureArray *)array;
-(instancetype) initForIndex:(uint32_t)index
                   withArray:(CNNRTextureArray *)array;

@end
