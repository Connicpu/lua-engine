local instance = require("engine.graphics.instance")
local device = require("engine.graphics.device")
local window = require("engine.graphics.window")
local render_target = require("engine.graphics.render_target")
local scene = require("engine.graphics.scene")
local camera = require("engine.graphics.camera")
local texture = require("engine.graphics.texture")

return {
    set_backend = instance.set_backend,
    Instance = instance.Instance,
    Device = device.Device,
    Window = window.Window,
    RenderTarget = render_target.RenderTarget,
    Scene = scene.Scene,
    Camera = camera.Camera,
    TextureArray = texture.TextureArray,
    Texture = texture.Texture,
}
