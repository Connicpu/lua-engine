local ffi = require("engine.graphics.renderer")
local rd_err = require("engine.graphics.error")

local C = ffi.C
local check_ptr = rd_err.check_ptr
local check_bool = rd_err.check_bool
local ffi_new = ffi.new
local ffi_cast = ffi.cast
local ffi_gc = ffi.gc
local ffi_string = ffi.string

local RenderTarget_t = ffi.typeof("struct{render_target *rt;}")
local RenderTarget = {}
local RenderTarget_mt = { __index = RenderTarget }
local RenderTarget_ct

function RenderTarget:clear(device, color)
    if type(color) == 'string' then
        color = math.color.parse(color)
    end
    if color == nil then
        error("Invalid color passed to RenderTarget:clear()")
    end

    __rd.rd_clear_render_target(device.dev, self.rt, color)
end

function RenderTarget:clear_depth(device)
    __rd.rd_clear_depth_buffer(device.dev, self.rt)
end

RenderTarget_ct = ffi.metatype(RenderTarget_t, RenderTarget_mt)

return {
    RenderTarget = RenderTarget_ct
}
