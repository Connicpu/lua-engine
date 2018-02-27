#import "CNCamera.h"
#import "CNDevice.h"

@implementation CNCamera
{
    id<MTLBuffer> _cam_buffer;
    bool _updated;
}

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        _transform = identity();
        _cam_inverse = identity();
        _cam_full = identity();
        _aspect_ratio = 1;
        _cam_buffer = nil;
        _updated = true;
    }
    return self;
}

-(id<MTLBuffer>)ensureUploadedToDevice:(id<MTLDevice>)device
{
    if (_updated)
    {
        if (_cam_buffer == nil)
        {
            _cam_buffer = [device newBufferWithLength:sizeof(matrix2d)
                                              options:kResourceOptions];
        }
        
        auto ptr = [_cam_buffer contents];
        memcpy(ptr, &_cam_full, sizeof(matrix2d));
        [_cam_buffer didModifyRange:NSMakeRange(0, sizeof(matrix2d))];
        
        _updated = false;
    }
    return _cam_buffer;
}

-(void)wasUpdated
{
    _cam_full = _cam_inverse * scale(vec2{ 1 / _aspect_ratio, 1 });
    _updated = true;
}

@end

camera *rd_create_camera()
{
    auto cam = [CNCamera new];
    return from_objc<camera>(cam);
}

void rd_free_camera(camera *cam)
{
    drop(into_objc<CNCamera>(cam));
}

void rd_set_camera_aspect(camera *pcam, float aspect_ratio)
{
    auto cam = ref_objc<CNCamera>(pcam);
    cam.aspect_ratio = aspect_ratio;
    [cam wasUpdated];
}

bool rd_update_camera(camera *pcam, const matrix2d *transform)
{
    if (!is_invertible(*transform))
        return false;
    
    auto cam = ref_objc<CNCamera>(pcam);
    cam.transform = *transform;
    cam.cam_inverse = inverse(*transform);
    [cam wasUpdated];
    return true;
}

void rd_get_camera_transform(camera *pcam, matrix2d *transform)
{
    auto cam = ref_objc<CNCamera>(pcam);
    *transform = cam.transform;
}
