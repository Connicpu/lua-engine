#import "platform.h"
#import "backends/common/scene_graph.h"

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
        //inst.texture_id = tex->index;
        return inst;
    }
};


