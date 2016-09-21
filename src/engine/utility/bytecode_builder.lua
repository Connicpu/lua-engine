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
        #include <unordered_map>

        std::unordered_map<std::string, std::string> baked_bytecode =
        std::unordered_map<std::string, std::string> {
    ]]
end

local function end_build()
    bfile:write("};")
    bfile:close()
end

local function build_file(path, mod_name)
    local lfile = io.open(path:to_str(), "r")
    
    local f_iter, f_state, f_line = lfile:lines()
    local func, err = load(function()
        repeat
            f_line = f_iter(f_state, f_line)
        until f_line ~= ""
        if f_line then
            return f_line.."\n"
        end
    end, mod_name)
    if not func then
        print("[WARNING] Error building "..mod_name)
        print(err)
        return
    end

    local data = string.dump(func)

    bfile:write('{"')
    bfile:write(mod_name)
    bfile:write('","')

    for i = 1, #data do
        bfile:write(string.format("\\x%02X", string.byte(data, i)))
    end

    bfile:write('"},\n')
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

function module.build()
    local root = path.new("src")
    start_build()
    build_dir(root, nil)
    end_build()
end

return module
