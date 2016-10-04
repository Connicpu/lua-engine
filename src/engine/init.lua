require("class")
require("engine.math")
require("engine.utility")

local module = {}

function module.run()
    local graphics = require("engine.graphics")

    -- Create the instance
    graphics.set_backend("rd-dx11")
    local instance = graphics.Instance()

    -- Choose the "best" adapter
    local adapter = instance:best_adapter()

    -- Create a device
    local device = graphics.Device(instance, adapter, true)
    
    -- Create a window
    local window = graphics.Window(device, {
        state = 'windowed',
        title = "Hiiiii!",
    })
    local back_buffer = window:render_target()

    local viewport = math.viewport()
    local camera = graphics.Camera(device)

    -- TEMP!!!
    local color = math.color
    local textures = graphics.TextureArray.build_placeholder {
        device = device,
        { color.parse('Yellow'), color.parse('Cyan') },
        { color.parse('Magenta'), color.parse('Gray') },
    }

    local scenes = {}
    table.insert(scenes, graphics.Scene(device, 5, 5))

    local sprites = {}
    table.insert(sprites, scenes[1]:create_sprite {
        texture = textures:get(0),
    })

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

    for i, sprite in ipairs(sprites) do
        sprite:destroy()
    end
    for i, scene in ipairs(scenes) do
        scene:destroy()
    end
    window:destroy()
    device:destroy()
    instance:destroy()
end

return module
