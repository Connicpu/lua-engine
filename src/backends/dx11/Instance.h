#pragma once
#include <backends/common/renderer.h>
#include "platform.h"

struct instance
{
    ComPtr<IDXGIFactory2> dxgi_factory;
    ComPtr<IDWriteFactory> dwrite_factory;
    ComPtr<ID2D1Factory1> d2d_factory;
};

extern "C" instance *rd_create_instance();
extern "C" void rd_free_instance(instance *inst);
