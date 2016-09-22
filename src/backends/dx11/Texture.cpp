#include "pch.h"
#include "Texture.h"

texture_array * rd_create_texture_array(device * dev, const texture_array_params * params)
{
    return nullptr;
}

void rd_free_texture_array(texture_array * set)
{
}

void rd_get_texture_array_size(const texture_array * set, uint32_t * width, uint32_t * height)
{
}

uint32_t rd_get_texture_array_count(const texture_array * set)
{
    return uint32_t();
}

bool rd_is_texture_array_streaming(const texture_array * set)
{
    return false;
}

bool rd_is_texture_array_pixel_art(const texture_array * set)
{
    return false;
}

bool rd_set_texture_array_pixel_art(texture_array * set, bool pa)
{
    return false;
}

texture * rd_get_texture(texture_array * set, uint32_t index)
{
    return nullptr;
}

texture_array * rd_get_texture_array(texture * texture)
{
    return nullptr;
}

void rd_update_texture(const uint8_t * data, size_t len)
{
}
