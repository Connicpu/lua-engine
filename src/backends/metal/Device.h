#pragma once

#include "platform.h"

@class CNNRTextureArray;

@interface CNNRDevice : NSObject

@property (readonly) id<MTLDevice> device;

-(void)bindQuadShader;
-(void)bindTexture:(CNNRTextureArray *array);

@end
