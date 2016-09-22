#pragma once

#include "platform.h"

bool rd_cbuffer_update(device *dev, const void *data, size_t size, size_t &size_, ComPtr<ID3D11Buffer> &buf_);

template <typename T>
class CBuffer
{
public:
    bool Update(device *dev, const T &data);

private:
    size_t size_;
    ComPtr<ID3D11Buffer> buf_;
};

template<typename T>
inline bool CBuffer<T>::Update(device *dev, const T &data)
{
    return rd_cbuffer_update(dev, (const void *)std::addressof(data), sizeof(T), size_, buf_);
}
