local io = require("io")

local function build_module(input, output)
    input = io.open(input, 'r')
    output = io.open(output, 'w+')

    output:write("EXPORTS\n")
    for line in input:lines() do
        local match = string.match(line, "rd_([a-z_]+)%(")
        if match then
            output:write("    rd_")
            output:write(match)
            output:write('\n')
        end
    end

    input:close()
    output:close()
end

local function build()
    local input = "src/backends/common/renderer.h"
    local dx11 = "src/backends/dx11/module.def"
    local vulkan = "src/backends/vulkan/module.def"
    
    build_module(input, dx11)
    --build_module(input, vulkan)
end

return {
    build = build
}
