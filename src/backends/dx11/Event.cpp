#include "pch.h"
#include "Event.h"
#include "Window.h"

bool rd_poll_window_event(window * window, window_event * event)
{
    return rd_poll_window_handler(window->handler, event);
}

void rd_free_window_event(window_event * event)
{
    rd_free_wh_event(event);
}
