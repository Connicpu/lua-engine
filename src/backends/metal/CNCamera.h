#import "platform.h"

@interface CNCamera : NSObject

@property (nonatomic) matrix2d transform;
@property (nonatomic) matrix2d cam_inverse;
@property (nonatomic) matrix2d cam_full;
@property (nonatomic) float aspect_ratio;

-(id<MTLBuffer>)ensureUploadedToDevice:(id<MTLDevice>)device;

@end
