#include "pch.h"
#include "Texture.h"
#include "Device.h"

texture_array * rd_create_texture_array(device * dev, const texture_array_params * params)
{
    HRESULT hr;
    D3D11_SUBRESOURCE_DATA *initial_data = nullptr;
    std::vector<D3D11_SUBRESOURCE_DATA> subresources;
    std::unique_ptr<texture_array> tary{ new texture_array };

    tary->streaming = params->streaming;
    tary->pixel_art = params->pixel_art;
    tary->width = params->sprite_width;
    tary->height = params->sprite_height;

    tary->textures.reserve(params->sprite_count);
    for (uint32_t i = 0; i < params->sprite_count; ++i)
    {
        texture tex;
        tex.array = tary.get();
        tex.index = i;
        tary->textures.push_back(tex);
    }

    if (params->buffers)
    {
        subresources.reserve(params->sprite_count);
        for (uint32_t i = 0; i < params->sprite_count; ++i)
        {
            D3D11_SUBRESOURCE_DATA subres;
            subres.pSysMem = params->buffers[i];
            subres.SysMemPitch = params->sprite_width * 4;
            subres.SysMemSlicePitch = 0;
            subresources.push_back(subres);
        }
        initial_data = subresources.data();
    }

    D3D11_TEXTURE2D_DESC desc;
    desc.ArraySize = params->sprite_count;
    desc.BindFlags = D3D11_BIND_SHADER_RESOURCE;
    desc.CPUAccessFlags = params->streaming ? D3D11_CPU_ACCESS_WRITE : 0;
    desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    desc.Width = params->sprite_width;
    desc.Height = params->sprite_height;
    desc.MiscFlags = 0;
    desc.MipLevels = 1;
    desc.SampleDesc = { 1, 0 };
    desc.Usage = params->streaming ? D3D11_USAGE_DYNAMIC : D3D11_USAGE_DEFAULT;
    hr = dev->d3d_device->CreateTexture2D(&desc, initial_data, &tary->buffer);
    if (FAILED(hr))
        return append_error_and_ret(set_error_and_ret(hr), "Failed to create Texture2D");

    D3D11_SHADER_RESOURCE_VIEW_DESC srvdesc;
    srvdesc.Format = desc.Format;
    srvdesc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2DARRAY;
    srvdesc.Texture2DArray.ArraySize = desc.ArraySize;
    srvdesc.Texture2DArray.FirstArraySlice = 0;
    srvdesc.Texture2DArray.MipLevels = 1;
    srvdesc.Texture2DArray.MostDetailedMip = 0;
    hr = dev->d3d_device->CreateShaderResourceView(tary->buffer, &srvdesc, &tary->srv);
    if (FAILED(hr))
        return append_error_and_ret(set_error_and_ret(hr), "Failed to create ShaderResourceView");

    return tary.release();
}

void rd_free_texture_array(texture_array * set)
{
    delete set;
}

void rd_get_texture_array_size(const texture_array * set, uint32_t * width, uint32_t * height)
{
    *width = set->width;
    *height = set->height;
}

uint32_t rd_get_texture_array_count(const texture_array * set)
{
    return (uint32_t)set->textures.size();
}

bool rd_is_texture_array_streaming(const texture_array * set)
{
    return set->streaming;
}

bool rd_is_texture_array_pixel_art(const texture_array * set)
{
    return set->pixel_art;
}

void rd_set_texture_array_pixel_art(texture_array * set, bool pa)
{
    set->pixel_art = pa;
}

texture * rd_get_texture(texture_array * set, uint32_t index)
{
    if (index >= set->textures.size())
        return set_error_and_ret("Index out of bounds");

    return &set->textures[index];
}

texture_array * rd_get_texture_array(texture * texture)
{
    return texture->array;
}

bool rd_update_texture(device *dev, texture *texture, const uint8_t *data, size_t len)
{
    auto ary = texture->array;
    if (len != ary->width * ary->height * 4)
        return set_error_and_ret(false, "Wrong buffer size for updating a texture");

    if (ary->streaming)
    {
        HRESULT hr;
        D3D11_MAPPED_SUBRESOURCE subres;
        hr = dev->d3d_context->Map(ary->buffer, texture->index, D3D11_MAP_WRITE_DISCARD, 0, &subres);
        if (FAILED(hr))
            return set_error_and_ret(false, "Failed to map texture buffer");

        for (uint32_t y = 0; y < ary->height; ++y)
        {
            const uint8_t *in = &data[y * ary->width * 4];
            uint8_t *out = ((uint8_t *)subres.pData) + y * subres.RowPitch;

            memcpy(out, in, ary->width * 4);
        }

        dev->d3d_context->Unmap(ary->buffer, texture->index);
    }
    else
    {
        D3D11_BOX box;
        box.front = 0;
        box.left = 0;
        box.top = 0;
        box.back = 1;
        box.right = ary->width;
        box.bottom = ary->height;
        dev->d3d_context->UpdateSubresource(
            ary->buffer,
            texture->index,
            &box,
            data,
            ary->width * 4,
            0
        );
    }

    return true;
}
