local ffi = require("engine.graphics.renderer.typedefs")

ffi.rd_header.cdef[[
    struct texture_set_params {
        bool streaming;
        uint32_t sprite_count;
        uint32_t sprite_width;
        uint32_t sprite_height;
        const uint8_t *const *buffers;
        bool pixel_art;
    };

    texture_set *rd_create_texture_set(device *dev, const texture_set_params *params);
    void rd_free_texture_set(texture_set *set);

    void rd_get_texture_set_size(const texture_set *set, uint32_t *width, uint32_t *height);
    uint32_t rd_get_texture_set_count(const texture_set *set);
    bool rd_is_texture_set_streaming(const texture_set *set);
    bool rd_is_texture_set_pixel_art(const texture_set *set);
    bool rd_set_texture_set_pixel_art(texture_set *set, bool pa);

    texture *rd_get_texture(texture_set *set, uint32_t index);
    texture_set *rd_get_texture_set(texture *texture);
    void rd_update_texture(const uint8_t *data, size_t len);
]]

return ffi
