#include "pch.h"
#include "Error.h"
#include <algorithm>

static thread_local bool has_last_error = false;
static thread_local renderer_error last_error;

void rd_set_error(int code, const char *msg)
{
    has_last_error = true;
    auto len = std::min(strlen(msg), size_t(127));
    memcpy(last_error.message, msg, len);
    last_error.message[len] = 0;
}

bool rd_last_error(renderer_error *error)
{
    if (!has_last_error)
        return false;

    *error = last_error;

    return true;
}

void rd_clear_error()
{
    has_last_error = false;
}
