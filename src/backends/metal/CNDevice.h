#import "platform.h"

@class CNTextureArray;

@interface CNDevice : NSObject

@property (readonly) id<MTLDevice> device;

-(void)startCommands;
-(void)useNormalShader;
-(void)usePixelArtShader;
-(void)setTexture:(CNTextureArray *)array;
-(void)drawWithInstances:(id<MTLBuffer>)instances;
-(void)commitCommands;

@end

#ifdef MACOS
constexpr MTLResourceOptions kResourceOptions = MTLResourceStorageModeManaged;
constexpr MTLStorageMode kStorageMode = MTLStorageModeManaged;
#else
constexpr MTLResourceOptions kResourceOptions = MTLResourceStorageModeShared;
constexpr MTLStorageMode kStorageMode = MTLStorageModeShared;
#endif

