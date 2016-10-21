#pragma once

#include "renderer.h"
#include "sg_details.h"
#include "renderer_math.h"
#include "object_pool.h"
#include <unordered_map>
#include <unordered_set>
#include <vector>

enum class sprite_class
{
    standard,
    statics,
    translucents,
};

template <typename object, typename instance, template <class I> class instance_buffer, typename errors>
class scene_graph
{
    template <typename K, typename V>
    using hashmap = std::unordered_map<K, V>;
    template <typename T>
    using hashset = std::unordered_set<T>;
    template <typename T>
    using vec = std::vector<T>;

public:
    using coord = sg_details::coord;
    using handle = object*;
    using unordered_batch = hashmap<texture_array *, instance_buffer<instance>>;
    using ordered_batch = vec<std::pair<texture_array *, instance_buffer<instance>>>;
    
    scene_graph(const scene_graph &) = delete;
    scene_graph &operator=(const scene_graph &) = delete;

private:
    struct opaque_group
    {
        hashset<handle> sprites;
        bool dirty = true;
    };
    struct opaque_pool
    {
        hashmap<texture_array *, opaque_group> sprites;
        unordered_batch batches;
        bool active = false;
    };
    struct translucent_pool
    {
        vec<handle> sprites;
        ordered_batch batches;
        bool dirty = true;
        bool active = false;

        void sort()
        {
            std::sort(sprites.begin(), sprites.end(), [](handle l, handle r) -> bool
            {
                return l->layer < r->layer;
            });
            dirty = true;
        }
    };
    struct grid_space
    {
        opaque_pool standard;
        opaque_pool statics;
        translucent_pool translucents;
        uint32_t frames_occluded;
        bool active = false;
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
    
    inline scene_graph()
        : scene_graph(vec2{1.f, 1.f})
    {
    }

    inline scene_graph(vec2 grid_size)
        : grid_size(grid_size)
    {
    }
    
    inline void init(vec2 grid_size)
    {
        assert(groups.empty());
        this->grid_size = grid_size;
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
                    if (!prepare_space(dev, space))
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
    to_be_rendered_t to_be_rendered() const
    {
        return this;
    }
    bool get_batch_state(coord c, batch_state &batch)
    {
        batch = { 0 };
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
    void collect_garbage(uint32_t deactivate_threshold)
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
        kill.clear();

        for (coord c : recently_emptied)
        {
            auto group = group_coord(c);
            if (kill.find(group.first) != kill.end())
                continue;

            auto grid_group = groups.find(group.first);
            if (grid_group == groups.end())
                continue;

            for (auto &row : grid_group->second.spaces)
            {
                for (auto &space : row)
                {
                    if (!(space.standard.sprites.empty() &&
                          space.statics.sprites.empty() &&
                          space.translucents.sprites.empty()))
                    {
                        goto next;
                    }
                }
            }

            groups.erase(grid_group);

        next:
            kill.insert(group.first);
        }
        recently_emptied.clear();
    }

    handle create_object(const sprite_params *params)
    {
        pool_allocation alloc = objects.alloc();
        handle obj = new (alloc.memory) object(alloc, params);
        place_object(obj);
        return obj;
    }
    void destroy_object(handle h)
    {
        remove_object(h);
        objects.free(h->alloc);
    }
    void move_object(handle obj, const matrix2d &new_transform)
    {
        coord old_c = get_coord(position_of(obj));
        coord new_c = get_coord(position_of(new_transform));

        if (old_c == new_c)
        {
            obj->transform = new_transform;
            updated_field(obj);
        }
        else
        {
            remove_object(obj);
            obj->transform = new_transform;
            place_object(obj);
        }
    }
    void change_texture(handle obj, texture *tex)
    {
        if (obj->type != sprite_class::translucents)
        {
            remove_object(obj);
            obj->tex = tex;
            place_object(obj);
        }
        else
        {
            updated_field(obj);
        }
    }
    void updated_layer(handle obj)
    {
        if (obj->type == sprite_class::translucents)
        {
            grid_space *space = lookup(obj);
            space->translucents.sort();
        }
        else
        {
            updated_field(obj);
        }
    }
    void updated_field(handle obj)
    {
        auto &space = *lookup(obj);
        auto *tary = obj->tex->array;
        switch (obj->type)
        {
            case sprite_class::standard:
                space.standard.sprites[tary].dirty = true;
                break;
            case sprite_class::statics:
                space.statics.sprites[tary].dirty = true;
                break;
            case sprite_class::translucents:
                space.translucents.dirty = true;
                break;
        }
    }

private:
    void place_object(handle obj)
    {
        vec2 pos = position_of(obj);
        coord c = get_coord(pos);
        grid_space &space = *ensure_space(c);
        texture_array *tary = obj->tex->array;
        switch (obj->type)
        {
            case sprite_class::standard:
            {
                auto &group = space.standard.sprites[tary];
                group.sprites.insert(obj);
                group.dirty = true;
                space.standard.active = true;
                space.active = true;
                break;
            }

            case sprite_class::statics:
            {
                auto &group = space.statics.sprites[tary];
                group.sprites.insert(obj);
                group.dirty = true;
                space.statics.active = true;
                space.active = true;
                break;
            }

            case sprite_class::translucents:
            {
                space.translucents.sprites.push_back(obj);
                space.translucents.sort();
                space.translucents.active = true;
                space.active = true;
                break;
            }
        }
    }
    void remove_object(handle obj)
    {
        vec2 pos = position_of(obj);
        coord c = get_coord(pos);
        grid_space &space = *ensure_space(c);
        texture_array *tary = obj->tex->array;
        bool mark_removal = false;
        switch (obj->type)
        {
            case sprite_class::standard:
            {
                auto &group = space.standard.sprites[tary];
                group.sprites.erase(obj);
                group.dirty = true;

                if (group.sprites.empty())
                {
                    space.standard.sprites.erase(tary);
                    space.standard.batches.erase(tary);
                    if (space.standard.sprites.empty())
                    {
                        space.standard.active = false;
                        mark_removal = true;
                    }
                }
                break;
            }

            case sprite_class::statics:
            {
                auto &group = space.statics.sprites[tary];
                group.sprites.erase(obj);
                group.dirty = true;
                space.statics.active = true;

                if (group.sprites.empty())
                {
                    space.statics.sprites.erase(tary);
                    space.statics.batches.erase(tary);
                    if (space.statics.sprites.empty())
                    {
                        space.statics.active = false;
                        mark_removal = true;
                    }
                }
                break;
            }

            case sprite_class::translucents:
            {
                auto &sprites = space.translucents.sprites;
                sprites.erase(std::find(sprites.begin(), sprites.end(), obj));
                space.translucents.dirty = true;
                if (sprites.empty())
                {
                    space.translucents.batches.clear();
                    space.translucents.active = false;
                    mark_removal = true;
                }
                break;
            }
        }

        if (mark_removal)
        {
            if (space.standard.sprites.empty() &&
                space.statics.sprites.empty() &&
                space.translucents.sprites.empty())
            {
                space.active = false;
                recently_emptied.insert(c);
            }
        }
    }

    bool prepare_space(device *dev, grid_space *space)
    {
        return
            prepare_opaque(dev, space->standard) &&
            prepare_opaque(dev, space->statics) &&
            prepare_translucent(dev, space->translucents);
    }
    bool prepare_opaque(device *dev, opaque_pool &pool)
    {
        for (auto &pair : pool.sprites)
        {
            if (pair.second.dirty)
            {
                auto &sprites = pair.second.sprites;
                assert(!sprites.empty());

                auto &batch = pool.batches[pair.first];
                if (!batch.start_upload(dev, (uint32_t)sprites.size()))
                    return errors::append_ret(false, "Failed to begin upload of sprite batch");

                for (handle sprite : sprites)
                {
                    batch.push(static_cast<instance>(*sprite));
                }

                if (!batch.finish(dev))
                    return errors::append_ret(false, "Failed to finish upload of sprite batch");

                pair.second.dirty = false;
            }
        }

        return true;
    }
    bool prepare_translucent(device *dev, translucent_pool &pool)
    {
        if (!pool.dirty)
            return true;

        vec<uint32_t> runs;
        runs.reserve(pool.batches.size());

        uint32_t run_len = 0;
        texture_array *run_tex = nullptr;
        for (auto *sprite : pool.sprites)
        {
            texture_array *ary = sprite->tex->array;
            if (ary != run_tex)
            {
                if (run_len > 0)
                    runs.push_back(run_len);
                run_len = 0;
                run_tex = ary;
            }

            run_len++;
        }

        uint32_t batch_i = 0;
        ordered_batch old_batches;
        old_batches.reserve(pool.batches.size());
        old_batches.swap(pool.batches);

        uint32_t sprite_i = 0;
        for (uint32_t run : runs)
        {
            std::pair<texture_array *, instance_buffer<instance>> current_inst;
            if (batch_i < old_batches.size())
            {
                current_inst = std::move(old_batches[batch_i++]);
            }
            
            current_inst.first = pool.sprites[sprite_i]->tex->array;

            if (!current_inst.second.start_upload(dev, run))
                return errors::append_ret(false, "Failed to begin upload of sprite batch");

            for (uint32_t j = 0; j < run; ++j)
            {
                current_inst.second.push(static_cast<instance>(*pool.sprites[sprite_i + j]));
            }

            if (!current_inst.second.finish(dev))
                return errors::append_ret(false, "Failed to finish upload of sprite batch");

            pool.batches.push_back(std::move(current_inst));
            sprite_i += run;
        }

        return true;
    }

    inline vec2 position_of(const matrix2d &mat)
    {
        return transform_point(mat, vec2{ 0, 0 });
    }
    inline vec2 position_of(handle obj)
    {
        return position_of(obj->transform);
    }
    inline coord get_coord(vec2 v)
    {
        int32_t grid_x = (int32_t)std::floor(v.x / grid_size.x);
        int32_t grid_y = (int32_t)std::floor(v.y / grid_size.y);

        return coord{ grid_x, grid_y };
    }
    inline std::pair<coord, coord> group_coord(coord c)
    {
        int32_t xgroup = int32_t(std::floor(c.x / 8.f));
        int32_t groupx = c.x % 8;

        int32_t ygroup = int32_t(std::floor(c.y / 8.f));
        int32_t groupy = c.y % 8;

        return std::make_pair(coord{ xgroup, ygroup }, coord{ groupx, groupy });
    }

    inline grid_space *lookup(handle h)
    {
        return lookup(get_coord(position_of(h)));
    }
    inline grid_space *lookup(coord c)
    {
        auto group = group_coord(c);

        auto iter = groups.find(group.first);
        if (iter == groups.end())
            return nullptr;

        return &iter->second.spaces[group.second.y][group.second.x];
    }
    inline grid_space *ensure_space(coord c)
    {
        auto group = group_coord(c);
        return &groups[group.first].spaces[group.second.y][group.second.x];
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
    hashmap<coord, grid_group> groups;
    hashset<coord> to_be_rendered_items;
    hashset<coord> previously_rendered;
    hashset<coord> recently_occluded;
    hashset<coord> recently_emptied;

    object_pool_t<object> objects;
};
