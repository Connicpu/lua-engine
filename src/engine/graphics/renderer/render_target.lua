local ffi = require("engine.graphics.renderer.typedefs")

ffi.rd_header.cdef[[
    framebuffer *rd_create_framebuffer(device *dev, uint32_t width, uint32_t height);
    void rd_free_framebuffer(framebuffer *fb);

    render_target *rd_get_framebuffer_target(framebuffer *fb);
    texture *rd_get_framebuffer_texture(framebuffer *fb);
    void rd_clear_render_target(device *dev, render_target *rt, const color *clear);
    void rd_clear_depth_buffer(device *dev, render_target *rt);
]]

return ffi
