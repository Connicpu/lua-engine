#pragma once

#include "platform.h"

struct ib_state
{
    ib_state();

    com_ptr<ID3D11Buffer> buffer;
    uint32_t cap;
    uint32_t previous_counts[8];

    uint32_t idx;
    D3D11_MAPPED_SUBRESOURCE subres;
};

template <typename T>
class InstanceBuffer
{
public:
    bool start_upload(device *dev, uint32_t count);
    void push(const T &item);
    void push(const T *data, uint32_t count);
    bool finish(device *dev);
    void bind(device *dev, UINT slot) const;

    void deactivate();
    uint32_t count() const;

private:
    ib_state state;
};

bool rd_ib_start_upload(device *dev, uint32_t count, uint32_t isize, ib_state &state);
void rd_ib_push(const void *data, uint32_t size, uint32_t count, ib_state &state);
bool rd_ib_finish(device *dev, ib_state &state);
void rd_ib_deactivate(ib_state &state);

template<typename T>
inline bool InstanceBuffer<T>::start_upload(device *dev, uint32_t count)
{
    return rd_ib_start_upload(dev, count, sizeof(T), state);
}

template<typename T>
inline void InstanceBuffer<T>::push(const T &item)
{
    push(std::addressof(item), 1);
}

template<typename T>
inline void InstanceBuffer<T>::push(const T * data, uint32_t count)
{
    rd_ib_push(data, sizeof(T), count, state);
}

template<typename T>
inline bool InstanceBuffer<T>::finish(device *dev)
{
    return rd_ib_finish(dev, state);
}

template<typename T>
inline void InstanceBuffer<T>::bind(device * dev, UINT slot) const
{
    UINT strides[] = { sizeof(T) };
    UINT offsets[] = { 0 };
    dev->d3d_context->IASetVertexBuffers(slot, 1, &state.buffer.p, strides, offsets);
}

template<typename T>
inline void InstanceBuffer<T>::deactivate()
{
    rd_ib_deactivate(state);
}

template<typename T>
inline uint32_t InstanceBuffer<T>::count() const
{
    return state.previous_counts[0];
}
