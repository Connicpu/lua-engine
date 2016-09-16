local ffi = require("ffi")
local bit = require("bit")

local int32 = {}
local int32_mt = { __index = int32 }
local int32_ct

function int32:hash(hasher)
    hasher:write_i32(self)
end

local uint32 = {}
local uint32_mt = { __index = uint32 }
local uint32_ct

function uint32:hash(hasher)
    hasher:write_u32(self)
end

local int64 = {}
local int64_mt = { __index = int64 }
local int64_ct

function int64:hash(hasher)
    hasher:write_i64(self)
end

local uint64 = {}
local uint64_mt = { __index = uint64 }
local uint64_ct

function uint64:hash(hasher)
    hasher:write_u64(self)
end

local string = {}
local string_mt = { __index = string }
local string_ct



return {
    int32_t = int32_ct,
    uint32_t = uint32_ct,
    int64_t = int64_ct,
    uint64_t = uint64_ct,

    string = string_ct,
    string_dtor = string_mt.__gc
}
