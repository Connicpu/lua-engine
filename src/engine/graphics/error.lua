local ffi = require("engine.graphics.renderer.error")
local debug = require("debug")

local ffi_string = ffi.string

local temp = {
    last_error = ffi.new("struct renderer_error[1]")
}

local function fail()
    if __rd.rd_last_error(temp.last_error) then
        local fmt = "Renderer Error (0x%08X): %s"
        local code = temp.last_error[0].system_code
        local msg = ffi_string(temp.last_error[0].message)
        error(string.format(fmt, code, msg))
    end
    error("Unknown renderer error (fail called, but rd_last_error was blank)")
end

local function check_ptr(ptr)
    if ptr == nil then
        fail()
    end
    return ptr
end

local function check_bool(result)
    if not result then
        fail()
    end
end

return {
    fail = fail,
    check_ptr = check_ptr,
    check_bool = check_bool,
}
