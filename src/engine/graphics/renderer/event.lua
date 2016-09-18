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
]]

return ffi
