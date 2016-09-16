local ffi = require("ffi")

local function create_list_type(comp_t)
    return ffi.typeof(cdef[[
        struct {
            $ *data;
            size_t cap;
            size_t len;
        }
    ]], comp_t)
end



