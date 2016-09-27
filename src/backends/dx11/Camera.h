#pragma once

#include "platform.h"
#include "CBuffer.h"

struct camera
{
    float aspect_ratio;
    matrix2d transform;
    matrix2d cam_inverse;
    matrix2d cam_full;
    
    cbuffer<matrix2d> cam_buffer;
    bool updated;
};

camera *rd_create_camera();
void rd_free_camera(camera *cam);

void rd_set_camera_aspect(camera *cam, float aspect_ratio);
bool rd_update_camera(camera *cam, const matrix2d *transform);
void rd_get_camera_transform(camera *cam, matrix2d *transform);

bool rd_upload_camera(device *dev, camera *cam);
