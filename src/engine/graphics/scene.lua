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

local Scene_t = ffi.typeof("struct{scene *scene;}")
local Scene = {}
local Scene_mt = { __index = Scene }
local Scene_ct

function Scene_mt.__new(tp, dev, gw, gh)
    local scene = check_ptr(__rd.rd_create_scene(dev.dev, gw, gh))
    return ffi_new(tp, scene)
end

function Scene_mt:__gc()
    self:destroy()
end

function Scene:destroy()
    if self.scene ~= nil then
        __rd.rd_free_scene(self.scene)
        self.scene = nil
    end
end

function Scene:draw(dev, rt, cam, vp)
    if vp == nil then
        error("Viewport cannot be nil")
    end
    check_bool(__rd.rd_draw_scene(dev.dev, rt.rt, self.scene, cam.cam, vp))
end

Scene_ct = ffi.metatype(Scene_t, Scene_mt)

return {
    Scene = Scene_ct,
}
