#pragma once

#include "platform.h"

struct depth_buffer
{
    com_ptr<ID3D11Texture2D> buffer;
    com_ptr<ID3D11DepthStencilState> dss;
    com_ptr<ID3D11DepthStencilView> dsv;
};

bool rd_init_depth_buffer(device *dev, depth_buffer *depth, ID3D11Texture2D *color_buffer);
