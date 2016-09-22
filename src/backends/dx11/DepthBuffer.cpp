#include "pch.h"
#include "DepthBuffer.h"
#include "Device.h"

bool rd_init_depth_buffer(device *dev, depth_buffer *depth, ID3D11Texture2D *color_buffer)
{
    HRESULT hr;

    auto *d3d = dev->d3d_device.p;

    depth->dsv.Release();
    depth->dss.Release();
    depth->buffer.Release();

    D3D11_TEXTURE2D_DESC color_desc;
    color_buffer->GetDesc(&color_desc);

    D3D11_TEXTURE2D_DESC buf_desc;
    buf_desc.Width = color_desc.Width;
    buf_desc.Height = color_desc.Height;
    buf_desc.BindFlags = D3D11_BIND_DEPTH_STENCIL;
    buf_desc.Format = DXGI_FORMAT_D24_UNORM_S8_UINT;
    buf_desc.Usage = D3D11_USAGE_DEFAULT;
    buf_desc.CPUAccessFlags = 0;
    buf_desc.ArraySize = 1;
    buf_desc.MipLevels = 1;
    buf_desc.SampleDesc = { 1, 0 };
    buf_desc.MiscFlags = 0;
    hr = d3d->CreateTexture2D(&buf_desc, nullptr, &depth->buffer);
    if (FAILED(hr))
        return set_error_and_ret(false, hr);

    D3D11_DEPTH_STENCIL_DESC state_desc;
    state_desc.DepthEnable = true;
    state_desc.DepthWriteMask = D3D11_DEPTH_WRITE_MASK_ALL;
    state_desc.DepthFunc = D3D11_COMPARISON_LESS_EQUAL;
    state_desc.StencilEnable = true;
    state_desc.StencilReadMask = 0xFF;
    state_desc.StencilWriteMask = 0xFF;
    state_desc.FrontFace.StencilFailOp = D3D11_STENCIL_OP_KEEP;
    state_desc.FrontFace.StencilDepthFailOp = D3D11_STENCIL_OP_INCR;
    state_desc.FrontFace.StencilPassOp = D3D11_STENCIL_OP_KEEP;
    state_desc.FrontFace.StencilFunc = D3D11_COMPARISON_ALWAYS;
    state_desc.BackFace.StencilFailOp = D3D11_STENCIL_OP_KEEP;
    state_desc.BackFace.StencilDepthFailOp = D3D11_STENCIL_OP_DECR;
    state_desc.BackFace.StencilPassOp = D3D11_STENCIL_OP_KEEP;
    state_desc.BackFace.StencilFunc = D3D11_COMPARISON_ALWAYS;
    hr = d3d->CreateDepthStencilState(&state_desc, &depth->dss);
    if (FAILED(hr))
        return set_error_and_ret(false, hr);

    D3D11_DEPTH_STENCIL_VIEW_DESC view_desc;
    view_desc.Flags = 0;
    view_desc.Format = buf_desc.Format;
    view_desc.ViewDimension = D3D11_DSV_DIMENSION_TEXTURE2D;
    view_desc.Texture2D.MipSlice = 0;
    hr = d3d->CreateDepthStencilView(depth->buffer, &view_desc, &depth->dsv);
    if (FAILED(hr))
        return set_error_and_ret(false, hr);

    return true;
}
