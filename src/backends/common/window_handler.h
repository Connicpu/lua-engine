#pragma once

#include "renderer.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct window_handler window_handler;

window_handler *rd_create_wh(const window_params *params);
void rd_free_wh(window_handler *handler);

bool rd_set_wh_state(window_handler *win, window_state state);
bool rd_check_dirty_buffers(window_handler *handler);
void *rd_get_wh_platform_handle(window_handler *handler);
bool rd_poll_window_handler(window_handler *handler, window_event *event);
void rd_free_wh_event(window_event *event);

#ifdef __cplusplus
}
#endif
