local ffi = require("ffi")
local bit = require("bit")
local hash_base = require("engine.hashing.base")

local bit_and = bit.band
local bit_xor = bit.bxor

ffi.cdef[[
    struct fnv1a_builder {};
    struct fnv1a {
        uint32_t state;
    };
]]

local fnv1a_builder = {}
local fnv1a_builder_mt = { __index = fnv1a_builder }
local fnv1a_builder_ct

local fnv1a = hash_base.impl({})
local fnv1a_mt = { __index = fnv1a }
local fnv1a_ct

function fnv1a_builder:build()
    return fnv1a_ct(2166136261ull)
end

function fnv1a:write(buf, len)
    for i = 0, len-1 do
        self.state = bit_xor(self.state, buf[i])
        self.state = self.state * 16777619ull
    end
end

function fnv1a:finish()
    return self.state
end

fnv1a_builder_ct = ffi.metatype("struct fnv1a_builder", fnv1a_builder_mt)
fnv1a_ct = ffi.metatype("struct fnv1a", fnv1a_mt)

return {
    builder = fnv1a_builder_ct
}
