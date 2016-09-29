local ffi = require("engine.graphics.renderer")
local path = require("engine.utility.path")
local rd_err = require("engine.graphics.error")
local render_target = require("engine.graphics.render_target")

local C = ffi.C
local check_ptr = rd_err.check_ptr
local check_bool = rd_err.check_bool
local fail = rd_err.fail
local ffi_new = ffi.new
local ffi_cast = ffi.cast
local ffi_gc = ffi.gc
local ffi_string = ffi.string

local Camera_t = ffi.typeof("struct{camera *cam;}")
local Camera = {}
local Camera_mt = { __index = Camera }
local Camera_ct

function Camera_mt.__new(tp, dev)
    local cam = check_ptr(__rd.rd_create_camera())
    return ffi_new(tp, cam)
end

function Camera_mt:__gc()
    self:destroy()
end

function Camera:destroy()
    if self.cam ~= nil then
        __rd.rd_free_camera(self.cam)
        self.cam = nil
    end
end

function Camera:set_aspect(aspect)
    __rd.rd_set_camera_aspect(self.cam, aspect)
end

function Camera:update(transform)
    check_bool(__rd.rd_update_camera(self.cam, transform))
end

function Camera:get_transform()
    local mat = math.matrix2d()
    __rd.rd_get_camera_transform(self.cam, mat)
    return mat
end

Camera_ct = ffi.metatype(Camera_t, Camera_mt)

return {
    Camera = Camera_ct,
}
