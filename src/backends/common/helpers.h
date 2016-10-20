#pragma once

#include <utility>

template <typename T>
inline void drop(T &&value)
{
    T moved = std::move(value);
    ((void)moved); // unreferenced
}

#ifdef OBJC

template <typename T, typename U>
inline T *from_objc(U *p)
{
    return (__bridge_retained T *)p;
}

template <typename T, typename U>
inline T *as_objc(U *p)
{
    return (__bridge T *)p;
}

template <typename T, typename U>
inline T *into_objc(U *p)
{
    return (__bridge_transfer T *)p;
}

#endif
