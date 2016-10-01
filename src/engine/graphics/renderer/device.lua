local ffi = require("engine.graphics.renderer.typedefs")

ffi.rd_header.cdef[[
    struct device_params {
        instance *inst;
        output_id preferred_output;
        bool enable_debug_mode;
    };

    device *rd_create_device(const device_params *params);
    void rd_free_device(device *dev);

    struct debuglog_entry {
        int severity;
        const char *msg;
        size_t len;
    };
    
    void rd_process_debuglog(device *dev);
    bool rd_next_debuglog(device *dev, struct debuglog_entry *entry);
]]

return ffi
