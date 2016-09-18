local ffi = require("ffi")
local module = {}

local ffi_cast = ffi.cast
local cbuf = ffi.typeof("const uint8_t *")

local function build_temp(ct)
    ct = ffi.typeof(ct)
    local size = ffi.sizeof(ct)
    local union = ffi.typeof("union{$ v; uint8_t a[$];}", ct, size)
    return ffi.new(union)
end

local i8 = build_temp("int8_t")
local i16 = build_temp("int16_t")
local i32 = build_temp("int32_t")
local i64 = build_temp("int64_t")
local u8 = build_temp("uint8_t")
local u16 = build_temp("uint16_t")
local u32 = build_temp("uint32_t")
local u64 = build_temp("uint64_t")
local f32 = build_temp("float")
local f64 = build_temp("double")

local function pun(temp, v)
    temp.v = v
    return temp.a
end

function module.impl(hasher)
    -- Signed Integers
    function hasher:write_i8(v)
        self:write(pun(i8, v), 1)
    end
    function hasher:write_i16(v)
        self:write(pun(i16, v), 2)
    end
    function hasher:write_i32(v)
        self:write(pun(i32, v), 4)
    end
    function hasher:write_i64(v)
        self:write(pun(i64, v), 8)
    end
    
    -- Unsigned integers
    function hasher:write_u8(v)
        self:write(pun(u8, v), 1)
    end
    function hasher:write_u16(v)
        self:write(pun(u16, v), 2)
    end
    function hasher:write_u32(v)
        self:write(pun(u32, v), 4)
    end
    function hasher:write_u64(v)
        self:write(pun(u64, v), 8)
    end

    -- Floating point numbers
    function hasher:write_f32(v)
        self:write(pun(f32, v), 4)
    end
    function hasher:write_f64(v)
        self:write(pun(f64, v), 8)
    end

    -- Other
    function hasher:write_str(s)
        self:write(ffi_cast(cbuf, s), #s)
    end

    return hasher
end

return module
