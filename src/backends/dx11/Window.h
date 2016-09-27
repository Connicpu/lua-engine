#pragma once

#include "platform.h"
#include "RenderTarget.h"
#include "DepthBuffer.h"

struct window
{
    freeing_ptr<window_handler> handler;
    com_ptr<IDXGISwapChain1> swap_chain;
    render_target back_buffer;

    HWND hwnd;
    window_state state;
};

size_t rd_get_outputs(instance *inst, size_t len, adapter_output *outputs);

window *rd_create_window(device *dev, const window_params *params);
void rd_free_window(window *win);

bool rd_set_window_state(window *win, window_state state);
render_target *rd_get_window_target(window *win);
void rd_get_window_dpi(window *win, float *dpix, float *dpiy);
bool rd_prepare_window_for_drawing(device * dev, window *win);
