local ffi = require("ffi")
local bit = require("bit")
local module = {}

local bswap = bit.bswap
local bit_or = bit.bor
local bit_lsl = bit.lshift

if ffi.abi("le") then
    function module.to_le(num)
        return num
    end
    function module.from_le(num)
        return num
    end
    function module.to_be(num)
        return bswap(num)
    end
    function module.from_be(num)
        return bswap(num)
    end
else -- big endian
    function module.to_be(num)
        return num
    end
    function module.from_be(num)
        return num
    end
    function module.to_le(num)
        return bswap(num)
    end
    function module.from_le(num)
        return bswap(num)
    end
end

if jit.arch == "x64" then -- x64 can do 0-overhead unaligned loads
    local pu64 = ffi.typeof("uint64_t *")
    function module.load_u64_le(buf, offset, len)
        if len then
            local out = 0ULL
            for i = 0, len-1 do
                out = bit_or(out, bit_lsl(buf[offset + i] + 0ull, i * 8))
            end
            return module.to_le(out)
        else
            return module.to_le(ffi.cast(pu64, buf + offset)[0])
        end
    end
else
    function module.load_u64_le(buf, offset, len)
        len = len or 8
        local out = 0ULL
        for i = 0, len-1 do
            out = bit_or(out, bit_lsl(buf[offset + i] + 0ull, i * 8))
        end
        return module.to_le(out)
    end
end

return module
