#pragma once
#include <backends/common/renderer.h>
#include "platform.h"

struct instance
{
    com_ptr<IDXGIFactory2> dxgi_factory;
    com_ptr<IDWriteFactory> dwrite_factory;
    com_ptr<ID2D1Factory1> d2d_factory;
};

extern "C" instance *rd_create_instance();
extern "C" void rd_free_instance(instance *inst);
