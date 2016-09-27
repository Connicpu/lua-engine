#pragma once
#include <backends/common/renderer.h>
#include "platform.h"

struct device
{
    instance *inst;
    
    com_ptr<ID3D11Device> d3d_device;
    com_ptr<ID3D11DeviceContext> d3d_context;
    com_ptr<ID2D1Device> d2d_device;
    com_ptr<ID2D1DeviceContext> d2d_context;
};

extern "C" device *rd_create_device(const device_params *params);
extern "C" void rd_free_device(device *dev);
