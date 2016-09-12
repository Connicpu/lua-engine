local ffi = require("engine.graphics.renderer.typedefs")

ffi.cdef[[
    struct renderer_error {
        int system_code;

        size_t message_len;
        char message[500];
    };

    bool renderer_last_error(renderer_error *error);
]]
