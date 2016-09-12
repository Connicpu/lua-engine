local ffi = require("engine.graphics.renderer.typedefs")

ffi.cdef[[
    struct sprite_params {
        bool translucent;
        bool static;
        color tint;
        matrix2d transform;
    };

    renderer_scene *renderer_create_scene(renderer_device *device);
    void renderer_free_scene(renderer_scene *scene);

    sprite_handle renderer_create_sprite(renderer_scene *scene, sprite_params *params);
]]
