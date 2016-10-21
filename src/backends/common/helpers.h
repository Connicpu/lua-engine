#pragma once

#include <utility>

template <typename T>
inline void drop(T &&value)
{
    T moved = std::forward<T>(value);
    ((void)moved); // unreferenced
}

#ifdef OBJC

template <typename T, typename U>
inline T *from_objc(U *p)
{
    return (__bridge_retained T *)p;
}

template <typename T, typename U>
inline T *ref_objc(U *p)
{
    return (__bridge T *)p;
}

template <typename T, typename U>
inline T *into_objc(U *p)
{
    return (__bridge_transfer T *)p;
}

inline void *ptr_offset(void *p, size_t off)
{
    return ((uint8_t *)p) + off;
}

inline const void *ptr_offset(const void *p, size_t off)
{
    return ((const uint8_t *)p) + off;
}

#endif
