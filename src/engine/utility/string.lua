function string.snakify(str)
    local out = string.lower(string.sub(str, 1, 1))
    for i = 2, #str do
        local sub = string.sub(str, i, i)
        local low = string.lower(sub)
        if sub == low then
            out = out..sub
        else
            out = out..'_'..low
        end
    end
    return out
end
