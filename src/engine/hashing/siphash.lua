local ffi = require("ffi")
local bit = require("bit")
local bits = require("engine.utility.bits")
local hash_base = require("engine.hashing.base")

local ffi_new = ffi.new
local ffi_cast = ffi.cast

local bit_and = bit.band
local bit_xor = bit.bxor
local bit_lsl = bit.lshift
local bit_lsr = bit.rshift
local bit_rol = bit.rol
local bit_or = bit.bor

local load64 = bits.load_u64_le

ffi.cdef[[
    struct siphash_state {
        uint64_t v0, v2, v1, v3;
    };

    struct siphash13 {
        uint64_t k0, k1;
        size_t length;
        struct siphash_state state;
        uint64_t tail;
        size_t ntail;
    };

    struct siphash_builder13 {
        uint64_t k0, k1;
    };
    
    struct siphash24 {
        uint64_t k0, k1;
        size_t length;
        struct siphash_state state;
        uint64_t tail;
        size_t ntail;
    };

    struct siphash_builder24 {
        uint64_t k0, k1;
    };
]]

local SipHash = hash_base.impl({})
local SipHash_mt = {}

local SipHash13 = {}
local SipHash13_mt = { __index = SipHash13 }
local SipHash13_ct

local SipHash24 = {}
local SipHash24_mt = { __index = SipHash24 }
local SipHash24_ct

local SipHash_builder = {}
local SipHash_builder_mt = {}

local SipHash13_builder = {}
local SipHash13_builder_mt = { __index = SipHash13_builder }
local SipHash13_builder_ct

local SipHash24_builder = {}
local SipHash24_builder_mt = { __index = SipHash24_builder }
local SipHash24_builder_ct

local function random_key()
    local p0 = math.random(0, 0xFFFFFFFF)+0ull
    local p1 = math.random(0, 0xFFFFFFFF)+0ull
    return bit_or(p0, bit_lsl(p1, 32))
end

local function compress(state)
    state.v0 = state.v0 + state.v1
    state.v1 = bit_rol(state.v1, 13)
    state.v1 = bit_xor(state.v1, state.v0)
    state.v0 = bit_rol(state.v0, 32)

    state.v2 = state.v2 + state.v3
    state.v3 = bit_rol(state.v3, 16)
    state.v3 = bit_xor(state.v3, state.v2)

    state.v0 = state.v0 + state.v3
    state.v3 = bit_rol(state.v3, 21)
    state.v3 = bit_xor(state.v3, state.v0)

    state.v2 = state.v2 + state.v1
    state.v1 = bit_rol(state.v1, 17)
    state.v1 = bit_xor(state.v1, state.v2)
    state.v2 = bit_rol(state.v2, 32)
end

function SipHash_mt.__new(tp, k0, k1)
    local sip = ffi_new(tp)
    sip.k0 = k0
    sip.k1 = k1
    sip:reset()
    return sip
end

function SipHash:reset()
    self.length = 0
    self.state.v0 = bit_xor(self.k0, 0x736f6d6570736575)
    self.state.v1 = bit_xor(self.k1, 0x646f72616e646f6d)
    self.state.v2 = bit_xor(self.k0, 0x6c7967656e657261)
    self.state.v3 = bit_xor(self.k1, 0x7465646279746573)
    self.ntail = 0
end

function SipHash13:_c_rounds(m)
    compress(self.state)
end
function SipHash13:_d_rounds()
    compress(self.state)
    compress(self.state)
    compress(self.state)
end

function SipHash24:_c_rounds(m)
    self.state.v3 = bit_xor(state.v3, m)
    compress(self.state)
    compress(self.state)
    self.state.v0 = bit_xor(state.v0, m)
end
function SipHash24:_d_rounds()
    compress(self.state)
    compress(self.state)
    compress(self.state)
    compress(self.state)
end

local pbuf = ffi.typeof("const uint8_t *")
function SipHash:write(msg, len)
    self.length = self.length + len

    local needed = 0
    if self.ntail ~= 0 then
        needed = 8 - self.ntail
        if len < needed then
            local value = load64(msg, 0, len)
            self.tail = bit_or(self.tail, bit_lsl(value, 8 * self.ntail))
            self.ntail = self.ntail + len
        end

        local value = load64(msg, 0, needed)
        local m = bit_or(self.tail, bit_lsl(value, 8 * self.ntail))
        self:_c_rounds(m)

        self.ntail = 0
    end

    len = len - needed
    local left = bit_and(len, 7)

    local i = needed
    while i < len - left do
        local m = load64(msg, i)

        self:_c_rounds(m)

        i = i + 8
    end

    self.tail = load64(msg, i, left)
    self.ntail = left
end

function SipHash:finish()
    local state = self.state
    local b = bit_or(bit_lsl(bit_and(self.length, 0xFFull), 56), self.tail)

    self:_c_rounds(b)

    state.v2 = bit_xor(state.v2, 0xff)
    self:_d_rounds()

    local v0, v1, v2, v3 = state.v0, state.v1, state.v2, state.v3
    return bit_xor(bit_xor(v0, v1), bit_xor(v2, v3))
end

function SipHash_builder_mt.__new(tp, k0, k1)
    k0 = k0 or random_key()
    k1 = k1 or random_key()
    return ffi_new(tp, k0, k1)
end

function SipHash_builder:reseed(k0, k1)
    self.k0 = k0 or random_key()
    self.k1 = k1 or random_key()
end

function SipHash13_builder:build()
    return SipHash13_ct(self.k0, self.k1)
end

function SipHash24_builder:build()
    return SipHash24_ct(self.k0, self.k1)
end

for k, fn in pairs(SipHash) do
    SipHash13[k] = fn
    SipHash24[k] = fn
end
for k, fn in pairs(SipHash_mt) do
    SipHash13_mt[k] = fn
    SipHash24_mt[k] = fn
end
for k, fn in pairs(SipHash_builder) do
    SipHash13_builder[k] = fn
    SipHash24_builder[k] = fn
end
for k, fn in pairs(SipHash_builder_mt) do
    SipHash13_builder_mt[k] = fn
    SipHash24_builder_mt[k] = fn
end

SipHash13_ct = ffi.metatype("struct siphash13", SipHash13_mt)
SipHash13_builder_ct = ffi.metatype("struct siphash_builder13", SipHash13_builder_mt)
SipHash24_ct = ffi.metatype("struct siphash24", SipHash24_mt)
SipHash24_builder_ct = ffi.metatype("struct siphash_builder24", SipHash24_builder_mt)

return {
    builder13 = SipHash13_builder_ct,
    builder24 = SipHash24_builder_ct
}
