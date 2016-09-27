#pragma once

#include "renderer.h"
#include "sg_details.h"
#include "renderer_math.h"
#include <unordered_map>
#include <unordered_set>
#include <vector>

template <typename object, typename instance, template <typename I> typename instance_buffer>
class scene_graph
{
    template <typename K, typename V>
    using hashmap = std::unordered_map<K, V>;
    template <typename T>
    using hashset = std::unordered_set<T>;
    template <typename T>
    using vec = std::vector<T>;

public:
    using unordered_batch = hashmap<texture_array *, instance_buffer<instance>>;
    using ordered_batch = vec<std::pair<texture_array *, instance_buffer<instance>>>;

private:
    using coord = sg_details::coord;
    struct opaque_pool
    {
        hashmap<texture_array *, hashset<object *>> sprites;
        unordered_batch batches;
        bool active;
    };

    struct translucent_pool
    {
        vec<object *> sprites;
        ordered_batch batches;
        bool active;
    };

    struct grid_space
    {
        opaque_pool standard;
        opaque_pool statics;
        translucent_pool translucents;
        uint32_t frames_occluded;
        bool active;
    };

    struct grid_group
    {
        grid_space spaces[8][8];
    };

public:
    struct batch_state
    {
        const unordered_batch *standard;
        const unordered_batch *statics;
        const ordered_batch *translucents;
    };

    struct to_be_rendered_t
    {
        to_be_rendered_t(const scene_graph *graph) : graph(graph) {}
        auto begin() { return graph->to_be_rendered_items.begin(); }
        auto end() { return graph->to_be_rendered_items.end(); }
        const scene_graph *graph;
    };

    inline scene_graph(vec2 grid_size)
        : grid_size(grid_size)
    {
    }

    bool prepare_rendering(device *dev, camera *cam)
    {
        matrix2d cam_transform;
        rd_get_camera_transform(cam, &cam_transform);
        previously_rendered.clear();
        previously_rendered.swap(to_be_rendered_items);

        coord c0 = get_coord(transform_point(cam_transform, vec2{ -1, 1 }));
        coord c1 = get_coord(transform_point(cam_transform, vec2{ 1, 1 }));
        coord c2 = get_coord(transform_point(cam_transform, vec2{ -1, -1 }));
        coord c3 = get_coord(transform_point(cam_transform, vec2{ 1, -1 }));
        int32_t minx = std::min(std::min(c0.x, c1.x), std::min(c2.x, c3.x)) - 1;
        int32_t maxx = std::max(std::max(c0.x, c1.x), std::max(c2.x, c3.x)) + 1;
        int32_t miny = std::min(std::min(c0.y, c1.y), std::min(c2.y, c3.y)) - 1;
        int32_t maxy = std::max(std::max(c0.y, c1.y), std::max(c2.y, c3.y)) + 1;

        for (int32_t y = miny; y <= maxy; ++y)
        {
            for (int32_t x = minx; x <= maxx; ++x)
            {
                coord c{ x, y };
                if (grid_space *space = lookup(c))
                {
                    if (!prepare_space(dev, c, space))
                        return false;
                    to_be_rendered_items.insert(c);
                }
            }
        }

        for (const coord &c : previously_rendered)
        {
            if (to_be_rendered_items.find(c) == to_be_rendered_items.end())
            {
                if (grid_space *space = lookup(c))
                {
                    recently_occluded.insert(c);
                }
            }
        }

        return true;
    }

    bool prepare_space(device *dev, const coord &c, grid_space *space)
    {
        return false;
    }

    to_be_rendered_t to_be_rendered() const
    {
        return this;
    }

    bool get_batch_state(coord c, batch_state &batch)
    {
        if (grid_space *space = lookup(c))
        {
            if (space->active)
            {
                if (space->standard.active)
                    batch.standard = &space->standard.batches;
                if (space->statics.active)
                    batch.statics = &space->statics.batches;
                if (space->translucents.active)
                    batch.translucents = &space->translucents.batches;

                return batch.standard || batch.statics || batch.translucents;
            }
        }

        return false;
    }

    void process_occluded(uint32_t deactivate_threshold)
    {
        std::unordered_set<coord> kill;
        for (coord c : recently_occluded)
        {
            if (grid_space *space = lookup(c))
            {
                space->frames_occluded++;
                if (space->frames_occluded > deactivate_threshold)
                {
                    space->standard.batch.deactivate();
                    space->statics.batch.deactivate();
                    space->translucents.deactivate();

                    kill.insert(c);
                }
            }
            else
            {
                kill.insert(c);
            }
        }

        for (coord c : kill)
        {
            recently_occluded.erase(c);
        }
    }

private:
    inline coord get_coord(vec2 v)
    {
        int32_t grid_x = (int32_t)std::floor(pos.x / grid_size.x);
        int32_t grid_y = (int32_t)std::floor(pos.x / grid_size.x);

        return coord{ grid_x, grid_y };
    }

    inline grid_space *lookup(coord c)
    {
        int32_t xgroup = int32_t(std::floor(c.x / 8.f));
        int32_t groupx = c.x % 8;

        int32_t ygroup = int32_t(std::floor(c.y / 8.f));
        int32_t groupy = c.y % 8;

        coord groupcoord(xgroup, ygroup);
        auto iter = groups.find(groupcoord);
        if (iter == groups.end())
            return nullptr;

        return &iter->second.spaces[groupy][groupx];
    }

    inline grid_space *lookup(vec2 pos)
    {
        coord c = get_coord(pos);
        return lookup(c);
    }

    inline grid_space *lookup(const matrix2d &m)
    {
        return lookup(vec2{ m.m31, m.m32 });
    }

    vec2 grid_size;
    std::unordered_map<coord, grid_group> groups;
    std::unordered_set<coord> to_be_rendered_items;
    std::unordered_set<coord> previously_rendered;
    std::unordered_set<coord> recently_occluded;
};
