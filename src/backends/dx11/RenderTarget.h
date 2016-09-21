#pragma once

#include <backends/common/renderer.h>

extern "C" framebuffer *rd_create_framebuffer(device *dev, uint32_t width, uint32_t height);
extern "C" void rd_free_framebuffer(framebuffer *fb);
extern "C" void rd_clear_framebuffer(framebuffer *fb, const color *clear);

extern "C" render_target *rd_get_framebuffer_target(framebuffer *fb);
extern "C" texture *rd_get_framebuffer_texture(framebuffer *fb);
