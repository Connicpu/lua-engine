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

    // Scene
    typedef struct scene scene;
    typedef struct sprite_object *sprite_handle;
    typedef struct sprite_params sprite_params;

    // Text
    typedef struct text_object *text_handle;
    typedef struct text_params text_params;


    struct device_params {
        instance *inst;
        output_id preferred_output;
        bool enable_debug_mode;
    };

    device *rd_create_device(const device_params *params);
    void rd_free_device(device *dev);


    struct renderer_error {
        int system_code;
        char message[128];
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
    };

    enum mouse_button {
        MB_LEFT,
        MB_RIGHT,
        MB_MIDDLE,
        MB_X1,
        MB_X2,
    };

    enum element_state {
        ELEM_PRESSED,
        ELEM_RELEASED,
    };

    enum virtual_key_code
    {
        VK_Key0,
        VK_Key1,
        VK_Key2,
        VK_Key3,
        VK_Key4,
        VK_Key5,
        VK_Key6,
        VK_Key7,
        VK_Key8,
        VK_Key9,

        VK_A,
        VK_B,
        VK_C,
        VK_D,
        VK_E,
        VK_F,
        VK_G,
        VK_H,
        VK_I,
        VK_J,
        VK_K,
        VK_L,
        VK_M,
        VK_N,
        VK_O,
        VK_P,
        VK_Q,
        VK_R,
        VK_S,
        VK_T,
        VK_U,
        VK_V,
        VK_W,
        VK_X,
        VK_Y,
        VK_Z,

        VK_Escape,

        VK_F1,
        VK_F2,
        VK_F3,
        VK_F4,
        VK_F5,
        VK_F6,
        VK_F7,
        VK_F8,
        VK_F9,
        VK_F10,
        VK_F11,
        VK_F12,
        VK_F13,
        VK_F14,
        VK_F15,

        VK_Snapshot,
        VK_Scroll,
        VK_Pause,

        VK_Insert,
        VK_Home,
        VK_Delete,
        VK_End,
        VK_PageDown,
        VK_PageUp,

        VK_Left,
        VK_Up,
        VK_Right,
        VK_Down,

        VK_Back,
        VK_Return,
        VK_Space,

        VK_Numlock,
        VK_Numpad0,
        VK_Numpad1,
        VK_Numpad2,
        VK_Numpad3,
        VK_Numpad4,
        VK_Numpad5,
        VK_Numpad6,
        VK_Numpad7,
        VK_Numpad8,
        VK_Numpad9,

        VK_AbntC1,
        VK_AbntC2,
        VK_Add,
        VK_Apostrophe,
        VK_Apps,
        VK_At,
        VK_Ax,
        VK_Backslash,
        VK_Calculator,
        VK_Capital,
        VK_Colon,
        VK_Comma,
        VK_Convert,
        VK_Decimal,
        VK_Divide,
        VK_Equals,
        VK_Grave,
        VK_Kana,
        VK_Kanji,
        VK_LAlt,
        VK_LBracket,
        VK_LControl,
        VK_LMenu,
        VK_LShift,
        VK_LWin,
        VK_Mail,
        VK_MediaSelect,
        VK_MediaStop,
        VK_Minus,
        VK_Multiply,
        VK_Mute,
        VK_MyComputer,
        VK_NavigateForward,
        VK_NavigateBackward,
        VK_NextTrack,
        VK_NoConvert,
        VK_NumpadComma,
        VK_NumpadEnter,
        VK_NumpadEquals,
        VK_OEM102,
        VK_Period,
        VK_PlayPause,
        VK_Power,
        VK_PrevTrack,
        VK_RAlt,
        VK_RBracket,
        VK_RControl,
        VK_RMenu,
        VK_RShift,
        VK_RWin,
        VK_Semicolon,
        VK_Slash,
        VK_Sleep,
        VK_Stop,
        VK_Subtract,
        VK_Sysrq,
        VK_Tab,
        VK_Underline,
        VK_Unlabeled,
        VK_VolumeDown,
        VK_VolumeUp,
        VK_Wake,
        VK_WebBack,
        VK_WebFavorites,
        VK_WebForward,
        VK_WebHome,
        VK_WebRefresh,
        VK_WebSearch,
        VK_WebStop,
        VK_Yen,
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
        };
    };


    instance *rd_create_instance();
    void rd_free_instance(instance *inst);


    render_target *rd_create_framebuffer(device *dev, uint32_t width, uint32_t height);


    struct sprite_params {
        bool is_translucent;
        bool is_static;
        color tint;
        matrix2d transform;
    };

    scene *rd_create_scene(device *device);
    void rd_free_scene(scene *scene);

    sprite_handle rd_create_sprite(scene *scene, sprite_params *params);
    void rd_destroy_sprite(scene *scene, sprite_handle sprite);

    void rd_get_sprite_transform(scene *scene, sprite_handle sprite, matrix2d *transform);
    void rd_set_sprite_transform(scene *scene, sprite_handle sprite, const matrix2d *transform);

    void rd_get_sprite_tint(scene *scene, sprite_handle sprite, color *tint);
    void rd_set_sprite_tint(scene *scene, sprite_handle sprite, const color *tint);


    struct adapter_output {
        output_id id;
        uint64_t device_memory;
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
    };

    // Call this function with (inst, 0, nil) and it will return the
    // number of outputs available. Otherwise it will fill `outputs`
    // up to the number of outputs or len, and return the number
    // written.
    size_t rd_get_outputs(instance *inst, size_t len, adapter_output *outputs);

    window *rd_create_window(device *device, const window_params *params);
    void rd_free_window(window *win);

    render_target *rd_get_window_target(window *win);
    void rd_get_window_dpi(window *win, float *dpix, float *dpiy);

        #ifdef __cplusplus
        }
        #endif
    