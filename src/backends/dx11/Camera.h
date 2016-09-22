#pragma once

#include "platform.h"
#include "CBuffer.h"

struct camera
{
    float aspect_ratio;
    matrix2d transform;
    matrix2d cam_inverse;
    matrix2d cam_full;
    
    CBuffer<matrix2d> cam_buffer;
    bool updated;
};

extern "C" camera *rd_create_camera();
extern "C" void rd_free_camera(camera *cam);

extern "C" void rd_set_camera_aspect(camera *cam, float aspect_ratio);
extern "C" bool rd_update_camera(camera *cam, matrix2d *transform);
