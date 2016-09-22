#include "pch.h"
#include "Scene.h"

scene * rd_create_scene(device * device, float grid_width, float grid_height)
{
    return nullptr;
}

void rd_free_scene(scene * scene)
{
}

void rd_draw_scene(device * dev, scene * scene, camera * cam)
{
}

sprite_handle rd_create_sprite(scene * scene, sprite_params * params)
{
    return sprite_handle();
}

void rd_destroy_sprite(scene * scene, sprite_handle sprite)
{
}

void rd_get_sprite_uv(scene * scene, sprite_handle sprite, vec2 * topleft, vec2 * topright)
{
}

void rd_set_sprite_uv(scene * scene, sprite_handle sprite, const vec2 * topleft, const vec2 * topright)
{
}

float rd_get_sprite_layer(scene * scene, sprite_handle sprite)
{
    return 0.0f;
}

void rd_set_sprite_layer(scene * scene, sprite_handle sprite, float layer)
{
}

texture * rd_get_sprite_texture(scene * scene, sprite_handle sprite)
{
    return nullptr;
}

void rd_set_sprite_texture(scene * scene, sprite_handle sprite, texture * tex)
{
}

void rd_get_sprite_transform(scene * scene, sprite_handle sprite, matrix2d * transform)
{
}

void rd_set_sprite_transform(scene * scene, sprite_handle sprite, const matrix2d * transform)
{
}

void rd_get_sprite_tint(scene * scene, sprite_handle sprite, color * tint)
{
}

void rd_set_sprite_tint(scene * scene, sprite_handle sprite, const color * tint)
{
}
