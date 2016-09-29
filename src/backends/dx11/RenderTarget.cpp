#include "pch.h"
#include "RenderTarget.h"
#include "Device.h"
#include "Instance.h"
#include <memory>

framebuffer * rd_create_framebuffer(device *dev, uint32_t width, uint32_t height)
{
    HRESULT hr;
    std::unique_ptr<framebuffer> fb(new framebuffer);

    fb->texture.width = width;
    fb->texture.height = height;

    auto *d3d = dev->d3d_device.p;

    // Create the buffer
    D3D11_TEXTURE2D_DESC desc;
    desc.ArraySize = 1;
    desc.BindFlags = D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET;
    desc.CPUAccessFlags = 0;
    desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    desc.Width = width;
    desc.Height = height;
    desc.MipLevels = 1;
    desc.MiscFlags = 0;
    desc.SampleDesc = { 1, 0 };
    desc.Usage = D3D11_USAGE_DEFAULT;
    hr = d3d->CreateTexture2D(&desc, nullptr, &fb->target.buffer);
    if (FAILED(hr))
        return set_error_and_ret(nullptr, hr);

    // Make the RTV for drawing onto
    D3D11_RENDER_TARGET_VIEW_DESC rtv_desc;
    rtv_desc.Format = desc.Format;
    rtv_desc.ViewDimension = D3D11_RTV_DIMENSION_TEXTURE2D;
    rtv_desc.Texture2D.MipSlice = 0;
    hr = d3d->CreateRenderTargetView(fb->target.buffer, &rtv_desc, &fb->target.rtv);
    if (FAILED(hr))
        return set_error_and_ret(nullptr, hr);

    // Get the Surface
    hr = fb->target.buffer->QueryInterface(&fb->target.surface);
    if (FAILED(hr))
        return set_error_and_ret(nullptr, hr);

    // Set up the texture_array buffer
    fb->texture.buffer = fb->target.buffer;

    // Set up the SRV for rendering the buffer
    D3D11_SHADER_RESOURCE_VIEW_DESC srv_desc;
    srv_desc.Format = desc.Format;
    srv_desc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2DARRAY;
    srv_desc.Texture2DArray.ArraySize = 1;
    srv_desc.Texture2DArray.FirstArraySlice = 0;
    srv_desc.Texture2DArray.MipLevels = 1;
    srv_desc.Texture2DArray.MostDetailedMip = 0;
    hr = d3d->CreateShaderResourceView(fb->texture.buffer, &srv_desc, &fb->texture.srv);
    if (FAILED(hr))
        return set_error_and_ret(nullptr, hr);

    // Set up the texture_array entry
    texture tex;
    tex.array = &fb->texture;
    tex.index = 0;
    fb->texture.textures.push_back(tex);

    // Create the D2D target
    hr = dev->inst->d2d_factory->CreateDxgiSurfaceRenderTarget(
        fb->target.surface,
        D2D1::RenderTargetProperties(
            D2D1_RENDER_TARGET_TYPE_HARDWARE,
            D2D1::PixelFormat(
                desc.Format,
                D2D1_ALPHA_MODE_PREMULTIPLIED
            ),
            96,
            96
        ),
        &fb->target.d2d_target
    );
    if (FAILED(hr))
        return set_error_and_ret(nullptr, hr);

    if (!rd_init_depth_buffer(dev, &fb->target.depth, fb->target.buffer))
        return nullptr;

    return fb.release();
}

void rd_free_framebuffer(framebuffer *fb)
{
    delete fb;
}

render_target *rd_get_framebuffer_target(framebuffer *fb)
{
    return &fb->target;
}

texture *rd_get_framebuffer_texture(framebuffer *fb)
{
    return &fb->texture.textures[0];
}

void rd_clear_render_target(device *dev, render_target *rt, const color *clear)
{
    dev->d3d_context->ClearRenderTargetView(rt->rtv, &clear->r);
}

void rd_clear_depth_buffer(device *dev, render_target *rt)
{
    dev->d3d_context->ClearDepthStencilView(rt->depth.dsv, D3D11_CLEAR_DEPTH, 1.0f, 0);
}
