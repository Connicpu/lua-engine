#pragma once
#include <backends/common/renderer.h>
#include "platform.h"

struct device
{
    instance *inst;
    
    com_ptr<ID3D11Device> d3d_device;
    com_ptr<ID3D11DeviceContext> d3d_context;
    com_ptr<ID2D1Device> d2d_device;
    com_ptr<ID2D1DeviceContext> d2d_context;

    com_ptr<ID3D11VertexShader> sprite_vs;
    com_ptr<ID3D11PixelShader> sprite_ps;
    com_ptr<ID3D11InputLayout> sprite_il;
    com_ptr<ID3D11Buffer> sprite_quad;
    
    com_ptr<ID3D11RasterizerState> rasterizer;
    com_ptr<ID3D11BlendState> alpha_blend;
    com_ptr<ID3D11SamplerState> standard_sampler;
    com_ptr<ID3D11SamplerState> pixelart_sampler;
};

device *rd_create_device(const device_params *params);
void rd_free_device(device *dev);

