#pragma once

#include "Texture.h"
#include "DepthBuffer.h"

struct render_target
{
    ComPtr<ID3D11Texture2D> buffer;
    ComPtr<ID3D11RenderTargetView> rtv;
    ComPtr<IDXGISurface> surface;

    depth_buffer depth;
};

struct framebuffer
{
    render_target target;
    texture_array texture;
};

extern "C" framebuffer *rd_create_framebuffer(device *dev, uint32_t width, uint32_t height);
extern "C" void rd_free_framebuffer(framebuffer *fb);

extern "C" render_target *rd_get_framebuffer_target(framebuffer *fb);
extern "C" texture *rd_get_framebuffer_texture(framebuffer *fb);
extern "C" void rd_clear_render_target(device *dev, render_target *rt, const color *clear);
extern "C" void rd_clear_depth_buffer(device *dev, render_target *rt);
