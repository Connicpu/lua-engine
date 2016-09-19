local ffi = require("engine.graphics.renderer.typedefs")

ffi.rd_header.cdef[[
    struct device_params {
        instance *inst;
        output_id preferred_output;
        bool enable_debug_mode;
    };

    device *rd_create_device(const device_params *params);
    void rd_free_device(device *dev);
]]
