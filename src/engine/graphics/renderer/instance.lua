local ffi = require("engine.graphics.renderer.typedefs")

ffi.rd_header.cdef[[
    instance *rd_create_instance();
    void rd_free_instance(instance *inst);
]]

return ffi
