local ffi = require("engine.graphics.renderer.typedefs")

ffi.cdef[[
    struct renderer_error {
        int system_code;
        char message[128];
    };

    // NOTE: The state is thread-local
    bool rd_last_error(renderer_error *error);
    void rd_clear_error();
]]
