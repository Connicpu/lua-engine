#pragma once

#include <stdint.h>
#include <unordered_map>

namespace sg_details
{
    struct coord
    {
        inline coord(int32_t x, int32_t y)
            : x(x), y(y)
        {
        }
        int32_t x, y;
    };

    inline bool operator==(const coord &lhs, const coord &rhs)
    {
        return lhs.x == rhs.x && lhs.y == rhs.y;
    }

    inline bool operator!=(const coord &lhs, const coord &rhs)
    {
        return !(lhs == rhs);
    }
}

namespace std
{
    template <>
    class hash<sg_details::coord>
    {
    public:
        typedef sg_details::coord argument_type;
        typedef std::size_t result_type;

        result_type operator()(const argument_type &key) const
        {
            size_t result = 2166136261;
            const uint8_t *data = (const uint8_t *)&key;
            for (int i = 0; i < sizeof(argument_type); ++i)
                result = (result * 16777619) ^ data[i];
            return result;
        }
    };
}
