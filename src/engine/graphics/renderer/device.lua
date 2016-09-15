local ffi = require("engine.graphics.renderer.typedefs")

ffi.cdef[[
    struct device_params {
        instance *inst;
        output_id preferred_output;
    };

    device *rd_create_device(const device_params *params);
    void rd_free_device(device *dev);
]]
