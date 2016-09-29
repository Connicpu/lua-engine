#include "pch.h"
#include "Error.h"
#include <algorithm>

static thread_local bool has_last_error = false;
static thread_local renderer_error last_error;

void rd_set_error(int code, const char *msg)
{
    if (IsDebuggerPresent())
    {
        __debugbreak();
    }

    has_last_error = true;
    last_error.system_code = code;
    auto len = std::min(strlen(msg), ARRAYSIZE(last_error.message)-1);
    memcpy(last_error.message, msg, len);
    last_error.message[len] = 0;
}

void rd_append_error(const char * msg)
{
    assert(has_last_error);

    auto new_len = strlen(msg);
    auto old_len = strlen(last_error.message);
    auto available = ARRAYSIZE(last_error.message) - old_len - 1;
    auto move_amt = std::min(available, old_len) + 1;

    memmove(last_error.message + new_len + 1, last_error.message, move_amt);
    memcpy(last_error.message, msg, new_len);
    last_error.message[new_len] = '\n';
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
