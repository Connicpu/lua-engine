local ffi = require("engine.graphics.renderer.typedefs")

ffi.rd_header.cdef[[
    struct renderer_error {
        int system_code;
        char message[1024];
    };

    // NOTE: The state is thread-local
    bool rd_last_error(renderer_error *error);
    void rd_clear_error();
]]
