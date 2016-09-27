#pragma once

#include "platform.h"

bool rd_cbuffer_update(device *dev, const void *data, size_t size, size_t &size_, com_ptr<ID3D11Buffer> &buf_);

template <typename T>
class cbuffer
{
public:
    bool update(device *dev, const T &data);

private:
    size_t size_;
    com_ptr<ID3D11Buffer> buf_;
};

template<typename T>
inline bool cbuffer<T>::update(device *dev, const T &data)
{
    return rd_cbuffer_update(dev, (const void *)std::addressof(data), sizeof(T), size_, buf_);
}
