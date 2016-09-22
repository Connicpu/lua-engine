#pragma once

#include "platform.h"
#include "RenderTarget.h"
#include "DepthBuffer.h"

struct window
{
    HWND hwnd;

    ComPtr<IDXGISwapChain> swap_chain;
    render_target back_buffer;
};

extern "C" size_t rd_get_outputs(instance *inst, size_t len, adapter_output *outputs);

extern "C" window *rd_create_window(device *device, const window_params *params);
extern "C" void rd_free_window(window *win);

extern "C" render_target *rd_get_window_target(window *win);
extern "C" void rd_get_window_dpi(window *win, float *dpix, float *dpiy);
