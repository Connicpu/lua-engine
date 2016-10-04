local ffi = require("ffi")
local class = require("class")
local vector = require("engine.datastructures.vector")
local vecmap = require("engine.datastructures.vecmap")
local hash_keys = require("engine.datastructures.hash_keys")

local ffi_new = ffi.new

local module = {}

function module.define(name, ctype, needs_dtor)
    local vlist_t = vecmap.type(ctype, needs_dtor)
    local index_t = hash_keys.uint32_t
    local process_queue_t = vector.type(index_t, false)
    local complist_t = ffi.typeof([[
        struct {
            $ values;
            $ process_queue;
        }
    ]], vlist_t, process_queue_t)
    local iterstate_t = ffi.typeof([[
        struct {
            $ *values;
            size_t i;
        }
    ]], vlist_t)
    local proc_iterstate_t = ffi.typeof([[
        struct {
            $ *queue;
            size_t i;
        }
    ]], process_queue_t)

    local CompList = class()

    function CompList:initialize()
        local values = vlist_t(512)
        local process_queue = process_queue_t(64)
        self.data = ffi_new(complist_t, values, process_queue)
    end

    local function values_iter(state)
        local i, value = state.values[0]:next(state.i)
        if i ~= nil then
            state.i = i
        end
        return i, value        
    end
    function CompList:iter()
        local state = iterstate_t(self.values, 0)
    end

    -- TODO: Register the component type or something?
end

return module
