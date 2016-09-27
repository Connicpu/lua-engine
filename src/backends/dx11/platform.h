#pragma once

#include "Error.h"

#include <Windows.h>
#include <d3d11.h>
#include <dxgi1_2.h>
#include <d2d1_1.h>
#include <dwrite.h>
#include <atlbase.h>
#include <comdef.h>
#include <codecvt>
#include <memory>
#include <backends/common/renderer.h>
#include <backends/common/window_handler.h>
#include <backends/common/renderer_math.h>
#include <backends/common/scene_graph.h>
#include <backends/common/freeing_ptr.h>
#include <backends/win32-handler/platform.h>

template <typename T>
using com_ptr = ATL::CComPtr<T>;

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
inline T set_error_and_ret(T ret, HRESULT hr)
{
    _com_error err(hr);
    return set_error_and_ret<T>(std::move(ret), hr, err.ErrorMessage());
}

template <typename T>
inline T append_error_and_ret(T ret, const char *msg)
{
    rd_append_error(msg);
    return std::move(ret);
}

inline nullptr_t set_error_and_ret(HRESULT hr)
{
    return set_error_and_ret(nullptr, hr);
}

inline nullptr_t set_error_and_ret(const char *msg)
{
    return set_error_and_ret(nullptr, msg);
}

inline nullptr_t append_error_and_ret(const char *msg)
{
    return append_error_and_ret(nullptr, msg);
}

#define IID_PPV_ARGS_IUNK(ppType) __uuidof(**(ppType)), ((IUnknown **)IID_PPV_ARGS_Helper(ppType))

#define LOAD_PFN(lib, fn) reinterpret_cast<decltype(fn)*>(GetProcAddress(lib, #fn))

