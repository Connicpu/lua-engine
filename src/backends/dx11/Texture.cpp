#include "pch.h"
#include "Texture.h"

texture_set * rd_create_texture_set(device * dev, const texture_set_params * params)
{
    return nullptr;
}

void rd_free_texture_set(texture_set * set)
{
}

void rd_get_texture_set_size(const texture_set * set, uint32_t * width, uint32_t * height)
{
}

uint32_t rd_get_texture_set_count(const texture_set * set)
{
    return uint32_t();
}

bool rd_is_texture_set_streaming(const texture_set * set)
{
    return false;
}

bool rd_is_texture_set_pixel_art(const texture_set * set)
{
    return false;
}

bool rd_set_texture_set_pixel_art(texture_set * set, bool pa)
{
    return false;
}

texture * rd_get_texture(texture_set * set, uint32_t index)
{
    return nullptr;
}

texture_set * rd_get_texture_set(texture * texture)
{
    return nullptr;
}

void rd_update_texture(const uint8_t * data, size_t len)
{
}
