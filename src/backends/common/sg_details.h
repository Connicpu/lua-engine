#pragma once

#include <stdint.h>

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
}

namespace std
{
    template <>
    class hash<sg_details::coord>
    {
    public:
        typedef sg_details::coord argument_type;
        typedef std::size_t result_type;

        result_type operator()(const argument_type &key)
        {
            size_t result = 2166136261;
            const uint8_t *data = (const uint8_t *)&key;
            for (int i = 0; i < sizeof(argument_type); ++i)
                result = (result * 16777619) ^ data[i];
            return result;
        }
    };
}
