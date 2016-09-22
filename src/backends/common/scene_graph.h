#pragma once

#include "sg_details.h"
#include "renderer_math.h"
#include <unordered_map>

template <typename object, typename instance, template <typename I> typename instance_buffer>
class scene_graph
{
    using coord = sg_details::coord;
    struct grid_group;
    struct grid_space;
    struct opaque_pool;
    struct translucent_pool;
public:
    inline scene_graph(vec2 grid_size)
        : grid_size(grid_size)
    {
    }

private:

    struct grid_space
    {
        opaque_pool standard;
        opaque_pool statics;
        translucent_pool translucents;
    };

    struct grid_group
    {
        grid_space spaces[8][8];
    };

    inline grid_space *lookup(vec2 pos)
    {
        float grid_x = pos.x / grid_size.x;
        float grid_y = pos.x / grid_size.x;

        int32_t xgroup = int32_t(std::floor(grid_x / 8));
        int32_t groupx = int32_t(grid_x) % 8;

        int32_t ygroup = int32_t(std::floor(grid_y / 8));
        int32_t groupy = int32_t(grid_y) % 8;

        coord groupcoord(xgroup, ygroup);
        auto iter = groups.find(groupcoord);
        if (iter == groups.end())
            return nullptr;

        return &iter->second.spaces[groupy][groupx];
    }

    inline grid_space *lookup(const matrix2d &m)
    {
        return lookup(vec2{ m.m31, m.m32 });
    }

    vec2 grid_size;
    std::unordered_map<coord, grid_group> groups;
};
