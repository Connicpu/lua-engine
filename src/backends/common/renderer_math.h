#pragma once

#include "renderer.h"
#include <cmath>
#include <cassert>

#pragma region vec2

inline float dot(vec2 lhs, vec2 rhs)
{
    return lhs.x * rhs.x + lhs.y * rhs.y;
}

inline float len2(vec2 self)
{
    return dot(self, self);
}

inline float len(vec2 self)
{
    return std::sqrt(len2(self));
}

inline vec2 operator+(vec2 lhs, vec2 rhs)
{
    return vec2{ lhs.x + rhs.x, lhs.y + rhs.y };
}

inline vec2 operator-(vec2 lhs, vec2 rhs)
{
    return vec2{ lhs.x - rhs.x, lhs.y - rhs.y };
}

inline vec2 operator*(vec2 lhs, vec2 rhs)
{
    return vec2{ lhs.x * rhs.x, lhs.y * rhs.y };
}

inline vec2 operator*(vec2 lhs, float rhs)
{
    return vec2{ lhs.x * rhs, lhs.y * rhs };
}

inline vec2 operator*(float lhs, vec2 rhs)
{
    return vec2{ lhs * rhs.x, lhs * rhs.y };
}

inline vec2 operator/(vec2 lhs, vec2 rhs)
{
    return vec2{ lhs.x / rhs.x, lhs.y / rhs.y };
}

inline vec2 operator/(vec2 lhs, float rhs)
{
    return vec2{ lhs.x / rhs, lhs.y / rhs };
}

inline vec2 operator/(float lhs, vec2 rhs)
{
    return vec2{ lhs / rhs.x, lhs / rhs.y };
}

inline vec2 operator^(vec2 self, float power)
{
    return vec2{ std::pow(self.x, power), std::pow(self.y, power) };
}

inline vec2 operator-(vec2 self)
{
    return vec2{ -self.x, -self.y };
}

#pragma endregion

#pragma region matrix2d

inline matrix2d identity()
{
    return matrix2d
    {
        1.f, 0.f,
        0.f, 1.f,
        0.f, 0.f
    };
}

inline matrix2d translation(float x, float y)
{
    return matrix2d
    {
        1.f, 0.f,
        0.f, 1.f,
          x,   y,
    };
}

inline matrix2d translation(vec2 v)
{
    return translation(v.x, v.y);
}

inline matrix2d scale(vec2 scale, vec2 center = vec2{ 0, 0 })
{
    return matrix2d
    {
        scale.x, 0,
        0, scale.y,
        center.x - scale.x * center.x, center.y - scale.y * center.y,
    };
}

inline matrix2d rotation(float θ, vec2 center = vec2{ 0, 0 })
{
    auto cosθ = std::cos(θ);
    auto sinθ = std::sin(θ);
    auto x = center.x;
    auto y = center.y;
    auto tx = x - cosθ*x - sinθ*y;
    auto ty = y - cosθ*y - sinθ*x;

    return matrix2d
    {
        cosθ, -sinθ,
        sinθ, cosθ,
        tx, ty
    };
}

inline matrix2d skew(float θx, float θy, vec2 center = vec2{ 0, 0 })
{
    auto tanx = tan(θx);
    auto tany = tan(θy);
    auto x = center.x;
    auto y = center.y;

    return matrix2d
    {
        1, tanx,
        tany, 1,
        -y*tany, -x*tanx
    };
}

inline float det(const matrix2d &m)
{
    return m.m11 * m.m22 - m.m12 * m.m21;
}

namespace details
{
    inline bool uninv_det(float d)
    {
        return std::abs(d) < 0.0000001f;
    }
}

inline bool is_invertible(const matrix2d &m)
{
    return !details::uninv_det(det(m));
}

inline matrix2d inverse(const matrix2d &m)
{
    float d = det(m);
    assert(!details::uninv_det(d));

    return matrix2d
    {
        m.m22 /  d, m.m12 / -d,
        m.m21 / -d, m.m11 /  d,
        (m.m22*m.m31 - m.m21*m.m32) / -d,
        (m.m12*m.m31 - m.m11*m.m32) /  d,
    };
}

inline vec2 transform_point(const matrix2d &m, vec2 point)
{
    return vec2
    {
        point.x*m.m11 + point.y*m.m21 + m.m31,
        point.x*m.m12 + point.y*m.m22 + m.m32,
    };
}

inline vec2 transform_vector(const matrix2d &m, vec2 vector)
{
    return vec2
    {
        vector.x*m.m11 + vector.y*m.m21,
        vector.x*m.m12 + vector.y*m.m22,
    };
}

inline matrix2d operator*(const matrix2d &m1, const matrix2d &m2)
{
    return matrix2d
    {
        m1.m11 * m2.m11 + m1.m12 * m2.m21,          m1.m11 * m2.m12 + m1.m12 * m2.m22,
        m2.m11 * m1.m21 + m2.m21 * m1.m22,          m2.m12 * m1.m21 + m1.m22 * m2.m22,
        m2.m31 + m2.m11 * m1.m31 + m2.m21 * m1.m32, m2.m32 + m2.m12 * m1.m31 + m2.m22 * m1.m32,
    };
}

#pragma endregion
