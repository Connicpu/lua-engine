local ffi = require("engine.graphics.renderer")
local rd_err = require("engine.graphics.error")

local C = ffi.C
local check_ptr = rd_err.check_ptr
local ffi_new = ffi.new
local ffi_cast = ffi.cast
local ffi_gc = ffi.gc
local ffi_string = ffi.string

local adapter_t = ffi.typeof("struct adapter_output")
local adapter_ptr = ffi.typeof("$ *", adapter_t)
local adapter_list = ffi.typeof("struct{adapter_output *list;uint32_t len;}")
local adapter_size = ffi.sizeof(adapter_t)

local Instance_t = ffi.typeof("struct{instance *inst;}")
local Instance = {}
local Instance_mt = { __index = Instance }
local Instance_ct

local function set_backend(backend)
    __rd = ffi.load(backend)
    if not __rd then
        error("Failed to load backend")
    end
end

function Instance_mt.__new(tp)
    local inst = check_ptr(__rd.rd_create_instance())
    return ffi_new(tp, inst)
end

function Instance_mt:__gc()
    self:destroy()
end

function Instance:destroy()
    if self.inst ~= nil then
        __rd.rd_free_instance(self.inst)
        self.inst = nil
    end
end

local function free_adapters(self)
    C.free(self.list)
end
function Instance:get_adapters()
    local count = __rd.rd_get_outputs(self.inst, 0, nil)
    local adapters = ffi_new(adapter_list)
    local adapter_mem = C.malloc(adapter_size * count)
    adapters.list = ffi_cast(adapter_ptr, adapter_mem)
    adapters.len = count
    adapters = ffi_gc(adapters, free_adapters)
    assert(__rd.rd_get_outputs(self.inst, count, adapters.list) == count)

    return adapters
end

function Instance:best_adapter()
    local adapters = self:get_adapters()
    local adapter_i = 0
    for i = 0, adapters.len-1 do
        if adapters.list[i].device_memory > adapters.list[adapter_i].device_memory then
            adapter = i
        end
    end
    return adapters.list[adapter_i].id
end

Instance_ct = ffi.metatype(Instance_t, Instance_mt)

-- Give a tostring for adapter_output
local function format_ram(amt)
    amt = tonumber(amt)

    local suffixes = { "kb", "mb", "gb", "tb", [0] = "" }
    local pow = 0
    while amt >= 1024 and pow < #suffixes do
        pow = pow + 1
        amt = amt / 1024
    end

    if amt == math.floor(amt) then
        return string.format("%d%s", amt, suffixes[pow])
    else
        return string.format("%.1f%s", amt, suffixes[pow])
    end
end
ffi.metatype(adapter_t, {
    __tostring = function(self)
        return string.format(
            "Device(%q, vram: %s, sysram: %s)",
            ffi_string(self.device_name),
            format_ram(self.device_memory),
            format_ram(self.system_memory)
        )
    end,
})

return {
    Instance = Instance_ct,
    set_backend = set_backend,
}
