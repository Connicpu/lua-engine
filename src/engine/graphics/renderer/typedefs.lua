local ffi = require("engine.graphics.util.header_builder")

ffi.rd_header.cdef[[
    // Mathlib structs
    typedef struct vec2 vec2;
    typedef struct matrix2d matrix2d;
    typedef struct color color;
    typedef struct viewport viewport;

    // Error handling
    typedef struct renderer_error renderer_error;

    // Instance
    typedef struct instance instance;

    // Device
    typedef struct device device;
    typedef struct device_params device_params;

    // Render Target
    typedef struct render_target render_target;
    typedef struct framebuffer framebuffer;

    // Window
    typedef struct window window;
    typedef struct window_params window_params;
    typedef enum window_state window_state;
    typedef struct adapter_output adapter_output;
    typedef uint64_t output_id;

    // Window events
    typedef struct window_event window_event;
    typedef enum event_type event_type;
    typedef enum mouse_button mouse_button;
    typedef enum element_state element_state;
    typedef enum virtual_key_code virtual_key_code;

    // Texture
    typedef struct texture_array_params texture_array_params;
    typedef struct texture_array texture_array;
    typedef struct texture texture;

    // Scene
    typedef struct scene scene;
    typedef struct sprite_object *sprite_handle;
    typedef struct sprite_params sprite_params;

    // Camera
    typedef struct camera camera;

    // Text
    typedef struct text_object *text_handle;
    typedef struct text_params text_params;
]]

return ffi
