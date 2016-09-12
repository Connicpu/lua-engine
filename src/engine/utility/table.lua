local table = require("table")
local stringbuilder = require("engine.utility.stringbuilder").stringbuilder

function table.findi(t, value)
    for i = 1, #t do
        if t[i] == value then
            return i
        end
    end
end

function table.find(t, value)
    for k, v in pairs(t) do
        if v == value then
            return k
        end
    end
end

local function dump_line(indent, builder)
    builder:append("\n")
    for i = 1, indent do
        builder:append("    ")
    end
end

local function do_dump(value, indent, builder)
    if value == nil then
        return 'nil'
    end
    local t = type(value)
    if t ~= 'table' and t ~= 'cdata' then
        if t == 'string' then
            value = string.format("%q", value)
        end
        builder:append(value)
        return
    end

    local meta = getmetatable(value)
    if meta then
        local minspect = meta.__inspect
        if minspect then
            minspect(value, indent + 1, builder)
            return
        end
    end

    if t == 'table' then
        builder:append("{")
        local first = true
        for k, v in pairs(value) do
            if first then first = false
            else builder:append(",") end

            dump_line(indent + 1, builder)
            builder:append("[")
            do_dump(k, indent + 1, builder)
            builder:append("] = ")
            do_dump(v, indent + 1, builder)
        end

        if not first then
            dump_line(indent, builder)
        end
        builder:append("}")
        return
    end

    builder:append(value)
end

function table.dump(value)
    local builder = stringbuilder()
    do_dump(value, 0, builder)
    return tostring(builder)
end

