local ffi = require("engine.graphics.renderer.instance")
local rd_err = require("engine.graphics.error")

local check_ptr = rd_err.check_ptr

local Instance = class()

function Instance:initialize(backend)
    local rd = ffi.load(backend)
    local inst = check_ptr(rd, rd.rd_create_instance())
    
    self.dll = rd
    self.inst = inst
end

return {
    Instance = Instance
}
