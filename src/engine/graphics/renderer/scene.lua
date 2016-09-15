local ffi = require("engine.graphics.renderer.typedefs")

ffi.cdef[[
    struct sprite_params {
        bool translucent;
        bool static;
        color tint;
        matrix2d transform;
    };

    scene *rd_create_scene(rd_device *device);
    void rd_free_scene(scene *scene);

    sprite_handle rd_create_sprite(scene *scene, sprite_params *params);
    void rd_destroy_sprite(scene *scene, sprite_handle sprite);

    void rd_get_sprite_transform(scene *scene, sprite_handle sprite, matrix2d *transform);
    void rd_set_sprite_transform(scene *scene, sprite_handle sprite, const matrix2d *transform);

    void rd_get_sprite_tint(scene *scene, sprite_handle sprite, color *tint);
    void rd_set_sprite_tint(scene *scene, sprite_handle sprite, const color *tint);
]]
