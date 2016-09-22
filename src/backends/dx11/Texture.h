#pragma once

#include "platform.h"
#include <vector>

struct texture
{
    texture_array *array;
    uint32_t index;
};

struct texture_array
{
    virtual ~texture_array() {}

    bool streaming;
    bool pixel_art;
    ComPtr<ID3D11Texture2D> buffer;
    ComPtr<ID3D11ShaderResourceView> srv;
    std::vector<texture> textures;
};

extern "C" texture_array *rd_create_texture_array(device *dev, const texture_array_params *params);
extern "C" void rd_free_texture_array(texture_array *set);

extern "C" void rd_get_texture_array_size(const texture_array *set, uint32_t *width, uint32_t *height);
extern "C" uint32_t rd_get_texture_array_count(const texture_array *set);
extern "C" bool rd_is_texture_array_streaming(const texture_array *set);
extern "C" bool rd_is_texture_array_pixel_art(const texture_array *set);
extern "C" bool rd_set_texture_array_pixel_art(texture_array *set, bool pa);

extern "C" texture *rd_get_texture(texture_array *set, uint32_t index);
extern "C" texture_array *rd_get_texture_array(texture *texture);
extern "C" void rd_update_texture(const uint8_t *data, size_t len);
