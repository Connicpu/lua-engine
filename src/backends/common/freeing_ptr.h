#pragma once

#include <algorithm>
#include <cassert>

template <typename T>
class freeing_ptr
{
public:
    using free_fn_t = void(*)(T*);

    inline freeing_ptr()
        : ptr(nullptr), free_fn(nullptr)
    {
    }

    inline freeing_ptr(T *ptr, free_fn_t free_fn)
        : ptr(ptr), free_fn(free_fn)
    {
        assert(!ptr || free_fn);
    }

    inline freeing_ptr(const freeing_ptr &) = delete;
    inline freeing_ptr(freeing_ptr &&move)
        : freeing_ptr()
    {
        swap(move);
    }

    inline ~freeing_ptr()
    {
        reset();
    }

    inline freeing_ptr &operator=(const freeing_ptr &) = delete;
    inline freeing_ptr &operator=(freeing_ptr &&move)
    {
        reset();
        swap(move);
        return *this;
    }

    inline void assign(T *p, free_fn_t f)
    {
        assert(!ptr || free_fn);
        reset();
        ptr = p;
        free_fn = f;
    }

    inline void swap(freeing_ptr &other)
    {
        std::swap(ptr, other.ptr);
        std::swap(free_fn, other.free_fn);
    }

    inline void reset()
    {
        if (ptr)
        {
            free_fn(ptr);
            
            ptr = nullptr;
            free_fn = nullptr;
        }
    }

    inline T *release()
    {
        T *temp = nullptr;
        std::swap(ptr, temp);
        return temp;
    }

    inline T *get() const
    {
        return ptr;
    }

    inline T &operator*() const
    {
        assert(ptr);
        return *ptr;
    }

    inline T *operator->() const
    {
        assert(ptr);
        return ptr;
    }

    inline operator T *() const
    {
        return ptr;
    }

private:
    T *ptr;
    free_fn_t free_fn;
};

