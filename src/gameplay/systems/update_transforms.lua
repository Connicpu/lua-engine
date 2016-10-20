local system = require("engine.system")
local filters = require("engine.filters")

local UpdateTransforms = system.System("UpdateTransforms")
UpdateTransforms.events = {"update"}

function UpdateTransforms:process(data, event)
    local transforms = data.components.transform

    -- Update all of the intermediate matrices
    for entity in data.entities:iter() do
        local t = transforms:get(entity)
        if t ~= nil then
            t:update()
        end
    end

    -- Update all of the parent hierarchies
    for entity in data.entities:iter() do
        local t = transforms:get(entity)
        if t ~= nil then
            t:update_self(data)
        end
    end
end

return UpdateTransforms
