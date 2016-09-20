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
    -- This is the type that gets stored inside the flat array
    -- of our hashmap, holding the key, value, and stored
    -- hash code, including the bit used for tombstoning
    local entry_t = ffi.typeof([[
        struct {
            $ key;
            $ value;
            uint32_t hash;
        }
    ]], key_t, value_t)

    -- This is a safe reference type we can cast entries to
    -- for returning back to the user, without allowing them
    -- to modify the key or hash, but the value is up for
    -- grabs.
    local const_entry_t = ffi.typeof([[
        struct {
            $ const key;
            $ value;
            const uint32_t hash;
        }
    ]], key_t, value_t)
    -- A reference to the type we just defined up there ;)
    local const_entry_ref_t = ffi.typeof("$ &", const_entry_t)

    -- This is the actual structure for the hashmap itself.
    -- Certain hasher types (e.g. siphash) need to keep a
    -- hash_state around because they generate hash codes that
    -- may differ from instance to instance for security reasons.
    -- Then we have `data` for the actual hash flat array. This
    -- is a standard open-addressing hashmap, except we keep the
    -- hash_code around for efficient robin-hood hashing.
    -- Finally, we store the cap and len for bookkeeping, and
    -- max_probe is thrown in for debugging purposes.
    local hashmap_t = ffi.typeof([[
        struct {
            $ hash_state;
            $ *data;
            uint32_t cap;
            uint32_t len;
            uint32_t max_probe;
        }
    ]], hasher_t, entry_t)

    -- We need the entry size kept around so
    -- we don't have to ask ffi for it every
    -- time we grow the map.
    local sizeof_entry = ffi.sizeof(entry_t)

    local HashMap = {}
    local HashMap_mt = { __index = HashMap }
    local HashMap_ct

    -- The HashMap([hasher]) constructor does not allocate.
    -- As an implementation detail, we immediately allocate
    -- 64 slots of room on first insertion.
    function HashMap_mt.__new(hashmap_t, hasher)
        hasher = hasher or hasher_t()
        return ffi_new(hashmap_t, hasher, nil, 0, 0)
    end

    -- Generate specialized destructors based on
    -- what we've been told about which pieces of
    -- data may hold destructors
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

    -- Calculate the hash of a given key, and truncating it
    -- to 31 bits to leave room for the tombstone bit.
    local function hash_key(self, key)
        local hasher = self.hash_state:build()
        local hash

        key:hash(hasher)
        hash = hasher:finish()
        hash = bit_and(hash, 0x7FFFFFFF)

        if hash == 0 then hash = 1 end
        return hash
    end

    -- Helper function to determine if the tombstone
    -- bit is set on a given hash value.
    local function is_deleted(hash)
        return bit_lsr(hash, 31) ~= 0
    end

    -- Given a plain hash value, determine its ideal address
    -- in the array.
    local function desired_pos(self, hash)
        return bit_and(hash, 0x7FFFFFFF) % self.cap
    end

    -- Given a hash value and where it was found, determine
    -- how far it is from its ideal address
    local function probe_distance(self, hash, slot_index)
        return (slot_index + self.cap - desired_pos(self, hash)) % self.cap
    end

    -- Allocate data to be a fresh array for an empty hashmap
    local function alloc(self)
        self.data = C.calloc(self.cap, sizeof_entry)
    end

    -- A couple temporary slots used during the insert_helper.
    -- insert_helper is not reentrant, so this is fine being
    -- shared between all instances of hashmaps of this type.
    local temp_entry = ffi.new(ffi.typeof("$[2]", entry_t))

    -- From a hash value, key, and value, insert the data into
    -- a hashmap. It is the caller's responsibility to ensure
    -- the array has room and that this key is not a duplicate.
    -- It is undetermined what would happen if this is not the
    -- case, but it is likely data would be leaked or an infinite
    -- loop would occur.
    local function insert_helper(self, hash, key, value)
        -- Determine the ideal address
        local pos = desired_pos(self, hash)
        local dist = 0

        -- Put out data into the temporary slot
        temp_entry[0].key = key
        temp_entry[0].value = value
        temp_entry[0].hash = hash

        -- Loop until our insertion has finished
        while true do
            local e = self.data[pos]

            -- If the current position is empty, this is the best slot
            -- for our data. Insert it and return.
            if e.hash == 0 then
                self.data[pos] = temp_entry[0]
                return
            end

            -- There is already an item here, so determine how far this
            -- weary traveller has gone. If it got luckier than we've been,
            -- "steal from the rich" and boot them out.
            local e_probe_dist = probe_distance(self, e.hash, pos)
            if e_probe_dist < dist then
                -- If this slot was tombstoned, then we can just settle right in.
                if is_deleted(e.hash) then
                    self.data[pos] = temp_entry[0]
                    return
                end

                -- Otherwise do a swap and turn the old value into the traveller.
                temp_entry[1] = e
                self.data[pos] = temp_entry[0]
                temp_entry[0] = temp_entry[1]
                dist = e_probe_dist
            end

            -- Move to the next location for travel
            pos = (pos + 1) % self.cap
            dist = dist + 1

            -- Store the max probe for debug purposes
            if dist > self.max_probe then
                self.max_probe = dist
            end
        end
    end

    -- Given a key, try to find it in the hashmap.
    local function lookup_index(self, key)
        -- Early out on empty hashmap
        if self.len == 0 then
            return nil
        end

        -- Get the hash and ideal address
        local hash = hash_key(self, key)
        local pos = desired_pos(self, hash)
        local dist = 0

        -- Loop until we either find it or know for
        -- sure the value doesn't exist
        while true do
            local e = self.data[pos]
            -- An empty slot means it couldn't have touched here
            if e.hash == 0 then
                return nil
            -- If we have travelled further than what's already here,
            -- it couldn't have gotten here.
            elseif dist > probe_distance(self, e.hash, pos) then
                return nil
            -- If the hash matches, let's check it!
            elseif e.hash == hash and key == e.key then
                return pos
            end

            -- Not this slot, move along
            pos = (pos + 1) % self.cap
            dist = dist + 1
        end
    end

    -- Tombstone a slot
    local function erase(self, idx)
        local e = self.data[idx]
        e.hash = bit_or(e.hash, 0x80000000)
        self.len = self.len - 1
    end

    -- Double our cap (or set it to 64) and reinsert all
    -- of the old values. Thankfully we don't have to
    -- rehash the keys!
    local function grow(self)
        -- Save the old data
        local old_data = self.data
        local old_cap = self.cap

        -- Give us some room to work
        if self.cap == 0 then
            self.cap = 64
        else
            self.cap = self.cap * 2
        end
        alloc(self)

        -- Insert all of the previous values
        for i = 0, old_cap-1 do
            local e = old_data[i]
            local hash = e.hash
            if hash ~= 0 and not is_deleted(hash) then
                insert_helper(hash, e.key, e.value)
            end
        end

        -- Free the old array
        C.free(old_data)
    end

    -- Insert a key and value into the array. Make sure
    -- to copy the values if you want to keep your own
    -- because the hashmap will be in charge of their
    -- destructor until you remove() them (if ever)
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

    -- Given the key, if it exists in the array, it will be
    -- removed and returned to you, with the default __gc
    -- metamethod reinstated. Whatever type `key` is, it
    -- must have an __eq metamethod that handles key_t passed
    -- as the second argument, and must have a self:hash(h) member
    -- function that works to produce the same hash value as
    -- the value it is equal to.
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

    -- Gets an entry if it exists in the array. `key` follows the
    -- exact same rules as in `remove` above here.
    function HashMap:find(key)
        local idx = lookup_index(self, key)
        if idx then
            return ffi_cast(const_entry_ref_t, self.data[idx])
        end
    end

    -- Just like `find`, but just returns the value element
    function HashMap:get(key)
        local idx = lookup_index(self, key)
        if idx then
            return self.data[idx].value
        end
    end

    local iterstate_t

    -- Iterator generator for the hashmap, yields entries
    local function iter(state)
        local self = state.map[0]
        local e = self.data[state.pos]
        -- Skip over tombstoned values
        while state.pos < self.cap and (e.hash == 0 or is_deleted(e.hash)) do
            state.pos = state.pos + 1
            e = self.data[state.pos]
        end
        -- Check for reaching the end
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

    -- Type used for the iterator state
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

