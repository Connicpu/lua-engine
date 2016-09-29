#include "pch.h"
#include "win32_handler.h"
#include <backends/dx11/platform.h>
#include <random>
#include <mutex>

static LRESULT WINAPI wnd_proc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp);

static std::wstring make_class(HINSTANCE hinst)
{
    struct window_class
    {
        HINSTANCE hinst;
        std::wstring name;

        window_class(HINSTANCE hinst)
            : hinst(hinst), name(L"lua-enging.win32-handler")
        {
            WNDCLASSEXW wndc = { sizeof(wndc) };
            wndc.cbClsExtra = 0;
            wndc.cbWndExtra = sizeof(window_handler *);
            wndc.hbrBackground = nullptr;
            wndc.hCursor = LoadCursor(nullptr, IDC_ARROW);
            wndc.hIcon = nullptr;
            wndc.hIconSm = nullptr;
            wndc.hInstance = hinst;
            wndc.lpfnWndProc = wnd_proc;
            wndc.lpszClassName = name.c_str();
            wndc.lpszMenuName = nullptr;
            wndc.style = CS_DBLCLKS | CS_VREDRAW | CS_HREDRAW;
            RegisterClassExW(&wndc);
        }

        ~window_class()
        {
            UnregisterClassW(name.c_str(), hinst);
        }

        window_class(const window_class &) = delete;
        window_class &operator=(const window_class &) = delete;
    };

    static window_class wndc{ hinst };
    return wndc.name;
}

static bool make_borderless(window_handler *win)
{
    DWORD dwStyle = GetWindowLong(win->hwnd, GWL_STYLE);

    if (GetWindowPlacement(win->hwnd, &win->wp))
    {
        SetWindowLongW(
            win->hwnd, GWL_STYLE,
            dwStyle & ~WS_OVERLAPPEDWINDOW
            );

        ShowWindow(win->hwnd, SW_MAXIMIZE);

        return true;
    }

    return false;
}

static void make_normal(window_handler *win)
{
    DWORD dwStyle = GetWindowLongW(win->hwnd, GWL_STYLE);
    MONITORINFO mi = { sizeof(mi) };

    SetWindowLongW(
        win->hwnd, GWL_STYLE,
        dwStyle | WS_OVERLAPPEDWINDOW
        );

    SetWindowPlacement(
        win->hwnd,
        &win->wp
        );

    SetWindowPos(
        win->hwnd, nullptr, 0, 0, 0, 0,
        SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
        SWP_NOOWNERZORDER | SWP_FRAMECHANGED
        );
}

window_handler::~window_handler()
{
    if (hwnd)
    {
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, (LONG_PTR)nullptr);
        DestroyWindow(hwnd);
    }
}

window_handler * rd_create_wh(const window_params * params)
{
    std::unique_ptr<window_handler> wh(new window_handler);

    auto title = widen(params->title);
    auto hinst = GetHinstanceFromFn(rd_create_wh);

    auto width = params->windowed_width;
    auto height = params->windowed_height;
    if (width == -1) width = CW_USEDEFAULT;
    if (height == -1) width = CW_USEDEFAULT;

    wh->hinst = hinst;
    wh->wnd_class = make_class(hinst);

    wh->hwnd = CreateWindowExW(
        0,
        wh->wnd_class.c_str(),
        title.c_str(),
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        width,
        height,
        nullptr,
        nullptr,
        hinst,
        wh.get()
        );

    DragAcceptFiles(wh->hwnd, true);
    ShowWindow(wh->hwnd, SW_SHOWNORMAL);

    if (params->state == borderless)
    {
        if (!make_borderless(wh.get()))
        {
            return set_error_and_ret("Failed to create a borderless window");
        }
    }

    wh->state = params->state;

    return wh.release();
}

void rd_free_wh(window_handler * handler)
{
    delete handler;
}

bool rd_set_wh_state(window_handler * win, window_state state)
{
    if (state == win->state)
        return true;

    if (state == borderless)
    {
        if (!make_borderless(win))
            return set_error_and_ret("Failed to switch to borderless windowed mode");
    }
    else
    {
        make_normal(win);
    }

    return true;
}

bool rd_check_dirty_buffers(window_handler * handler)
{
    auto temp = handler->dirty_buffers;
    handler->dirty_buffers = false;
    return temp;
}

void * rd_get_wh_platform_handle(window_handler * handler)
{
    return handler->hwnd;
}

bool rd_poll_window_handler(window_handler * handler, window_event * event)
{
    for (;;)
    {
        if (handler->events.try_pop(*event))
        {
            return true;
        }

        MSG msg;
        if (!PeekMessageW(&msg, handler->hwnd, 0, 0, PM_REMOVE))
        {
            return false;
        }

        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
}

void rd_free_wh_event(window_event * event)
{
    switch (event->event)
    {
        case EVENT_DROPPED_FILE:
            free(event->dropped_file.path);
            break;

        default:
            // No freeing necessary
            break;
    }
}

static virtual_key_code map_vk(int vk, bool &has);
static void get_event_button(UINT msg, WPARAM wp, mouse_button *button, element_state *state);

static LRESULT WINAPI wnd_proc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
{
    window_event event;
    window_handler *win = (window_handler *)GetWindowLongPtrW(hwnd, GWLP_USERDATA);
    switch (msg)
    {
        // Upon creation of the window, we get the display from the CREATESTRUCT(W)
        // and set its value into the USERDATA section of our window.
        case WM_CREATE:
        {
            CREATESTRUCTW *create = (CREATESTRUCTW *)lp;
            win = (window_handler *)create->lpCreateParams;
            SetWindowLongPtrW(hwnd, GWLP_USERDATA, (LONG_PTR)win);
            return 0;
        }

        // Window resizes!
        case WM_SIZE:
        {
            if (win)
            {
                event.event = EVENT_WINDOW_RESIZED;
                event.window_resized.width = LOWORD(lp);
                event.window_resized.height = HIWORD(lp);
                win->events.push(event);
                win->dirty_buffers = true;
            }
            break;
        }

        // Window got moved :3
        case WM_MOVE:
        {
            if (win)
            {
                event.event = EVENT_WINDOW_MOVED;
                event.window_moved.x = (short)LOWORD(lp);
                event.window_moved.y = (short)HIWORD(lp);
                win->events.push(event);
            }
            break;
        }

        // RIP Window
        case WM_CLOSE:
        {
            if (win)
            {
                event.event = EVENT_CLOSED;
                win->events.push(event);
                return 0;
            }
            break;
        }

        // Oh boy! Drag-and-drop files! :D
        case WM_DROPFILES:
        {
            auto drop = (HDROP)wp;
            if (win)
            {
                uint32_t file_count = DragQueryFileW(drop, UINT_MAX, nullptr, 0);
                for (uint32_t i = 0; i < file_count; ++i)
                {
                    POINT point;
                    uint32_t path_len = DragQueryFileW(drop, i, nullptr, 0);
                    std::vector<wchar_t> temp_path(path_len + 1);
                    if (DragQueryFileW(drop, i, temp_path.data(), (uint32_t)temp_path.size()) &&
                        DragQueryPoint(drop, &point))
                    {
                        event.event = EVENT_DROPPED_FILE;
                        event.dropped_file.x = point.x;
                        event.dropped_file.y = point.y;

                        auto path_str = narrow(temp_path.data());
                        auto path = (char *)malloc(path_str.size() + 1);
                        memcpy(path, path_str.c_str(), path_str.size() + 1);
                        event.dropped_file.path = path;
                        event.dropped_file.path_len = path_str.size();

                        win->events.push(event);
                    }
                }
            }
            DragFinish(drop);
            return 0;
        }

        // Receive characters!
        case WM_CHAR:
        {
            thread_local static bool HAS_HIGH_SURROGATE;
            thread_local static wchar_t LAST_HIGH_SURROGATE;

            uint32_t char_code;
            if (IS_HIGH_SURROGATE(wp))
            {
                HAS_HIGH_SURROGATE = true;
                LAST_HIGH_SURROGATE = (wchar_t)wp;
                break;
            }
            else if (IS_LOW_SURROGATE(wp))
            {
                if (!HAS_HIGH_SURROGATE)
                    break;

                wchar_t hs = LAST_HIGH_SURROGATE;
                wchar_t ls = (wchar_t)wp;

                HAS_HIGH_SURROGATE = false;
                if (!IS_SURROGATE_PAIR(hs, ls))
                    break;

                // Credit: following 4 lines taken from http://www.unicode.org/faq//utf_bom.html
                uint32_t X = (uint32_t(hs) & ((1 << 6) - 1)) << 10 | uint32_t(ls) & ((1 << 10) - 1);
                uint32_t W = (uint32_t(hs) >> 6) & ((1 << 5) - 1);
                uint32_t U = W + 1;
                uint32_t C = U << 16 | X;

                char_code = C;
            }
            else
            {
                char_code = (uint32_t)wp;
            }

            if (win)
            {
                event.event = EVENT_KEYBOARD_CHARACTER;
                event.char_input.codepoint = char_code;
                win->events.push(event);
            }
            break;
        }

        // Receive/Lose focus
        case WM_KILLFOCUS:
        case WM_SETFOCUS:
        {
            if (win)
            {
                event.event = EVENT_WINDOW_FOCUS;
                event.window_focus.state = (msg == WM_SETFOCUS);
                win->events.push(event);
            }
            break;
        }

        // Keyboard input ;) the VK mapping is a doozy
        case WM_KEYDOWN:
        case WM_KEYUP:
        {
            uint8_t scancode = uint8_t((lp >> 16) & 0xFF);
            bool extended = (lp & 0x01000000) != 0;
            int vk = 0;
            switch ((int)wp)
            {
                case VK_SHIFT:
                    vk = MapVirtualKeyA(scancode, MAPVK_VSC_TO_VK_EX);
                    break;
                case VK_CONTROL:
                    if (extended)
                        vk = VK_RCONTROL;
                    else
                        vk = VK_LCONTROL;
                    break;
                case VK_MENU:
                    if (extended)
                        vk = VK_RMENU;
                    else
                        vk = VK_LMENU;
                    break;
                default:
                    vk = (int)wp;
                    break;
            }

            if (win)
            {
                event.event = EVENT_KEYBOARD_INPUT;
                event.key_input.scan_code = scancode;
                event.key_input.virtual_key = map_vk(vk, event.key_input.has_vk);
                if (msg == WM_KEYDOWN)
                    event.key_input.state = ELEM_PRESSED;
                else
                    event.key_input.state = ELEM_RELEASED;
                win->events.push(event);
            }
        }

        // Whenever the mouse moves ;)
        case WM_MOUSEMOVE:
        {
            if (win)
            {
                event.event = EVENT_MOUSE_MOVED;
                event.mouse_moved.x = (short)LOWORD(lp);
                event.mouse_moved.y = (short)HIWORD(lp);
                win->events.push(event);
            }
            break;
        }

        // Mouse wheel scrolling
        case WM_MOUSEWHEEL:
        {
            auto raw_delta = GET_WHEEL_DELTA_WPARAM(wp);
            auto delta = float(raw_delta) / WHEEL_DELTA;

            if (win)
            {
                event.event = EVENT_MOUSE_WHEEL;
                event.mouse_wheel.dx = 0;
                event.mouse_wheel.dy = delta;
                win->events.push(event);
            }
            break;
        }

        // Mouse button events. SO MANY! XD
        case WM_LBUTTONDOWN: case WM_LBUTTONUP:
        case WM_RBUTTONDOWN: case WM_RBUTTONUP:
        case WM_MBUTTONDOWN: case WM_MBUTTONUP:
        case WM_XBUTTONDOWN: case WM_XBUTTONUP:
        {
            if (win)
            {
                event.event = EVENT_MOUSE_INPUT;
                get_event_button(msg, wp, &event.mouse_input.button, &event.mouse_input.state);
                win->events.push(event);
            }
            break;
        }

        default:
        {
            break;
        }
    }
    return DefWindowProcW(hwnd, msg, wp, lp);
}


static virtual_key_code map_vk(int vk, bool &has)
{
    has = true;
    if (vk >= 'A' && vk <= 'Z')
        return (virtual_key_code)(((int)Vk_A) + (vk - 'A'));
    if (vk >= '0' && vk <= '9')
        return (virtual_key_code)(((int)Vk_Key0) + (vk - '0'));
    if (vk >= VK_F1 && vk <= VK_F15)
        return (virtual_key_code)(((int)Vk_F1) + (vk - VK_F1));
    if (vk >= VK_NUMPAD0 && vk <= VK_NUMPAD9)
        return (virtual_key_code)(((int)Vk_Numpad0) + (vk - VK_NUMPAD0));

    switch (vk)
    {
        case VK_ESCAPE:
            return Vk_Escape;

        case VK_SNAPSHOT:
            return Vk_Snapshot;
        case VK_SCROLL:
            return Vk_Scroll;
        case VK_PAUSE:
            return Vk_Pause;

        case VK_INSERT:
            return Vk_Insert;
        case VK_HOME:
            return Vk_Home;
        case VK_DELETE:
            return Vk_Delete;
        case VK_END:
            return Vk_End;
        case VK_NEXT:
            return Vk_PageDown;
        case VK_PRIOR:
            return Vk_PageUp;

        case VK_LEFT:
            return Vk_Left;
        case VK_UP:
            return Vk_Up;
        case VK_RIGHT:
            return Vk_Right;
        case VK_DOWN:
            return Vk_Down;

        case VK_BACK:
            return Vk_Back;
        case VK_RETURN:
            return Vk_Return;
        case VK_SPACE:
            return Vk_Space;

        case VK_NUMLOCK:
            return Vk_Numlock;

        case VK_ADD:
            return Vk_Add;
        case VK_OEM_7:
            return Vk_Apostrophe;
        case VK_APPS:
            return Vk_Apps;
        case VK_OEM_102:
            return Vk_Backslash;
        case VK_CAPITAL:
            return Vk_Capital;
        case VK_OEM_1:
            return Vk_Colon;
        case VK_OEM_COMMA:
            return Vk_Comma;
        case VK_CONVERT:
            return Vk_Convert;
        case VK_DECIMAL:
            return Vk_Decimal;
        case VK_DIVIDE:
            return Vk_Divide;
        case VK_OEM_PLUS:
            return Vk_Equals;
        case VK_OEM_3:
            return Vk_Grave;
        case VK_KANA:
            return Vk_Kana;
        case VK_KANJI:
            return Vk_Kanji;
        case VK_LCONTROL:
            return Vk_LControl;
        case VK_LMENU:
            return Vk_LMenu;
        case VK_LSHIFT:
            return Vk_LShift;
        case VK_LWIN:
            return Vk_LWin;
        case VK_LAUNCH_MAIL:
            return Vk_Mail;
        case VK_LAUNCH_MEDIA_SELECT:
            return Vk_MediaSelect;
        case VK_MEDIA_STOP:
            return Vk_MediaStop;
        case VK_OEM_MINUS:
            return Vk_Minus;
        case VK_MULTIPLY:
            return Vk_Multiply;
        case VK_VOLUME_MUTE:
            return Vk_Mute;
        case VK_BROWSER_FORWARD:
            return Vk_NavigateForward;
        case VK_BROWSER_BACK:
            return Vk_NavigateBackward;
        case VK_MEDIA_NEXT_TRACK:
            return Vk_NextTrack;
        case VK_NONCONVERT:
            return Vk_NoConvert;
        case VK_OEM_PERIOD:
            return Vk_Period;
        case VK_MEDIA_PLAY_PAUSE:
            return Vk_PlayPause;
        case VK_MEDIA_PREV_TRACK:
            return Vk_PrevTrack;
        case VK_RCONTROL:
            return Vk_RControl;
        case VK_RMENU:
            return Vk_RMenu;
        case VK_RSHIFT:
            return Vk_RShift;
        case VK_RWIN:
            return Vk_RWin;
        case VK_OEM_2:
            return Vk_Slash;
        case VK_SLEEP:
            return Vk_Sleep;
        case VK_BROWSER_STOP:
            return Vk_Stop;
        case VK_SUBTRACT:
            return Vk_Subtract;
        case VK_TAB:
            return Vk_Tab;
        case VK_VOLUME_DOWN:
            return Vk_VolumeDown;
        case VK_VOLUME_UP:
            return Vk_VolumeUp;
        case VK_BROWSER_FAVORITES:
            return Vk_WebFavorites;
        case VK_BROWSER_HOME:
            return Vk_WebHome;
        case VK_BROWSER_REFRESH:
            return Vk_WebRefresh;
        case VK_BROWSER_SEARCH:
            return Vk_WebSearch;

        default:
            has = false;
            return (virtual_key_code)0;
    }
}

static void get_event_button(UINT msg, WPARAM wp, mouse_button *button, element_state *state)
{
    UINT base;
    if (msg >= WM_XBUTTONDOWN)
    {
        base = msg - WM_XBUTTONDOWN;
        if (HIWORD(wp) == XBUTTON1)
            *button = Mb_X1;
        else
            *button = Mb_X2;
    }
    else if (msg >= WM_MBUTTONDOWN)
    {
        base = msg - WM_MBUTTONDOWN;
        *button = Mb_Middle;
    }
    else if (msg >= WM_RBUTTONDOWN)
    {
        base = msg - WM_RBUTTONDOWN;
        *button = Mb_Right;
    }
    else
    {
        base = msg - WM_LBUTTONDOWN;
        *button = Mb_Left;
    }

    switch (base)
    {
        case 0:
            *state = ELEM_PRESSED;
            break;
        case 1:
            *state = ELEM_RELEASED;
            break;
        default:
            unreachable_msg("Invalid event made it in here");
    }
}
