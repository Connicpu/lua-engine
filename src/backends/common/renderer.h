        #pragma once
        #ifdef __cplusplus
        #include <stdint.h>
        extern "C" {
        #endif

        struct vec2 {
            float x;
            float y;
        };
        struct matrix2d {
            float m11, m12;
            float m21, m22;
            float m31, m32;
        };
        struct color {
            float r, g, b, a;
        };
    
    // Mathlib structs
    typedef struct vec2 vec2;
    typedef struct matrix2d matrix2d;
    typedef struct color color;

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


    camera *rd_create_camera();
    void rd_free_camera(camera *cam);

    void rd_set_camera_aspect(camera *cam, float aspect_ratio);
    bool rd_update_camera(camera *cam, const matrix2d *transform);


    struct device_params {
        instance *inst;
        output_id preferred_output;
        bool enable_debug_mode;
    };

    device *rd_create_device(const device_params *params);
    void rd_free_device(device *dev);


    struct renderer_error {
        int system_code;
        char message[1024];
    };

    // NOTE: The state is thread-local
    bool rd_last_error(renderer_error *error);
    void rd_clear_error();


    bool rd_poll_window_event(window *window, window_event *event);
    void rd_free_window_event(window_event *event);

    enum event_type {
        EVENT_CLOSED,

        EVENT_WINDOW_RESIZED,
        EVENT_WINDOW_MOVED,
        EVENT_WINDOW_FOCUS,
        EVENT_DROPPED_FILE,

        EVENT_KEYBOARD_CHARACTER,
        EVENT_KEYBOARD_INPUT,

        EVENT_MOUSE_MOVED,
        EVENT_MOUSE_INPUT,
        EVENT_MOUSE_WHEEL,

        EVENT_DPI_CHANGED,
    };

    enum mouse_button {
        Mb_Left,
        Mb_Right,
        Mb_Middle,
        Mb_X1,
        Mb_X2,
    };

    enum element_state {
        ELEM_PRESSED,
        ELEM_RELEASED,
    };

    enum virtual_key_code
    {
        Vk_Key0,
        Vk_Key1,
        Vk_Key2,
        Vk_Key3,
        Vk_Key4,
        Vk_Key5,
        Vk_Key6,
        Vk_Key7,
        Vk_Key8,
        Vk_Key9,

        Vk_A,
        Vk_B,
        Vk_C,
        Vk_D,
        Vk_E,
        Vk_F,
        Vk_G,
        Vk_H,
        Vk_I,
        Vk_J,
        Vk_K,
        Vk_L,
        Vk_M,
        Vk_N,
        Vk_O,
        Vk_P,
        Vk_Q,
        Vk_R,
        Vk_S,
        Vk_T,
        Vk_U,
        Vk_V,
        Vk_W,
        Vk_X,
        Vk_Y,
        Vk_Z,

        Vk_Escape,

        Vk_F1,
        Vk_F2,
        Vk_F3,
        Vk_F4,
        Vk_F5,
        Vk_F6,
        Vk_F7,
        Vk_F8,
        Vk_F9,
        Vk_F10,
        Vk_F11,
        Vk_F12,
        Vk_F13,
        Vk_F14,
        Vk_F15,

        Vk_Snapshot,
        Vk_Scroll,
        Vk_Pause,

        Vk_Insert,
        Vk_Home,
        Vk_Delete,
        Vk_End,
        Vk_PageDown,
        Vk_PageUp,

        Vk_Left,
        Vk_Up,
        Vk_Right,
        Vk_Down,

        Vk_Back,
        Vk_Return,
        Vk_Space,

        Vk_Numlock,
        Vk_Numpad0,
        Vk_Numpad1,
        Vk_Numpad2,
        Vk_Numpad3,
        Vk_Numpad4,
        Vk_Numpad5,
        Vk_Numpad6,
        Vk_Numpad7,
        Vk_Numpad8,
        Vk_Numpad9,

        Vk_AbntC1,
        Vk_AbntC2,
        Vk_Add,
        Vk_Apostrophe,
        Vk_Apps,
        Vk_At,
        Vk_Ax,
        Vk_Backslash,
        Vk_Calculator,
        Vk_Capital,
        Vk_Colon,
        Vk_Comma,
        Vk_Convert,
        Vk_Decimal,
        Vk_Divide,
        Vk_Equals,
        Vk_Grave,
        Vk_Kana,
        Vk_Kanji,
        Vk_LAlt,
        Vk_LBracket,
        Vk_LControl,
        Vk_LMenu,
        Vk_LShift,
        Vk_LWin,
        Vk_Mail,
        Vk_MediaSelect,
        Vk_MediaStop,
        Vk_Minus,
        Vk_Multiply,
        Vk_Mute,
        Vk_MyComputer,
        Vk_NavigateForward,
        Vk_NavigateBackward,
        Vk_NextTrack,
        Vk_NoConvert,
        Vk_NumpadComma,
        Vk_NumpadEnter,
        Vk_NumpadEquals,
        Vk_OEM102,
        Vk_Period,
        Vk_PlayPause,
        Vk_Power,
        Vk_PrevTrack,
        Vk_RAlt,
        Vk_RBracket,
        Vk_RControl,
        Vk_RMenu,
        Vk_RShift,
        Vk_RWin,
        Vk_Semicolon,
        Vk_Slash,
        Vk_Sleep,
        Vk_Stop,
        Vk_Subtract,
        Vk_Sysrq,
        Vk_Tab,
        Vk_Underline,
        Vk_Unlabeled,
        Vk_VolumeDown,
        Vk_VolumeUp,
        Vk_Wake,
        Vk_WebBack,
        Vk_WebFavorites,
        Vk_WebForward,
        Vk_WebHome,
        Vk_WebRefresh,
        Vk_WebSearch,
        Vk_WebStop,
        Vk_Yen,
    };

    struct window_event {
        event_type event;
        union {
            struct {
                uint32_t width, height;
            } window_resized;

            struct {
                int32_t x, y;
                uint32_t width, height;
            } window_moved;

            struct {
                bool state;
            } window_focus;

            struct {
                int32_t x, y;

                size_t path_len;
                char *path;
            } dropped_file;

            struct {
                uint32_t codepoint;
            } char_input;

            struct {
                element_state state;
                virtual_key_code virtual_key;
                bool has_vk;
                uint8_t scan_code;
            } key_input;
            
            struct {
                int32_t x, y;
            } mouse_moved;

            struct {
                mouse_button button;
                element_state state;
                int32_t x, y;
            } mouse_input;

            struct {
                float dx, dy;
            } mouse_wheel;

            struct {
                float dpi;
            } dpi_changed;
        };
    };


    instance *rd_create_instance();
    void rd_free_instance(instance *inst);


    framebuffer *rd_create_framebuffer(device *dev, uint32_t width, uint32_t height);
    void rd_free_framebuffer(framebuffer *fb);

    render_target *rd_get_framebuffer_target(framebuffer *fb);
    texture *rd_get_framebuffer_texture(framebuffer *fb);
    void rd_clear_render_target(device *dev, render_target *rt, const color *clear);
    void rd_clear_depth_buffer(device *dev, render_target *rt);


    struct texture_array_params {
        bool streaming;
        uint32_t sprite_count;
        uint32_t sprite_width;
        uint32_t sprite_height;
        const uint8_t *const *buffers;
        bool pixel_art;
    };

    texture_array *rd_create_texture_array(device *dev, const texture_array_params *params);
    void rd_free_texture_array(texture_array *set);

    void rd_get_texture_array_size(const texture_array *set, uint32_t *width, uint32_t *height);
    uint32_t rd_get_texture_array_count(const texture_array *set);
    bool rd_is_texture_array_streaming(const texture_array *set);
    bool rd_is_texture_array_pixel_art(const texture_array *set);
    bool rd_set_texture_array_pixel_art(texture_array *set, bool pa);

    texture *rd_get_texture(texture_array *set, uint32_t index);
    texture_array *rd_get_texture_array(texture *texture);
    void rd_update_texture(const uint8_t *data, size_t len);


    struct sprite_params {
        bool is_translucent;
        bool is_static;
        float layer;
        texture *tex;
        vec2 uv_topleft;
        vec2 uv_topright;
        matrix2d transform;
        color tint;
    };

    scene *rd_create_scene(device *dev, float grid_width, float grid_height);
    void rd_free_scene(scene *scene);

    void rd_draw_scene(device *dev, scene *scene, camera *cam);

    sprite_handle rd_create_sprite(scene *scene, sprite_params *params);
    void rd_destroy_sprite(scene *scene, sprite_handle sprite);

    void rd_get_sprite_uv(scene *scene, sprite_handle sprite, vec2 *topleft, vec2 *topright);
    void rd_set_sprite_uv(scene *scene, sprite_handle sprite, const vec2 *topleft, const vec2 *topright);

    float rd_get_sprite_layer(scene *scene, sprite_handle sprite);
    void rd_set_sprite_layer(scene *scene, sprite_handle sprite, float layer);

    texture *rd_get_sprite_texture(scene *scene, sprite_handle sprite);
    void rd_set_sprite_texture(scene *scene, sprite_handle sprite, texture *tex);

    void rd_get_sprite_transform(scene *scene, sprite_handle sprite, matrix2d *transform);
    void rd_set_sprite_transform(scene *scene, sprite_handle sprite, const matrix2d *transform);

    void rd_get_sprite_tint(scene *scene, sprite_handle sprite, color *tint);
    void rd_set_sprite_tint(scene *scene, sprite_handle sprite, const color *tint);


    


    struct adapter_output {
        // An index that can be used for looking up this adapter later,
        // but only within this process on this specific instance.
        uint32_t process_index;

        output_id id;
        uint64_t device_memory;
        uint64_t system_memory;
        char device_name[64];
    };

    enum window_state {
        windowed = 0,
        borderless = 1,
        fullscreen = 2,
    };

    struct window_params {
        window_state state;
        int windowed_width;
        int windowed_height;
        const char *title;
    };

    // Call this function with (inst, 0, nil) and it will return the
    // number of outputs available. Otherwise it will fill `outputs`
    // up to the number of outputs or len, and return the number
    // written.
    size_t rd_get_outputs(instance *inst, size_t len, adapter_output *outputs);

    window *rd_create_window(device *dev, const window_params *params);
    void rd_free_window(window *win);

    bool rd_set_window_state(window *win, window_state state);
    render_target *rd_get_window_target(window *win);
    void rd_get_window_dpi(window *win, float *dpix, float *dpiy);
    bool rd_prepare_window_for_drawing(device * dev, window *win);

        #ifdef __cplusplus
        }
        #endif
    