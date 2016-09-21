#pragma once

#include <backends/common/renderer.h>

extern "C" texture_set *rd_create_texture_set(device *dev, const texture_set_params *params);
extern "C" void rd_free_texture_set(texture_set *set);

extern "C" void rd_get_texture_set_size(const texture_set *set, uint32_t *width, uint32_t *height);
extern "C" uint32_t rd_get_texture_set_count(const texture_set *set);
extern "C" bool rd_is_texture_set_streaming(const texture_set *set);
extern "C" bool rd_is_texture_set_pixel_art(const texture_set *set);
extern "C" bool rd_set_texture_set_pixel_art(texture_set *set, bool pa);

extern "C" texture *rd_get_texture(texture_set *set, uint32_t index);
extern "C" texture_set *rd_get_texture_set(texture *texture);
extern "C" void rd_update_texture(const uint8_t *data, size_t len);
