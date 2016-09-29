#pragma once

#include "platform.h"
#include "InstanceBuffer.h"
#include "Texture.h"

struct sprite_vertex
{
    vec2 pos;
    vec2 tex;
};

struct sprite_instance
{
    matrix2d transform;
    color tint;
    vec2 uv0, uv1;
    float layer;
    uint32_t texture_id;
};

struct sprite_object
{
    sprite_object(const pool_allocation &alloc, const sprite_params *params)
        : alloc(alloc)
    {
        if (params->is_translucent)
            type = sprite_class::translucents;
        else if (params->is_static)
            type = sprite_class::statics;
        else
            type = sprite_class::standard;

        transform = params->transform;
        tint = params->tint;
        uv0 = params->uv_topleft;
        uv1 = params->uv_bottomright;
        layer = params->layer;
        tex = params->tex;
    }

    matrix2d transform;
    color tint;
    vec2 uv0, uv1;
    float layer;
    texture *tex;

    pool_allocation alloc;
    sprite_class type;

    inline explicit operator sprite_instance()
    {
        sprite_instance inst;
        inst.transform = transform;
        inst.tint = tint;
        inst.uv0 = uv0;
        inst.uv1 = uv1;
        inst.layer = layer;
        inst.texture_id = tex->index;
        return inst;
    }
};

struct error_interface
{
    template <typename T>
    static T append_ret(T ret, const char *msg)
    {
        return append_error_and_ret(ret, msg);
    }
};

struct scene
{
    scene(vec2 grid)
        : graph(grid)
    {
    }

    scene_graph<sprite_object, sprite_instance, InstanceBuffer, error_interface> graph;
};

scene *rd_create_scene(device *device, float grid_width, float grid_height);
void rd_free_scene(scene *scene);

bool rd_draw_scene(device *dev, render_target *rt, scene *scene, camera *cam, const viewport *vp);

sprite_handle rd_create_sprite(scene *scene, const sprite_params *params);
void rd_destroy_sprite(scene *scene, sprite_handle sprite);

void rd_get_sprite_uv(scene *scene, sprite_handle sprite, vec2 *topleft, vec2 *bottomright);
void rd_set_sprite_uv(scene *scene, sprite_handle sprite, const vec2 *topleft, const vec2 *bottomright);

float rd_get_sprite_layer(scene *scene, sprite_handle sprite);
void rd_set_sprite_layer(scene *scene, sprite_handle sprite, float layer);

texture *rd_get_sprite_texture(scene *scene, sprite_handle sprite);
void rd_set_sprite_texture(scene *scene, sprite_handle sprite, texture *tex);

void rd_get_sprite_transform(scene *scene, sprite_handle sprite, matrix2d *transform);
void rd_set_sprite_transform(scene *scene, sprite_handle sprite, const matrix2d *transform);

void rd_get_sprite_tint(scene *scene, sprite_handle sprite, color *tint);
void rd_set_sprite_tint(scene *scene, sprite_handle sprite, const color *tint);
