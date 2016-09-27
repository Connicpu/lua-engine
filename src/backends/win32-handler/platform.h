#pragma once

#include <Windows.h>
#include <comdef.h>
#include <codecvt>
#include <memory>
#include <shellapi.h>
#include <cassert>
#include <backends/common/window_handler.h>

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

inline std::wstring widen(const char *str)
{
    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
    return converter.from_bytes(str);
}

inline std::wstring widen(const std::string &str)
{
    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
    return converter.from_bytes(str);
}

template <typename FnPtr>
inline HINSTANCE GetHinstanceFromFn(FnPtr *pFn)
{
    HMODULE handle;
    BOOL result = GetModuleHandleExW(
        GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
        GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
        (LPCWSTR)pFn,
        &handle
    ); result;
    assert(result);
    return (HINSTANCE)handle;
}

#ifdef DEBUG
#define unreachable() (assert(false && "Unreachable statement was reached :x"))
#define unreachable_msg(msg) (assert(false && msg))
#else
#define unreachable() (__assume(0))
#define unreachable_msg(msg) (unreachable())
#endif
