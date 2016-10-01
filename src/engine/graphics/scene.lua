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

local Sprite_t = ffi.typeof("struct{scene *scene;sprite_handle handle;}")
local Sprite = {}
local Sprite_mt = { __index = Sprite }
local Sprite_ct

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

local sparams_t = ffi.typeof("struct sprite_params")
local function parse_stype(str)
    if str == 'translucent' then
        return false, true
    elseif str == 'static' then
        return true, false
    elseif str == 'standard' or str == nil then
        return false, false
    end
    error("Unknown sprite type")
end
local function parse_uv(uv)
    if not uv then return math.vec2(0, 0), math.vec2(1, 1) end
    local tl = uv.topleft or math.vec2(0, 0)
    local br = uv.bottomright or math.vec2(1, 1)
    return tl, br
end
function Scene:create_sprite(params)
    local sparams = ffi_new(sparams_t)
    sparams.is_static, sparams.is_translucent = parse_stype(params.type)
    sparams.layer = params.layer or 0
    sparams.tex = params.texture.tex
    sparams.uv_topleft, sparams.uv_bottomright = parse_uv(params.uv)
    sparams.transform = params.transform or math.matrix2d.identity()
    sparams.tint = params.tint or math.color(1, 1, 1, 1)
    return Sprite_ct(self.scene, check_ptr(__rd.rd_create_sprite(self.scene, sparams)))
end

function Sprite_mt:__gc()
    self:destroy()
end

function Sprite:destroy()
    if self.handle ~= nil then
        __rd.rd_destroy_sprite(self.scene, self.handle)
        self.handle = nil
    end
end

Scene_ct = ffi.metatype(Scene_t, Scene_mt)
Sprite_ct = ffi.metatype(Sprite_t, Sprite_mt)

return {
    Scene = Scene_ct,
    Sprite = Sprite_ct,
}
