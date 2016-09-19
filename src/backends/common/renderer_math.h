#pragma once

#include "renderer.h"
#include <cmath>

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

}

#pragma endregion
