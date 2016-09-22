local ffi = require("engine.graphics.renderer.typedefs")

ffi.rd_header.cdef[[
    camera *rd_create_camera();
    void rd_free_camera(camera *cam);

    void rd_set_camera_aspect(camera *cam, float aspect_ratio);
    bool rd_update_camera(camera *cam, matrix2d *transform);
]]

return ffi
