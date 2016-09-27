#include "pch.h"
#include "Camera.h"

camera * rd_create_camera()
{
    return new camera;
}

void rd_free_camera(camera *cam)
{
    delete cam;
}

static void on_update(camera *cam)
{
    cam->cam_full = cam->cam_inverse * scale(vec2{ 1 / cam->aspect_ratio, 1 });
    cam->updated = true;
}

void rd_set_camera_aspect(camera *cam, float aspect_ratio)
{
    cam->aspect_ratio = aspect_ratio;
    on_update(cam);
}

bool rd_update_camera(camera *cam, const matrix2d *transform)
{
    if (!is_invertible(*transform))
        return false;

    cam->transform = *transform;
    cam->cam_inverse = inverse(*transform);
    on_update(cam);

    return true;
}

void rd_get_camera_transform(camera *cam, matrix2d *transform)
{
    *transform = cam->transform;
}

bool rd_upload_camera(device *dev, camera *cam)
{
    if (cam->updated)
    {
        cam->cam_buffer.update(dev, cam->cam_full);
        cam->updated = false;
    }
    return true;
}
