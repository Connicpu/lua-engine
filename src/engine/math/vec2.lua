local ffi = require("ffi")
local math = require("math")

local istype = ffi.istype
local sqrt = math.sqrt

ffi.cdef[[
    struct vec2 {
        float x;
        float y;
    };
]]

local vec2_class = {}
local vec2 = setmetatable({}, vec2_class)
local vec2_mt = { __index = vec2 }
local vec2_ct

-- Constructor
function vec2_class:__call(x, y)
    if x == nil then x = 0 end
    if y == nil then y = x end
    return vec2_ct(x, y)
end

function vec2.dot(lhs, rhs)
    local lvec = istype(vec2_ct, lhs)
    local rvec = istype(vec2_ct, rhs)
    if lvec and rvec then
        return lhs.x * rhs.x + lhs.y * rhs.y
    end
    error("Invalid types for vec2:dot")
end

function vec2:len2()
    return self:dot(self)
end

function vec2:len()
    return sqrt(self:len2())
end

--------------------------------------------------------
-- Operators

function vec2_mt:__tostring()
    return string.format("<%f, %f>", self.x, self.y)
end

function vec2_mt.__add(lhs, rhs)
    local lvec = istype(vec2_ct, lhs)
    local rvec = istype(vec2_ct, rhs)
    if lvec and rvec then
        return vec2_ct(lhs.x + rhs.x, lhs.y + rhs.y)
    end
    error("Invalid types for vec2:__add")
end

function vec2_mt.__sub(lhs, rhs)
    local lvec = istype(vec2_ct, lhs)
    local rvec = istype(vec2_ct, rhs)
    if lvec and rvec then
        return vec2_ct(lhs.x - rhs.x, lhs.y - rhs.y)
    end
    error("Invalid types for vec2:__sub")
end

function vec2_mt.__mul(lhs, rhs)
    local lvec = istype(vec2_ct, lhs)
    local rvec = istype(vec2_ct, rhs)
    if lvec and rvec then
        return vec2_ct(lhs.x * rhs.x, lhs.y * rhs.y)
    elseif lvec and type(rhs) == 'number' then
        return vec2_ct(lhs.x * rhs, lhs.y * rhs)
    elseif rvec and type(lhs) == 'number' then
        return vec2_ct(lhs * rhs.x, lhs * rhs.y)
    end
    error("Invalid types for vec2:__mul")
end

function vec2_mt.__div(lhs, rhs)
    local lvec = istype(vec2_ct, lhs)
    local rvec = istype(vec2_ct, rhs)
    if lvec and rvec then
        return vec2_ct(lhs.x / rhs.x, lhs.y / rhs.y)
    elseif lvec and type(rhs) == 'number' then
        return vec2_ct(lhs.x / rhs, lhs.y / rhs)
    elseif rvec and type(lhs) == 'number' then
        return vec2_ct(lhs / rhs.x, lhs / rhs.y)
    end
    error("Invalid types for vec2:__div")
end

function vec2_mt:__pow(power)
    if type(power) == 'number' then
        return vec2_ct(self.x ^ power, self.y ^ power)
    end
    error("Invalid types for vec2:__pow")
end

function vec2_mt:__unm()
    return vec2_ct(-self.x, -self.y)
end

vec2_ct = ffi.metatype("struct vec2", vec2_mt)
vec2.ctype = vec2_ct

return {
    vec2 = vec2
}
