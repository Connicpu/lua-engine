require("engine.class")
require("engine.math")
require("engine.utility")

local module = {}

function module.run()
    local graphics = require("engine.graphics")

    -- Create the instance
    graphics.set_backend("rd-dx11")
    local inst = graphics.Instance()

    -- Choose the "best" adapter
    local adapter = inst:best_adapter()

    -- Create a device
    local device = graphics.Device(inst, adapter)
    
    -- Create a window
    local window = graphics.Window(device, { title = "Hiiiii!" })
    local back_buffer = window:render_target()

    local quit = false
    local occluded = false
    repeat
        for event in window:poll() do
            if event.event == 'closed' then
                quit = true
            end
        end

        if not occluded then
            window:begin_frame(device)
            back_buffer:clear(device, 'red')
            back_buffer:clear_depth(device)

            -- TODO: Draw!

            if window:present() == 'occluded' then
                print('occluded')
                occluded = true
            end
        -- If we're occluded, check if we're not anymore
        elseif window:test_occlusion() == 'unoccluded' then
            print('unoccluded')
            occluded = false
        end
    until quit
end

return module
