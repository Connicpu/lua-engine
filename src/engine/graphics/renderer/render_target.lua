local ffi = require("engine.graphics.renderer.typedefs")

ffi.cdef[[
    render_target *rd_create_framebuffer(device *dev, uint32_t width, uint32_t height);
]]
