local ffi = require("ffi")
local bit = require("bit")

ffi.cdef[[
    void *malloc(size_t size);
    void free(void *ptr);
]]

local C = ffi.C
local ffi_new = ffi.new
local ffi_string = ffi.string
local ffi_istype = ffi.istype
local ffi_gc = ffi.gc

local int32 = {}
local int32_mt = { __index = int32 }
local int32_ct

function int32:hash(hasher)
    hasher:write_i32(self.value)
end

function int32_mt:__tostring()
    return tostring(self.value)
end

function int32_mt.__eq(lhs, rhs)
    return ffi_istype(int32_ct, lhs) and ffi_istype(int32_ct, rhs) and lhs.value == rhs.value
end

int32_ct = ffi.metatype("struct{int32_t value;}", int32_mt)

local uint32 = {}
local uint32_mt = { __index = uint32 }
local uint32_ct

function uint32:hash(hasher)
    hasher:write_u32(self.value)
end

function uint32_mt:__tostring()
    return tostring(self.value)
end

function uint32_mt.__eq(lhs, rhs)
    return ffi_istype(uint32_ct, lhs) and ffi_istype(uint32_ct, rhs) and lhs.value == rhs.value
end

uint32_ct = ffi.metatype("struct{uint32_t value;}", uint32_mt)

local int64 = {}
local int64_mt = { __index = int64 }
local int64_ct

function int64:hash(hasher)
    hasher:write_i64(self.value)
end

function int64_mt:__tostring()
    return tostring(self.value)
end

function int64_mt.__eq(lhs, rhs)
    return ffi_istype(int64_ct, lhs) and ffi_istype(int64_ct, rhs) and lhs.value == rhs.value
end

int64_ct = ffi.metatype("struct{int64_t value;}", int64_mt)

local uint64 = {}
local uint64_mt = { __index = uint64 }
local uint64_ct

function uint64:hash(hasher)
    hasher:write_u64(self.value)
end

function uint64_mt:__tostring()
    return tostring(self.value)
end

function uint64_mt.__eq(lhs, rhs)
    return ffi_istype(uint64_ct, lhs) and ffi_istype(uint64_ct, rhs) and lhs.value == rhs.value
end

uint64_ct = ffi.metatype("struct{uint64_t value;}", uint64_mt)

local string = {}
local string_mt = { __index = string }
local string_ct

function string:hash(hasher)
    hasher:write(self.data, self.len)
end

function string_mt.__new(tp, s, istemp)
    if type(s) ~= 'string' then
        error("Expected string")
    end

    if istemp then
        return ffi_gc(ffi_new(string_ct, s, #s), nil)
    else
        local ptr = C.malloc(#s)
        return ffi_new(string_ct, ptr, #s)
    end
end

function string_mt:__gc()
    C.free(self.data)
end

function string_mt:__tostring()
    return ffi_string(self.data, self.len)
end

function string_mt.__eq(lhs, rhs)
    if (not ffi_istype(string_ct, lhs)) or (not ffi_istype(string_ct, rhs)) then
        return false
    end

    if lhs.len ~= rhs.len then
        return false
    end

    for i = 0, lhs.len-1 do
        if lhs.data[i] ~= rhs.data[i] then
            return false
        end
    end

    return true
end

string_ct = ffi.metatype("struct{const uint8_t *data; uint32_t len;}", string_mt)

return {
    int32_t = int32_ct,
    uint32_t = uint32_ct,
    int64_t = int64_ct,
    uint64_t = uint64_ct,

    string = string_ct
}
