local ffi = require("ffi")
local class = require("engine.class")
local vector = require("engine.datastructures.vector")
local vecmap = require("engine.datastructures.vecmap")

local ffi_new = ffi.new

local module = {}

function module.define(name, ctype, needs_dtor)
    local vlist_t = vecmap.type(ctype, needs_dtor)
    local index_t = ffi.typeof("struct{uint32_t i;}")
    local process_queue_t = vector.type(index_t, false)
    local complist_t = ffi.typeof([[
        struct {
            $ values;
            $ process_queue;
        }
    ]])
    local iterstate_t = ffi.typeof([[
        struct {
            $ *values;
            size_t i;
        }
    ]])

    local CompList = class()

    function CompList:initialize()
        local values = vlist_t(512)
        local process_queue = process_queue_t(64)
        self.data = ffi_new(complist_t, values, process_queue)
    end

    function CompList:iter()
        return ipairs(self.data.values)
    end

    -- TODO: Register the component type or something?
end

return module
