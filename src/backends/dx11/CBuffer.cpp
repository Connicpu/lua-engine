#include "pch.h"
#include "CBuffer.h"
#include "Device.h"

bool rd_cbuffer_update(device *dev, const void *data, size_t size, size_t &size_, com_ptr<ID3D11Buffer> &buf_)
{
    HRESULT hr;

    if (!buf_ || size != size_)
    {
        buf_.Release();
        size_ = size;

        D3D11_BUFFER_DESC desc;
        desc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
        desc.ByteWidth = (uint32_t)size;
        desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
        desc.MiscFlags = 0;
        desc.StructureByteStride = (uint32_t)size;
        desc.Usage = D3D11_USAGE_DYNAMIC;

        D3D11_SUBRESOURCE_DATA init_data = { 0 };
        init_data.pSysMem = data;

        hr = dev->d3d_device->CreateBuffer(&desc, &init_data, &buf_);
        if (FAILED(hr))
            return set_error_and_ret(false, hr);
    }
    else
    {
        D3D11_MAPPED_SUBRESOURCE mapped;
        hr = dev->d3d_context->Map(buf_, 0, D3D11_MAP_WRITE_DISCARD, 0, &mapped);
        if (FAILED(hr))
            return set_error_and_ret(false, hr);

        memcpy(mapped.pData, data, size);

        dev->d3d_context->Unmap(buf_, 0);
    }

    return true;
}
