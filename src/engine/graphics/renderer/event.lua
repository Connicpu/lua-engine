local ffi = require("engine.graphics.renderer.typedefs")

ffi.rd_header.cdef[[
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
]]

return ffi
