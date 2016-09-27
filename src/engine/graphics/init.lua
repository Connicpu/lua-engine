local instance = require("engine.graphics.instance")
local device = require("engine.graphics.device")
local window = require("engine.graphics.window")

return {
    set_backend = instance.set_backend,
    Instance = instance.Instance,
    Device = device.Device,
    Window = window.Window,
}
