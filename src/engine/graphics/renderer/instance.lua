local ffi = require("engine.graphics.renderer.typedefs")

ffi.cdef[[
    instance *rd_create_instance();
    void rd_free_instance(instance *instance);
]]
