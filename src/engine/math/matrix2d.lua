local ffi = require("ffi")
local math = require("math")
local vec2 = require("engine.math.vec2").vec2

local vec2_ct = vec2.ctype
local cos = math.cos
local sin = math.sin
local tan = math.tan
local abs = math.abs

ffi.cdef[[
    struct matrix2d {
        float m11, m12;
        float m21, m22;
        float m31, m32;
    };
]]

local matrix2d = {}
local matrix2d_mt = { __index = matrix2d }
local matrix2d_ct

function matrix2d.identity()
    return matrix2d_ct(
        1, 0,
        0, 1,
        0, 0
    )
end

function matrix2d.translation(x, y)
    if y == nil then
        x = x.x
        y = x.y
    end

    return matrix2d_ct(
        1, 0,
        0, 1,
        x, y
    )
end

function matrix2d.scale(scale, center)
    center = center or vec2_ct(0, 0)
    if type(center) == 'number' then
        scale = vec2_ct(scale, center)
        center = vec2_ct(0, 0)
    end

    return matrix2d_ct(
        scale.x, 0,
        0, scale.y,
        center.x - scale.x * center.x, center.y - scale.y * center.y
    )
end

function matrix2d.rotation(θ, center)
    center = center or vec2_ct(0, 0)

    local cosθ = cos(θ)
    local sinθ = sin(θ)
    local x = center.x
    local y = center.y
    local tx = x - cosθ*x - sinθ*y
    local ty = y - cosθ*y - sinθ*x

    return matrix2d_ct(
        cosθ, -sinθ,
        sinθ,  cosθ,
          tx,    ty
    )
end

function matrix2d.skew(θx, θy, center)
    center = center or vec2_ct(0, 0)

    local tanx = tan(θx)
    local tany = tan(θy)
    local x = center.x
    local y = center.y

    return matrix2d_ct(
        1, tanx,
        tany, 1,
        -y*tany, -x*tanx
    )
end

local function det(m)
    return m.m11 * m.m22 - m.m12 * m.m21
end
matrix2d.det = det

local function uninv_det(d)
    return abs(d) < 0.0000001
end

function matrix2d.is_invertible(m)
    return not uninv_det(det(m))
end

function matrix2d.inverse(m)
    local d = det(m)
    if uninv_det(d) then
        return nil
    end

    return matrix2d_ct(
        m.m22 /  d, m.m12 / -d,
        m.m21 / -d, m.m11 /  d,
        (m.m22*m.m31 - m.m21*m.m32) / -d,
        (m.m12*m.m31 - m.m11*m.m32) /  d
    )
end

function matrix2d.transform_point(m, point)
    return vec2_ct(
        point.x*m.m11 + point.y*m.m21 + m.m31,
        point.x*m.m12 + point.y*m.m22 + m.m32
    )
end

function matrix2d.transform_vector(m, vector)
    return vec2_ct(
        vector.x*m.m11 + vector.y*m.m21,
        vector.x*m.m12 + vector.y*m.m22
    )
end

function matrix2d_mt:__tostring()
    return string.format(
        "[%f, %f, 0]\n[%f, %f, 0]\n[%f, %f, 1]",
        self.m11, self.m12,
        self.m21, self.m22,
        self.m31, self.m32
    )
end

function matrix2d_mt.__mul(m1, m2)
    return matrix2d_ct(
        m1.m11 * m2.m11 + m1.m12 * m2.m21,          m1.m11 * m2.m12 + m1.m12 * m2.m22,
        m2.m11 * m1.m21 + m2.m21 * m1.m22,          m2.m12 * m1.m21 + m1.m22 * m2.m22,
        m2.m31 + m2.m11 * m1.m31 + m2.m21 * m1.m32, m2.m32 + m2.m12 * m1.m31 + m2.m22 * m1.m32
    )
end

matrix2d_ct = ffi.metatype("struct matrix2d", matrix2d_mt)
matrix2d.ctype = matrix2d_ct

return {
    matrix2d = matrix2d
}
