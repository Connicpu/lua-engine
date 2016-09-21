local ffi = require("engine.graphics.renderer.typedefs")

ffi.rd_header.cdef[[
    framebuffer *rd_create_framebuffer(device *dev, uint32_t width, uint32_t height);
    void rd_free_framebuffer(framebuffer *fb);
    void rd_clear_framebuffer(framebuffer *fb, const color *clear);

    render_target *rd_get_framebuffer_target(framebuffer *fb);
    texture *rd_get_framebuffer_texture(framebuffer *fb);
]]
