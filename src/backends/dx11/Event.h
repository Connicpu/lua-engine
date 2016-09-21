#pragma once

#include <backends/common/renderer.h>

extern "C" bool rd_poll_window_event(window *window, window_event *event);
extern "C" void rd_free_window_event(window_event *event);
