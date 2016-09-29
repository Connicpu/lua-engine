local ffi = require("ffi")
local io = require("io")

local rd_file
ffi.rd_header = {}

function ffi.rd_header.begin()
    local err
    rd_file, err = io.open("src/backends/common/renderer.h", "w+")
    if not rd_file then
        error(err)
    end

    rd_file:write[[
        #pragma once
        #ifdef __cplusplus
        #include <stdint.h>
        extern "C" {
        #endif

        struct vec2 {
            float x;
            float y;
        };
        struct matrix2d {
            float m11, m12;
            float m21, m22;
            float m31, m32;
        };
        struct color {
            float r, g, b, a;
        };
        struct viewport {
            float x, y;
            float w, h;
        };
    ]]
end

function ffi.rd_header.cdef(def)
    ffi.cdef(def)
    if rd_file then
        rd_file:write("\n")
        rd_file:write(def)
        rd_file:write("\n")
    end
end

function ffi.rd_header.finish()
    rd_file:write[[
        #ifdef __cplusplus
        }
        #endif
    ]]
    rd_file:close()
end

return ffi
