#include "pch.h"
#include "Scene.h"
#include "Device.h"
#include "RenderTarget.h"
#include "Camera.h"

scene * rd_create_scene(device * , float grid_width, float grid_height)
{
    return new scene(vec2{ grid_width, grid_height });
}

void rd_free_scene(scene * scene)
{
    delete scene;
}

using namespace sg_details;
using batch_state = decltype(scene::graph)::batch_state;

static bool bind_state(device *dev, render_target *rt, camera *cam, const viewport *vp);
static void bind_sampler(device *dev);
static void bind_texture(device *dev, texture_array *array);
static void bind_instance(device *dev, const InstanceBuffer<sprite_instance> &instance);
static void draw_sprites(device *dev, uint32_t count);
static thread_local bool was_pixel = false;

template <typename Cont>
void draw_batch(device *dev, const Cont *cont)
{
    if (cont)
    {
        for (auto &pair : *cont)
        {
            bind_texture(dev, pair.first);
            bind_instance(dev, pair.second);
            draw_sprites(dev, pair.second.count());
        }
    }
}

bool rd_draw_scene(device * dev, render_target *rt, scene * scene, camera * cam, const viewport * vp)
{
    if (!scene->graph.prepare_rendering(dev, cam))
        return append_error_and_ret(false, "Error while prepaing scene for drawing");

    if (!bind_state(dev, rt, cam, vp))
        return false;

    bind_sampler(dev);

    for (const coord &c : scene->graph.to_be_rendered())
    {
        batch_state batch;
        if (!scene->graph.get_batch_state(c, batch))
            continue;

        draw_batch(dev, batch.standard);
        draw_batch(dev, batch.statics);
        draw_batch(dev, batch.translucents);
    }

    return true;
}

bool bind_state(device *dev, render_target *rt, camera *cam, const viewport *vp)
{
    static const UINT strides[] = { sizeof(sprite_vertex) };
    static const UINT offsets[] = { 0 };

    D3D11_VIEWPORT view;
    view.TopLeftX = vp->x;
    view.TopLeftY = vp->y;
    view.Width = vp->w;
    view.Height = vp->h;
    view.MinDepth = 0;
    view.MaxDepth = 1;

    if (!rd_upload_camera(dev, cam))
        return append_error_and_ret(false, "Failed to upload camera data");

    dev->d3d_context->OMSetRenderTargets(1, &rt->rtv.p, rt->depth.dsv);
    dev->d3d_context->OMSetBlendState(dev->alpha_blend, nullptr, 0xFFFFFF);
    dev->d3d_context->RSSetState(dev->rasterizer);
    dev->d3d_context->RSSetViewports(1, &view);
    dev->d3d_context->VSSetShader(dev->sprite_vs, nullptr, 0);
    dev->d3d_context->PSSetShader(dev->sprite_ps, nullptr, 0);
    dev->d3d_context->VSSetConstantBuffers(0, 1, cam->cam_buffer.addr());
    dev->d3d_context->IASetInputLayout(dev->sprite_il);
    dev->d3d_context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    dev->d3d_context->IASetVertexBuffers(0, 1, &dev->sprite_quad.p, strides, offsets);

    return true;
}

void bind_sampler(device * dev)
{
    if (was_pixel)
    {
        dev->d3d_context->PSSetSamplers(0, 1, &dev->pixelart_sampler.p);
    }
    else
    {
        dev->d3d_context->PSSetSamplers(0, 1, &dev->standard_sampler.p);
    }
}

void bind_texture(device * dev, texture_array * array)
{
    if (was_pixel != array->pixel_art)
    {
        was_pixel = array->pixel_art;
        bind_sampler(dev);
    }

    dev->d3d_context->PSSetShaderResources(0, 1, &array->srv.p);
}

void bind_instance(device * dev, const InstanceBuffer<sprite_instance> &instance)
{
    instance.bind(dev, 1);
}

void draw_sprites(device * dev, uint32_t count)
{
    dev->d3d_context->DrawInstanced(6, count, 0, 0);
}

sprite_handle rd_create_sprite(scene * scene, const sprite_params * params)
{
    return scene->graph.create_object(params);
}

void rd_destroy_sprite(scene * scene, sprite_handle sprite)
{
    scene->graph.destroy_object(sprite);
}

void rd_get_sprite_uv(scene *, sprite_handle sprite, vec2 * topleft, vec2 * bottomright)
{
    *topleft = sprite->uv0;
    *bottomright = sprite->uv1;
}

void rd_set_sprite_uv(scene * scene, sprite_handle sprite, const vec2 * topleft, const vec2 * bottomright)
{
    sprite->uv0 = *topleft;
    sprite->uv1 = *bottomright;
    scene->graph.updated_field(sprite);
}

float rd_get_sprite_layer(scene *, sprite_handle sprite)
{
    return sprite->layer;
}

void rd_set_sprite_layer(scene * scene, sprite_handle sprite, float layer)
{
    sprite->layer = layer;
    scene->graph.updated_layer(sprite);
}

texture * rd_get_sprite_texture(scene *, sprite_handle sprite)
{
    return sprite->tex;
}

void rd_set_sprite_texture(scene * scene, sprite_handle sprite, texture * tex)
{
    scene->graph.change_texture(sprite, tex);
}

void rd_get_sprite_transform(scene *, sprite_handle sprite, matrix2d * transform)
{
    *transform = sprite->transform;
}

void rd_set_sprite_transform(scene * scene, sprite_handle sprite, const matrix2d * transform)
{
    scene->graph.move_object(sprite, *transform);
}

void rd_get_sprite_tint(scene *, sprite_handle sprite, color * tint)
{
    *tint = sprite->tint;
}

void rd_set_sprite_tint(scene * scene, sprite_handle sprite, const color * tint)
{
    sprite->tint = *tint;
    scene->graph.updated_field(sprite);
}
