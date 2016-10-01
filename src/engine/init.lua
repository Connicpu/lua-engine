require("engine.class")
require("engine.math")
require("engine.utility")

local module = {}

-- TEMP!!!!
local function build_texture(dev)
    local ffi = require("ffi")
    local err = require("engine.graphics.error")
    local params = ffi.new("struct texture_array_params")
    params.streaming = false
    params.sprite_count = 1
    params.sprite_width = 2
    params.sprite_height = 2
    params.pixel_art = true
    local buffer = ffi.new("uint32_t[4]")
    buffer[0] = 0xFF00FFFF
    buffer[1] = 0xFFFF00FF
    buffer[2] = 0xFFFFFF00
    buffer[3] = 0xFF7F7F7F
    local buffers = ffi.new("const uint8_t *[1]", ffi.cast("const uint8_t *", buffer))
    params.buffers = buffers

    return err.check_ptr(__rd.rd_create_texture_array(dev.dev, params))
end

local function build_sprite(scene, tary)
    local ffi = require("ffi")
    local err = require("engine.graphics.error")

    local params = ffi.new("struct sprite_params")
    params.tex = err.check_ptr(__rd.rd_get_texture(tary, 0))
    params.uv_bottomright = math.vec2(1, 1)
    params.transform = math.matrix2d.identity()
    params.tint = math.color(1, 1, 1, 1)

    return err.check_ptr(__rd.rd_create_sprite(scene.scene, params))
end

function module.run()
    local graphics = require("engine.graphics")

    -- Create the instance
    graphics.set_backend("rd-dx11")
    local inst = graphics.Instance()

    -- Choose the "best" adapter
    local adapter = inst:best_adapter()

    -- Create a device
    local device = graphics.Device(inst, adapter, true)
    
    -- Create a window
    local window = graphics.Window(device, {
        state = 'windowed',
        title = "Hiiiii!",
    })
    local back_buffer = window:render_target()

    local viewport = math.viewport()
    local camera = graphics.Camera(device)
    local textures = build_texture(device)

    local scenes = {}
    scenes[1] = graphics.Scene(device, 5, 5)
    local sprite = build_sprite(scenes[1], textures)

    local quit = false
    local occluded = false
    repeat
        for event in window:poll() do
            if event.event == 'closed' then
                quit = true
            elseif event.event == 'window_resized' then
                camera:set_aspect(event.width / event.height)
                viewport.w = event.width
                viewport.h = event.height
            end
        end

        if not occluded then
            window:begin_frame(device)
            back_buffer:clear(device, 'cornflower_blue')
            back_buffer:clear_depth(device)

            for i, scene in ipairs(scenes) do
                scene:draw(device, back_buffer, camera, viewport)
            end

            if window:present() == 'occluded' then
                print('occluded')
                occluded = true
            end
        -- If we're occluded, check if we're not anymore
        elseif window:test_occlusion() == 'unoccluded' then
            print('unoccluded')
            occluded = false
        end

        for sev, msg in device:debug_messages() do
            print(string.format("[D3D Debug]: [%s] %s", sev, msg))
        end
    until quit

    __rd.rd_destroy_sprite(scenes[1].scene, sprite)
end

return module
