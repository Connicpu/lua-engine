local ffi = require("engine.graphics.renderer.typedefs")

ffi.rd_header.cdef[[
    struct sprite_params {
        bool is_translucent;
        bool is_static;
        float layer;
        texture *tex;
        vec2 uv_topleft;
        vec2 uv_bottomright;
        matrix2d transform;
        color tint;
    };

    scene *rd_create_scene(device *dev, float grid_width, float grid_height);
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
]]

return ffi
