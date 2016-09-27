local ffi = require("engine.graphics.renderer")
local rd_err = require("engine.graphics.error")

local C = ffi.C
local check_ptr = rd_err.check_ptr
local ffi_new = ffi.new
local ffi_cast = ffi.cast
local ffi_gc = ffi.gc
local ffi_string = ffi.string

local dparams = ffi.typeof("struct device_params")

local Device_t = ffi.typeof("struct{device *dev;}")
local Device = {}
local Device_mt = { __index = Device }
local Device_ct

function Device_mt.__new(tp, inst, adapter, debug)
    debug = debug or false
    local params = ffi_new(dparams, inst.inst, adapter, debug)
    local dev = check_ptr(__rd.rd_create_device(params))
    return ffi_new(tp, dev)
end

function Device_mt:__gc()
    self:destroy()
end

function Device:destroy()
    if self.dev ~= nil then
        __rd.rd_free_device(self.dev)
        self.dev = nil
    end
end

Device_ct = ffi.metatype(Device_t, Device_mt)

return {
    Device = Device_ct
}
