#include "pch.h"
#include "InstanceBuffer.h"
#include "Device.h"

ib_state::ib_state()
{
    rd_ib_deactivate(*this);
}

static bool should_resize(uint32_t count, ib_state & state)
{
    if (!state.buffer)
        return true;

    if (state.cap < count)
        return true;

    for (size_t c : state.previous_counts)
    {
        if (c > state.cap / 3)
            return false;
    }

    return true;
}

bool rd_ib_start_upload(device * dev, uint32_t count, uint32_t isize, ib_state & state)
{
    if (count == 0)
        return set_error_and_ret(false, "Cannot create an instance buffer of size 0");

    HRESULT hr;
    if (should_resize(count, state))
    {
        rd_ib_deactivate(state);
        uint32_t new_cap = uint32_t(count * 1.5);

        D3D11_BUFFER_DESC desc;
        desc.BindFlags = D3D11_BIND_VERTEX_BUFFER;
        desc.ByteWidth = new_cap * isize; // allocate 1.5x as much room as we need to avoid resizes
        desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
        desc.MiscFlags = 0;
        desc.StructureByteStride = isize;
        desc.Usage = D3D11_USAGE_DYNAMIC;

        hr = dev->d3d_device->CreateBuffer(&desc, nullptr, &state.buffer);
        if (FAILED(hr))
            return set_error_and_ret(false, hr);

        state.cap = new_cap;
    }

    memmove(state.previous_counts + 1, state.previous_counts, 7 * sizeof(size_t));
    state.previous_counts[0] = count;

    hr = dev->d3d_context->Map(state.buffer, 0, D3D11_MAP_WRITE_DISCARD, 0, &state.subres);
    if (FAILED(hr))
        return set_error_and_ret(false, hr);

    state.idx = 0;
    return true;
}

void rd_ib_push(const void * data, uint32_t size, ib_state & state)
{
    assert(state.idx < state.cap);
    auto offset = size * state.idx;
    auto dst = ((uint8_t *)state.subres.pData) + offset;

    memcpy(dst, data, size);

    state.idx++;
}

void rd_ib_push(const void * data, uint32_t size, uint32_t count, ib_state & state)
{
    assert(state.idx + count <= state.cap);
    auto offset = size * state.idx;
    auto dst = ((uint8_t *)state.subres.pData) + offset;

    memcpy(dst, data, size * count);

    state.idx += count;
}

bool rd_ib_finish(device * dev, ib_state & state)
{
    dev->d3d_context->Unmap(state.buffer, 0);
    return true;
}

void rd_ib_deactivate(ib_state & state)
{
    state.buffer.Release();
    state.cap = 0;
    memset(state.previous_counts, 0xFF, sizeof(state.previous_counts));
}
