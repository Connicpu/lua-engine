#pragma once

#include <backends/common/renderer.h>

void rd_set_error(int code, const char *msg);
void rd_append_error(const char *msg);

bool rd_last_error(renderer_error *error);
void rd_clear_error();

template <typename T>
inline T set_error_and_ret(T ret, int code, const char *msg)
{
    rd_set_error(code, msg);
    return std::move(ret);
}

template <typename T>
inline T set_error_and_ret(T ret, const char *msg)
{
    return set_error_and_ret<T>(std::move(ret), 0, msg);
}

template <typename T>
inline T append_error_and_ret(T ret, const char *msg)
{
    rd_append_error(msg);
    return std::move(ret);
}

inline std::nullptr_t set_error_and_ret(const char *msg)
{
    return set_error_and_ret(nullptr, msg);
}

inline std::nullptr_t append_error_and_ret(const char *msg)
{
    return append_error_and_ret(nullptr, msg);
}

struct error_interface
{
    template <typename T>
    static T append_ret(T ret, const char *msg)
    {
        return append_error_and_ret(ret, msg);
    }
};
