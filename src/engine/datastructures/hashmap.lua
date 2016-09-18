local ffi = require("ffi")
local bit = require("bit")
local fnv1a = require("engine.hashing.fnv1a")

local bit_lsr = bit.rshift
local bit_and = bit.band
local bit_or = bit.bor

ffi.cdef[[
    void *calloc(size_t num, size_t size);
    void free(void *ptr);
]]

local ffi_new = ffi.new
local ffi_cast = ffi.cast
local C = ffi.C

local function build_type(key_t, value_t, hasher_t, needs_dtor)

    local entry_t = ffi.typeof([[
        struct {
            $ key;
            $ value;
            uint32_t hash;
        }
    ]], key_t, value_t)
    local const_entry_t = ffi.typeof([[
        struct {
            $ const key;
            $ value;
            const uint32_t hash;
        }
    ]], key_t, value_t)
    local const_entry_ref_t = ffi.typeof("$ &", const_entry_t)
    local hashmap_t = ffi.typeof([[
        struct {
            $ hash_state;
            $ *data;
            uint32_t cap;
            uint32_t len;
            uint32_t max_probe;
        }
    ]], hasher_t, entry_t)

    local sizeof_entry = ffi.sizeof(entry_t)

    local HashMap = {}
    local HashMap_mt = { __index = HashMap }
    local HashMap_ct

    function HashMap_mt.__new(hashmap_t, hasher)
        hasher = hasher or hasher_t()
        return ffi_new(hashmap_t, hasher, nil, 0, 0)
    end

    if needs_dtor == true then
        function HashMap_mt:__gc()
            for e in pairs(self) do
                ffi_new(key_t, e.key)
                ffi_new(value_t, e.value)
            end
            C.free(self.data)
        end
    elseif needs_dtor == 'key' then
        function HashMap_mt:__gc()
            for e in pairs(self) do
                ffi_new(key_t, e.key)
            end
            C.free(self.data)
        end
    elseif needs_dtor == 'value' then
        function HashMap_mt:__gc()
            for e in pairs(self) do
                ffi_new(value_t, e.value)
            end
            C.free(self.data)
        end
    else
        function HashMap_mt:__gc()
            C.free(self.data)
        end
    end

    local function hash_key(self, key)
        local hasher = self.hash_state:build()
        local hash

        key:hash(hasher)
        hash = hasher:finish()
        hash = bit_and(hash, 0x7FFFFFFF)

        if hash == 0 then hash = 1 end
        return hash
    end

    local function is_deleted(hash)
        return bit_lsr(hash, 31) ~= 0
    end

    local function desired_pos(self, hash)
        return hash % self.cap
    end

    local function probe_distance(self, hash, slot_index)
        return (slot_index + self.cap - desired_pos(self, hash)) % self.cap
    end

    local function alloc(self)
        self.data = C.calloc(self.cap, sizeof_entry)
        for i = 0, self.cap-1 do
            self.data[i].hash = 0
        end
    end

    local temp_entry = ffi.new(ffi.typeof("$[2]", entry_t))

    local function insert_helper(self, hash, key, value)
        local pos = desired_pos(self, hash)
        local dist = 0

        temp_entry[0].key = key
        temp_entry[0].value = value
        temp_entry[0].hash = hash

        while true do
            local e = self.data[pos]
            if e.hash == 0 then
                self.data[pos] = temp_entry[0]
                return
            end

            local e_probe_dist = probe_distance(self, e.hash, pos)
            if e_probe_dist < dist then
                if is_deleted(e.hash) then
                    self.data[pos] = temp_entry[0]
                    return
                end

                temp_entry[1] = e
                self.data[pos] = temp_entry[0]
                temp_entry[0] = temp_entry[1]
                dist = e_probe_dist
            end

            pos = (pos + 1) % self.cap
            dist = dist + 1

            if dist > self.max_probe then
                self.max_probe = dist
            end
        end
    end

    local function lookup_index(self, key)
        if self.cap == 0 then
            return nil
        end

        local hash = hash_key(self, key)
        local pos = desired_pos(self, hash)
        local dist = 0
        while true do
            local e = self.data[pos]
            if e.hash == 0 then
                return nil
            elseif dist > probe_distance(self, e.hash, pos) then
                return nil
            elseif e.hash == hash and e.key == key then
                return pos
            end

            pos = (pos + 1) % self.cap
            dist = dist + 1
        end
    end

    local function erase(self, idx)
        local e = self.data[idx]
        e.hash = bit_or(e.hash, 0x80000000)
        self.len = self.len - 1
    end

    local function grow(self)
        local old_data = self.data
        local old_cap = self.cap

        if self.cap == 0 then
            self.cap = 64
        else
            self.cap = self.cap * 2
        end
        alloc(self)

        for i = 0, old_cap-1 do
            local e = old_data[i]
            local hash = e.hash
            if hash ~= 0 and not is_deleted(hash) then
                insert_helper(hash, e.key, e.value)
            end
        end

        C.free(old_data)
    end

    function HashMap:insert(key, value)
        key = ffi.gc(key, nil)
        value = ffi.gc(value, nil)

        -- Remove old value
        local old_key, old_value = self:remove(key)

        if self.len >= self.cap*0.95 then
            grow(self)
        end

        local hash = hash_key(self, key)
        insert_helper(self, hash, key, value)
        self.len = self.len + 1

        return old_key, old_value
    end

    function HashMap:remove(key)
        local old = lookup_index(self, key)
        local old_key, old_value
        if old then
            local e = self.data[old]
            old_key = ffi_new(key_t, e.key)
            old_value = ffi_new(value_t, e.value)
            erase(self, old)
        end
        return old_key, old_value
    end

    function HashMap:find(key)
        local idx = lookup_index(self, key)
        if idx then
            return ffi_cast(const_entry_ref_t, self.data[idx])
        end
    end

    function HashMap:get(key)
        local idx = lookup_index(self, key)
        if idx then
            return self.data[idx].value
        end
    end

    local iterstate_t

    local function iter(state)
        local self = state.map[0]
        local e = self.data[state.pos]
        while state.pos < self.cap and (e.hash == 0 or is_deleted(e.hash)) do
            state.pos = state.pos + 1
            e = self.data[state.pos]
        end
        if state.pos >= self.cap then
            return nil
        end

        state.pos = state.pos + 1
        return ffi_cast(const_entry_ref_t, e)
    end

    function HashMap_mt:__pairs()
        local state = iterstate_t(self, 0)
        return iter, state, nil
    end

    HashMap_ct = ffi.metatype(hashmap_t, HashMap_mt)
    iterstate_t = ffi.typeof([[
        struct {
            $ *map;
            uint32_t pos;
        }
    ]], HashMap_ct)

    return HashMap_ct
end

local HashMap_mt = {}
local HashMap = setmetatable({}, HashMap_mt)

local key_t_cache = {}
local KeyType_mt = {}

local ValueType = {}
local ValueType_mt = { __index = ValueType }

function HashMap_mt:__index(key_t)
    if key_t_cache[key_t] then
        return key_t_cache[key_t]
    end

    local key_type = setmetatable({
        __key_t = key_t,
        __value_t_cache = {}
    }, KeyType_mt)

    key_t_cache[key_t] = key_type
    return key_type
end

function KeyType_mt:__index(value_t)
    if self.__value_t_cache[value_t] then
        return self.__value_t_cache[value_t]
    end

    local value_type = setmetatable({
        __key_t = self.__key_t,
        __value_t = value_t,
        __cache = {}
    }, ValueType_mt)
    
    self.__value_t_cache[value_t] = value_type
    return value_type
end

function ValueType_mt:__call()
    local t = self:type()
    return t()
end

function ValueType:type(hasher_t, needs_dtor)
    if hasher_t == nil then
        hasher_t = fnv1a.builder
    end
    if needs_dtor == nil then
        needs_dtor = true
    end

    if not self.__cache[hasher_t] then
        self.__cache[hasher_t] = {
            [true] = build_type(self.__key_t, self.__value_t, hasher_t, true),
            ['key'] = build_type(self.__key_t, self.__value_t, hasher_t, 'key'),
            ['value'] = build_type(self.__key_t, self.__value_t, hasher_t, 'value'),
            [false] = build_type(self.__key_t, self.__value_t, hasher_t, false),
        }
    end

    return self.__cache[hasher_t][needs_dtor]
end

return HashMap

