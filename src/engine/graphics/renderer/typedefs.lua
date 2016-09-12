local ffi = require("ffi")

ffi.cdef[[
    // Math
    typedef struct vec2 vec2;
    typedef struct matrix2d matrix2d;

    // Error handling
    typedef struct renderer_error renderer_error;

    // Device
    typedef struct renderer_device renderer_device;
    typedef struct renderer_device_params renderer_device_params;

    // Scene
    typedef struct renderer_scene renderer_scene;
    typedef struct sprite_object *sprite_handle;
    typedef struct sprite_params sprite_params;
]]

return ffi
