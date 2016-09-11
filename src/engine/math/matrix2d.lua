local ffi = require("ffi")
local vec2 = require("engine.math.vec2").vec2

local istype = ffi.istype
local vec2_ct = vec2.ctype

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

function matrix2d.transform_point(m, point)
    local lmat = istype(m, matrix2d_ct)
    local rvec = istype(point, vec2_ct)
    if lmat and rvec then
        return vec2_ct(
            point.x*m.m11 + point.y*m.m21 + m.m31,
            point.x*m.m12 + point.y*m.m22 + m.m32
        )
    end
    error("Invalid types for matrix2d:transform_point")
end

function matrix2d_mt:__tostring()
    return "<TODO matrix2d>"
end

function matrix2d_mt.__mul(lhs, rhs)
    local lmat = istype(lhs, matrix2d_ct)
    local rmat = istype(rhs, matrix2d_ct)

    if lmat and rmat then
        return matrix2d_ct(
            m1.m11 * m2.m11 + m1.m12 * m2.m21,          m1.m11 * m2.m12 + m1.m12 * m2.m22,
            m2.m11 * m1.m21 + m2.m21 * m1.m22,          m2.m12 * m1.m21 + m1.m22 * m2.m22,
            m2.m31 + m2.m11 * m1.m31 + m2.m21 * m1.m32, m2.m32 + m2.m12 * m1.m31 + m2.m22 * m1.m32
        )
    end
    error("Invalid types for matrix2d:__mul")
end

matrix2d_ct = ffi.metatype("struct matrix2d", matrix2d_mt)
matrix2d.ctype = matrix2d_ct

return {
    matrix2d = matrix2d
}
