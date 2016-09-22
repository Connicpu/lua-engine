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
#include <backends/common/renderer.h>
#include <backends/common/renderer_math.h>

template <typename T>
using ComPtr = ATL::CComPtr<T>;

template <typename T>
inline T set_error_and_ret(T ret, HRESULT hr)
{
    _com_error err(hr);
    rd_set_error(hr, err.ErrorMessage());
    return std::move(ret);
}

#define IID_PPV_ARGS_IUNK(ppType) __uuidof(**(ppType)), ((IUnknown **)IID_PPV_ARGS_Helper(ppType))

inline std::string narrow(const wchar_t *str)
{
    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
    return converter.to_bytes(str);
}

inline std::string narrow(const std::wstring &str)
{
    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
    return converter.to_bytes(str);
}

#define LOAD_PFN(lib, fn) reinterpret_cast<decltype(fn)*>(GetProcAddress(lib, #fn))

