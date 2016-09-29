local io = require("io")
local os = require("os")
local args = { ... }

local baked_shaders
local function begin_shaders()
    baked_shaders = io.open("src/backends/"..args[1].."/baked_shaders.cpp", "w+")
    if args[1] ~= 'metal' then
        baked_shaders:write[[#include "pch.h"]]
        baked_shaders:write('\n')
    end
    baked_shaders:write[[
#include <unordered_map>
#include <string>
using namespace std::string_literals;

std::unordered_map<std::string, std::string> baked_shaders =
std::unordered_map<std::string, std::string> {
]]
end

local function output_shader(name, file)
    local datafile = io.open(file, "rb")
    local data = datafile:read("*a")
    datafile:close()

    baked_shaders:write('{"')
    baked_shaders:write(name)
    baked_shaders:write('"s,"')
    for i = 1, #data do
        baked_shaders:write(string.format("\\x%02X", string.byte(data, i)))
    end
    baked_shaders:write('"s},\n')
end

local function end_shaders()
    baked_shaders:write("};\n")
    baked_shaders:close()
end

if args[1] == 'dx11' then
    local powershell = "powershell -NoProfile -File"
    local fxcps1 = "build/windows/fxc.ps1 /nologo"
    local fxc = powershell..' '..fxcps1
    local shader_dir = "src/backends/shaders/dx11/"

    local shaders = { "sprite.ps.hlsl", "sprite.vs.hlsl" }

    local success = true
    for i, shader in ipairs(shaders) do
        local input = shader_dir..shader
        local output = args[2]..string.gsub(shader, ".hlsl", ".cso")

        local profile
        if string.match(shader, ".vs.hlsl$") then
            profile = "vs_5_0"
        else
            profile = "ps_5_0"
        end

        if os.execute(fxc.." /T "..profile.." "..input.." /Fo "..output) ~= 0 then
            success = false
        end
    end

    if success then
        begin_shaders()
        for i, shader in ipairs(shaders) do
            local output = args[2]..string.gsub(shader, ".hlsl", ".cso")
            output_shader(shader, output)
        end
        end_shaders()
    end

elseif args[1] == 'vulkan' then



elseif args[1] == 'metal' then



else
    error("Unknown shader set "..args[1])
end

