local table = require("table")

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

