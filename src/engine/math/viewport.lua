local ffi = require("ffi")

ffi.cdef[[
    struct viewport {
        float x, y;
        float w, h;
    };
]]

local viewport_ct

viewport_ct = ffi.typeof("struct viewport")

return {
    viewport = viewport_ct
}
