#pragma once

#include "platform.h"
#include <concurrent_queue.h>

struct window_handler
{
    ~window_handler();

    HWND hwnd;
    HINSTANCE hinst;
    std::wstring wnd_class;
    WINDOWPLACEMENT wp;
    window_state state;
    bool dirty_buffers;

    concurrency::concurrent_queue<window_event> events;
};

window_handler *rd_create_wh(const window_params *params);
void rd_free_wh(window_handler *handler);

bool rd_set_wh_state(window_handler *win, window_state state);
bool rd_check_dirty_buffers(window_handler *handler);
void *rd_get_wh_platform_handle(window_handler *handler);
bool rd_poll_window_handler(window_handler *handler, window_event *event);
void rd_free_wh_event(window_event *event);
