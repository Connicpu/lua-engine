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

void rd_set_camera_aspect(camera *cam, float aspect_ratio)
{
    cam->aspect_ratio = aspect_ratio;
    cam->cam_full = cam->cam_inverse * scale(vec2{ 1/aspect_ratio, 1 });
    cam->updated = false;
}

bool rd_update_camera(camera *cam, matrix2d *transform)
{
}
