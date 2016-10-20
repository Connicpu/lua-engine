local ffi = require("ffi")
local io = require("io")

local rd_file
ffi.rd_header = { cpp_only = {} }

function ffi.rd_header.begin()
    local err
    rd_file, err = io.open("src/backends/common/renderer.h", "w+")
    if not rd_file then
        error(err)
    end

    rd_file:write[[
        #pragma once
        #include <stddef.h>
        #include <stdint.h>
        #ifdef __cplusplus
        #define RD_IF_CPP(x) x
        extern "C" {
        #else
        #define RD_IF_CPP(x) 
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
    local ffi_def = string.gsub(def, "#ENUM", "")
    local cpp_def = string.gsub(def, "#ENUM", "RD_IF_CPP(:int)")
    ffi.cdef(ffi_def)
    if rd_file then
        rd_file:write("\n")
        rd_file:write(cpp_def)
        rd_file:write("\n")
    end
end

function ffi.rd_header.finish()
    rd_file:write[[
        #ifdef __cplusplus
        }
        #include "helpers.h"
        #endif
    ]]
    rd_file:close()
end

return ffi
