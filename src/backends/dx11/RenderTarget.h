#pragma once

#include "Texture.h"
#include "DepthBuffer.h"

struct render_target
{
    com_ptr<ID3D11Texture2D> buffer;
    com_ptr<ID3D11RenderTargetView> rtv;
    com_ptr<IDXGISurface> surface;

    depth_buffer depth;
};

struct framebuffer
{
    render_target target;
    texture_array texture;
};

framebuffer *rd_create_framebuffer(device *dev, uint32_t width, uint32_t height);
void rd_free_framebuffer(framebuffer *fb);

render_target *rd_get_framebuffer_target(framebuffer *fb);
texture *rd_get_framebuffer_texture(framebuffer *fb);
void rd_clear_render_target(device *dev, render_target *rt, const color *clear);
void rd_clear_depth_buffer(device *dev, render_target *rt);
