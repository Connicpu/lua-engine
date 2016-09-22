local path = require("engine.utility.path")
local io = require("io")

local module = {}

local bfile

local function start_build()
    local err
    bfile, err = io.open("src/launcher/bytecode.cpp", "w+")
    if not bfile then
        error(err)
    end

    bfile:write[[
#include "bytecode.h"
using namespace std::string_literals;

std::unordered_map<std::string, std::string> baked_bytecode =
std::unordered_map<std::string, std::string> {
]]
end

local function end_build()
    bfile:write("};\n")
end

local function build_file(path, mod_name)
    local lfile = io.open(path:to_str(), "r")
    
    local f_iter, f_state, f_line = lfile:lines()
    local func, err = load(function()
        f_line = f_iter(f_state, f_line)
        if f_line then
            return f_line.."\n"
        end
    end, mod_name)
    if not func then
        print("[WARNING] Error building "..mod_name)
        print(err)
        return
    end

    local data = string.dump(func, true)

    bfile:write('{"')
    bfile:write(mod_name)
    bfile:write('"s,"')

    for i = 1, #data do
        bfile:write(string.format("\\x%02X", string.byte(data, i)))
    end

    bfile:write('"s},\n')
end

local function inner_mod(item, mod_name)
    local item_name
    if item:is_dir() or item:extension() == nil then
        item_name = item:file_name()
    else
        item_name = item:file_stem()
    end

    if mod_name then
        return mod_name .. "." .. item_name
    else
        return item_name
    end
end

local function build_dir(dir, mod_name)
    for item in dir:walk() do
        local mod = inner_mod(item, mod_name)
        if item:is_dir() then
            build_dir(item, mod)
        else
            if item:file_name() == 'init.lua' then
                build_file(item, mod_name)
            elseif item:extension() == 'lua' then
                build_file(item, mod)
            end
        end
    end
end

local function start_list()
    bfile:write[[
bytecode_listing bytecode_list =
]]
end

local function end_list()
    bfile:write(";")
    bfile:close()
end

local function indent(i)
    for j = 0, i do
        bfile:write("    ")
    end
end

local function contains_lua(dir)
    for item in dir:walk() do
        if item:is_file() and item:extension() == 'lua' then
            return true
        elseif item:is_dir() then
            if contains_lua(item) then
                return true
            end
        end
    end
    return false
end

local function list_dir(path, i)
    bfile:write("bytecode_listing {\n")
    indent(i + 1)
    bfile:write("std::unordered_set<std::string> {")
    for item in path:walk() do
        if item:is_file() and item:extension() == 'lua' then
            bfile:write('"')
            bfile:write(item:file_stem())
            bfile:write('"s,')
        elseif item:is_dir() and path.join(item, "init.lua"):exists() then
            bfile:write('"')
            bfile:write(item:file_name())
            bfile:write('"s,')
        end
    end
    bfile:write("},\n")

    indent(i + 1)
    bfile:write("std::unordered_map<std::string, bytecode_listing> {\n")
    for item in path:walk() do
        if item:is_dir() and contains_lua(item) then
            indent(i + 2)
            bfile:write('{"')
            bfile:write(item:file_name())
            bfile:write('"s, ')
            list_dir(item, i + 2)
            bfile:write("},\n")
        end
    end
    indent(i + 1)
    bfile:write("},\n")
    indent(i)
    bfile:write("}")
end

function module.build()
    local root = path.new("src")
    start_build()
    build_dir(root, nil)
    end_build()
    start_list()
    list_dir(root, 0)
    end_list()
end

return module
