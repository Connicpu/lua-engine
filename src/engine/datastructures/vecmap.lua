local ffi = require("ffi")
local vector = require("engine.datastructures.vector")

local ffi_new = ffi.new

local exists_entry = ffi.typeof("struct{bool exists;}")
local exists_list_t = vector.type(exists_entry, false)

local function build_type(value_t, needs_dtor)
    local value_list_t = vector.type(value_t, false)
    local vecmap_t = ffi.typeof([[
        struct {
            $ data;
            $ exists;
        }
    ]], value_list_t, exists_list_t)

    local VecMap = {}
    local VecMap_mt = { __index = VecMap }
    local VecMap_ct

    local function alloc(self, required)
        if self.exists.len >= required then
            return
        end

        self.data:zero_extend(required)
        self.exists:zero_extend(required)
    end

    function VecMap_mt.__new(tp, cap)
        local vm = ffi_new(tp)
        if cap then
            alloc(self, cap)
        end
        return vm
    end

    if needs_dtor then
        function VecMap_mt:__gc()
            for i, v in ipairs(self) do
                ffi_new(value_t, v)
            end
            ffi_new(exists_list_t, self.exists)
            ffi_new(value_list_t, self.data)
        end
    else
        function VecMap_mt:__gc()
            ffi_new(exists_list_t, self.exists)
            ffi_new(value_list_t, self.data)
        end
    end

    function VecMap:insert(i, value)
        if i > self.exists.len then
            alloc(self, i + 1)
        end

        if self.exists:get(i).exists = true
        return self.data:replace(i, value)
    end

    function VecMap:get(i)
        if i < 1 or i > self.exists.len then
            return nil
        end
        if not self.exists:get(i).exists then
            return nil
        end
        return self.data:get(i)
    end

    function VecMap:remove(i)
        if i < 1 or i > self.exists.len then
            return nil
        end
        local e_entry = self.exists:get(i)
        if not e_entry.exists then
            return nil
        end
        e_entry.exists = false
        return ffi_new(value_t, self.data:get(i))
    end

    local function iter(self, i)
        repeat
            i = i + 1
        until i > self.exists.len or self.exists:get(i).exists

        if i <= self.exists.len then
            return i, self.data:get(i)
        end
    end

    function VecMap_mt.__ipairs()
        return iter, self, 0
    end
end

local cache = {}

local function get_type(value_t, needs_dtor)
    if needs_dtor == nil then
        needs_dtor = true
    end
    if not cache[value_t] then
        cache[value_t] = {
            [true] = build_type(value_t, true),
            [false] = build_type(value_t, false),
        }
    end
    return cache[value_t][needs_dtor]
end

return {
    type = get_type
}
