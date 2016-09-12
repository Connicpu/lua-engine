local ffi = require("engine.graphics.renderer.typedefs")

ffi.cdef[[
    struct renderer_device_params {
        int expected_monitor;
    };

    renderer_device *renderer_create_device(const renderer_device_params *params);
    void renderer_free_device(renderer_device *device);
]]
