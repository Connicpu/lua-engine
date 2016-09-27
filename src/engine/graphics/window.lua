local ffi = require("engine.graphics.renderer")
local path = require("engine.utility.path")
local rd_err = require("engine.graphics.error")
local render_target = require("engine.graphics.render_target")

local C = ffi.C
local check_ptr = rd_err.check_ptr
local check_bool = rd_err.check_bool
local fail = rd_err.fail
local ffi_new = ffi.new
local ffi_cast = ffi.cast
local ffi_gc = ffi.gc
local ffi_string = ffi.string

local wparams_t = ffi.typeof("struct window_params");

local Window_t = ffi.typeof("struct{window *win; window_event last_event; bool has_event;}")
local Window = {}
local Window_mt = { __index = Window }
local Window_ct

local function window_state(state)
    if state == 'borderless' then
        return __rd.borderless
    elseif state == 'fullscreen' then
        return __rd.fullscreen
    else
        return __rd.windowed
    end
end

local function window_state_name(state)
    if state == __rd.borderless then
        return 'borderless'
    elseif state == __rd.fullscreen then
        return 'fullscreen'
    else
        return 'windowed'
    end
end

function Window_mt.__new(tp, dev, params)
    params = params or {}

    local wparams = ffi_new(wparams_t)
    wparams.state = window_state(params.state)
    wparams.windowed_width = params.width or -1
    wparams.windowed_height = params.height or -1
    wparams.title = params.title or "Unnamed window ;)"

    local win = check_ptr(__rd.rd_create_window(dev.dev, wparams))
    return ffi_new(tp, win)
end

function Window_mt:__gc()
    self:destroy()
end

function Window:destroy()
    if self.win ~= nil then
        __rd.rd_free_window(self.win)
        self.win = nil
    end
end

local function event_tostr(event)
    if event == __rd.EVENT_CLOSED then
        return 'closed'
    elseif event == __rd.EVENT_WINDOW_RESIZED then
        return 'window_resized'
    elseif event == __rd.EVENT_WINDOW_MOVED then
        return 'window_moved'
    elseif event == __rd.EVENT_WINDOW_FOCUS then
        return 'window_focus'
    elseif event == __rd.EVENT_DROPPED_FILE then
        return 'dropped_file'
    elseif event == __rd.EVENT_KEYBOARD_CHARACTER then
        return 'keyboard_character'
    elseif event == __rd.EVENT_KEYBOARD_INPUT then
        return 'keyboard_input'
    elseif event == __rd.EVENT_MOUSE_MOVED then
        return 'mouse_moved'
    elseif event == __rd.EVENT_MOUSE_INPUT then
        return 'mouse_input'
    elseif event == __rd.EVENT_MOUSE_WHEEL then
        return 'mouse_wheel'
    elseif event == __rd.EVENT_DPI_CHANGED then
        return 'dpi_changed'
    end
    error("Unknown event `"..event.."`")
end

local function mb_tostr(mb)
    if mb == __rd.Mb_Left then
        return 'left'
    elseif mb == __rd.Mb_Right then
        return 'right'
    elseif mb == __rd.Mb_Middle then
        return 'middle'
    elseif mb == __rd.Mb_X1 then
        return 'x1'
    elseif mb == __rd.Mb_X2 then
        return 'x2'
    end
    error("Unknown mouse button `"..mb.."`")
end

local vk_names = {
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',

    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',

    'Escape',

    'F1',
    'F2',
    'F3',
    'F4',
    'F5',
    'F6',
    'F7',
    'F8',
    'F9',
    'F10',
    'F11',
    'F12',
    'F13',
    'F14',
    'F15',

    'Snapshot',
    'Scroll',
    'Pause',

    'Insert',
    'Home',
    'Delete',
    'End',
    'PageDown',
    'PageUp',

    'Left',
    'Up',
    'Right',
    'Down',

    'Back',
    'Return',
    'Space',

    'Numlock',
    'Numpad0',
    'Numpad1',
    'Numpad2',
    'Numpad3',
    'Numpad4',
    'Numpad5',
    'Numpad6',
    'Numpad7',
    'Numpad8',
    'Numpad9',

    'AbntC1',
    'AbntC2',
    'Add',
    'Apostrophe',
    'Apps',
    'At',
    'Ax',
    'Backslash',
    'Calculator',
    'Capital',
    'Colon',
    'Comma',
    'Convert',
    'Decimal',
    'Divide',
    'Equals',
    'Grave',
    'Kana',
    'Kanji',
    'LAlt',
    'LBracket',
    'LControl',
    'LMenu',
    'LShift',
    'LWin',
    'Mail',
    'MediaSelect',
    'MediaStop',
    'Minus',
    'Multiply',
    'Mute',
    'MyComputer',
    'NavigateForward',
    'NavigateBackward',
    'NextTrack',
    'NoConvert',
    'NumpadComma',
    'NumpadEnter',
    'NumpadEquals',
    'OEM102',
    'Period',
    'PlayPause',
    'Power',
    'PrevTrack',
    'RAlt',
    'RBracket',
    'RControl',
    'RMenu',
    'RShift',
    'RWin',
    'Semicolon',
    'Slash',
    'Sleep',
    'Stop',
    'Subtract',
    'Sysrq',
    'Tab',
    'Underline',
    'Unlabeled',
    'VolumeDown',
    'VolumeUp',
    'Wake',
    'WebBack',
    'WebFavorites',
    'WebForward',
    'WebHome',
    'WebRefresh',
    'WebSearch',
    'WebStop',
    'Yen',
}

local vk_codes = {}
for i, name in ipairs(vk_names) do
    vk_codes[name] = i - 1
    vk_codes[string.lower(name)] = i - 1
    vk_codes[string.snakify(name)] = i - 1
end

local function vk_tostr(vk)
    return vk_names[vk + 1]
end

local function vk_parse(name)
    return vk_codes[name]
end

local function elem_tostr(elem)
    if elem == __rd.ELEM_PRESSED then
        return 'pressed'
    elseif elem == __rd.ELEM_RELEASED then
        return 'released'
    end
end

local function translate_window_event(data)
    local name = event_tostr(data.event)
    local event = { event = name }
    if name == 'window_resized' then
        event.width = data.window_resized.width
        event.height = data.window_resized.height
    elseif name == 'window_moved' then
        event.x = data.window_moved.x
        event.y = data.window_moved.y
        event.width = data.window_moved.width
        event.height = data.window_moved.height
    elseif name == 'window_focus' then
        event.state = data.window_focus.state
    elseif name == 'dropped_file' then
        event.x = data.dropped_file.x
        event.y = data.dropped_file.y
        event.path = path.new(ffi_string(data.dropped_file.path, data.dropped_file.path_len))
    elseif name == 'keyboard_character' then
        event.codepoint = data.char_input.codepoint
    elseif name == 'keyboard_input' then
        event.state = elem_tostr(data.key_input.state)
        if data.key_input.has_vk then
            event.virtual_key = vk_tostr(data.key_input.virtual_key)
        end
        event.scan_code = data.key_input.scan_code
    elseif name == 'mouse_moved' then
        event.x = data.mouse_moved.x
        event.y = data.mouse_moved.y
    elseif name == 'mouse_input' then
        event.button = mb_tostr(data.mouse_input.button)
        event.state = elem_tostr(data.mouse_input.state)
        event.x = data.mouse_input.x
        event.y = data.mouse_input.y
    elseif name == 'mouse_wheel' then
        event.dx = event.mouse_wheel.dx
        event.dy = event.mouse_wheel.dy
    elseif name == 'dpi_changed' then
        event.dpi = event.dpi_changed.dpi
    end
    return event
end

local function poll_iter(self)
    if self.has_event then
        __rd.rd_free_window_event(self.last_event)
    end

    if __rd.rd_poll_window_event(self.win, self.last_event) then
        return translate_window_event(self.last_event)
    end
end

function Window:poll()
    return poll_iter, self
end

function Window:render_target()
    local rt = check_ptr(__rd.rd_get_window_target(self.win))
    return render_target.RenderTarget(rt)
end

function Window:begin_frame(dev)
    check_bool(__rd.rd_prepare_window_for_drawing(dev.dev, self.win))
end

function Window:present()
    local status = __rd.rd_present_window(self.win)
    if status == 1 then
        return 'occluded'
    elseif status == -1 then
        fail()
    end
end

function Window:test_occlusion()
    return __rd.rd_test_window_occlusion(self.win)
end

Window_ct = ffi.metatype(Window_t, Window_mt)

return {
    Window = Window_ct,
}
