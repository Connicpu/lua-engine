#include "pch.h"
#include "Device.h"
#include "Instance.h"
#include "Scene.h"
#include <memory>
#include <backends/common/baked_shaders.h>

static bool init_sprite_state(device * dev);

static com_ptr<IDXGIAdapter> find_adapter(const device *dev, const device_params *params)
{
    auto dxgi = dev->inst->dxgi_factory.p;

    bool use_adapter = false;
    com_ptr<IDXGIAdapter> adapter;
    for (UINT i = 0; dxgi->EnumAdapters(i, &adapter) == S_OK; ++i)
    {
        DXGI_ADAPTER_DESC adesc;
        adapter->GetDesc(&adesc);
        if (*(uint64_t *)&adesc.AdapterLuid == params->preferred_output)
        {
            use_adapter = true;
            break;
        }
    }

    if (!use_adapter)
    {
        adapter.Release();
        // Use adapter 0 by default
        HRESULT hr = dxgi->EnumAdapters(0, &adapter);
        if (FAILED(hr))
            return set_error_and_ret(nullptr, hr);
    }

    return adapter;
}

device *rd_create_device(const device_params *params)
{
    HRESULT hr;
    std::unique_ptr<device> dev(new device);

    auto inst = params->inst;
    dev->inst = inst;
    auto adapter = find_adapter(dev.get(), params);
    if (!adapter)
        return nullptr;

    auto driver_type = D3D_DRIVER_TYPE_UNKNOWN;
    UINT flags = D3D11_CREATE_DEVICE_BGRA_SUPPORT;
    if (params->enable_debug_mode)
        flags |= D3D11_CREATE_DEVICE_DEBUG;

    D3D_FEATURE_LEVEL feature_levels[] = { D3D_FEATURE_LEVEL_11_0 };
    D3D_FEATURE_LEVEL feature_level;

    hr = D3D11CreateDevice(
        adapter,
        driver_type,
        nullptr,
        flags,
        feature_levels,
        ARRAYSIZE(feature_levels),
        D3D11_SDK_VERSION,
        &dev->d3d_device,
        &feature_level,
        &dev->d3d_context
    );
    if (FAILED(hr))
        return set_error_and_ret(nullptr, hr);

    com_ptr<IDXGIDevice> dxgi_device;
    hr = dev->d3d_device->QueryInterface(&dxgi_device);
    if (FAILED(hr))
        return set_error_and_ret(nullptr, hr);

    hr = inst->d2d_factory->CreateDevice(
        dxgi_device,
        &dev->d2d_device
    );
    if (FAILED(hr))
        return set_error_and_ret(nullptr, hr);

    hr = dev->d2d_device->CreateDeviceContext(
        D2D1_DEVICE_CONTEXT_OPTIONS_ENABLE_MULTITHREADED_OPTIMIZATIONS,
        &dev->d2d_context
    );
    if (FAILED(hr))
        return set_error_and_ret(nullptr, hr);

    if (!init_sprite_state(dev.get()))
        return nullptr;

    return dev.release();
}

void rd_free_device(device *dev)
{
    delete dev;
}

template <typename T, typename V>
static D3D11_INPUT_ELEMENT_DESC elem_desc(
    UINT slot, V(T::*member), UINT semantic_multiplier,
    DXGI_FORMAT format, bool instance,
    const char *semantic, UINT semantic_index = 0
)
{
    union
    {
        V(T::*p);
        size_t len;
    } mem;
    mem.p = member;

    D3D11_INPUT_ELEMENT_DESC desc;
    desc.AlignedByteOffset = (UINT)mem.len + semantic_multiplier * semantic_index;
    desc.Format = format;
    desc.InputSlot = slot;
    desc.InputSlotClass = instance ? D3D11_INPUT_PER_INSTANCE_DATA : D3D11_INPUT_PER_VERTEX_DATA;
    desc.InstanceDataStepRate = instance ? 1 : 0;
    desc.SemanticIndex = semantic_index;
    desc.SemanticName = semantic;
    return desc;
}

template <typename T, typename V>
static D3D11_INPUT_ELEMENT_DESC elem_desc(
    UINT slot, V(T::*member),
    DXGI_FORMAT format, bool instance,
    const char *semantic, UINT semantic_index = 0
)
{
    return elem_desc(slot, member, 0, format, instance, semantic, semantic_index);
}

static bool init_shaders(device * dev)
{
    HRESULT hr;
    D3D11_INPUT_ELEMENT_DESC sprite_input_desc[] =
    {
        elem_desc(0, &sprite_vertex::pos, DXGI_FORMAT_R32G32_FLOAT, false, "POSITION"),
        elem_desc(0, &sprite_vertex::tex, DXGI_FORMAT_R32G32_FLOAT, false, "TEXCOORD", 0),

        elem_desc(1, &sprite_instance::transform, 8, DXGI_FORMAT_R32G32_FLOAT,       true, "TRANSFORM", 0),
        elem_desc(1, &sprite_instance::transform, 8, DXGI_FORMAT_R32G32_FLOAT,       true, "TRANSFORM", 1),
        elem_desc(1, &sprite_instance::transform, 8, DXGI_FORMAT_R32G32_FLOAT,       true, "TRANSFORM", 2),
        elem_desc(1, &sprite_instance::tint,         DXGI_FORMAT_R32G32B32A32_FLOAT, true, "COLOR"),
        elem_desc(1, &sprite_instance::uv0,          DXGI_FORMAT_R32G32_FLOAT,       true, "TEXCOORD", 1),
        elem_desc(1, &sprite_instance::uv1,          DXGI_FORMAT_R32G32_FLOAT,       true, "TEXCOORD", 2),
        elem_desc(1, &sprite_instance::layer,        DXGI_FORMAT_R32_FLOAT,          true, "LAYER"),
        elem_desc(1, &sprite_instance::texture_id,   DXGI_FORMAT_R32_UINT,           true, "TEXTURE_ID"),
    };

    auto &vs = baked_shaders["sprite.vs.hlsl"];
    auto &ps = baked_shaders["sprite.ps.hlsl"];

    hr = dev->d3d_device->CreateInputLayout(
        sprite_input_desc, ARRAYSIZE(sprite_input_desc),
        vs.data(), vs.size(), &dev->sprite_il
    );
    if (FAILED(hr))
        return append_error_and_ret(set_error_and_ret(false, hr), "Failed to create InputLayout");

    hr = dev->d3d_device->CreateVertexShader(
        vs.data(), vs.size(), nullptr, &dev->sprite_vs
    );
    if (FAILED(hr))
        return append_error_and_ret(set_error_and_ret(false, hr), "Failed to create VertexShader");

    hr = dev->d3d_device->CreatePixelShader(
        ps.data(), ps.size(), nullptr, &dev->sprite_ps
    );
    if (FAILED(hr))
        return append_error_and_ret(set_error_and_ret(false, hr), "Failed to create PixelShader");

    return true;
}

static bool init_samplers(device * dev)
{
    HRESULT hr;
    D3D11_SAMPLER_DESC desc;
    desc.Filter = D3D11_FILTER_ANISOTROPIC;
    desc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
    desc.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
    desc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
    desc.MipLODBias = 0;
    desc.MaxAnisotropy = 8;
    desc.MinLOD = -FLT_MAX;
    desc.MaxLOD = FLT_MAX;
    desc.ComparisonFunc = D3D11_COMPARISON_NEVER;
    *(color *)desc.BorderColor = color{ 0, 0, 0, 1 };

    hr = dev->d3d_device->CreateSamplerState(&desc, &dev->standard_sampler);
    if (FAILED(hr))
        return append_error_and_ret(set_error_and_ret(false, hr), "Failed to create texture sampler");

    desc.Filter = D3D11_FILTER_MIN_MAG_MIP_POINT;

    hr = dev->d3d_device->CreateSamplerState(&desc, &dev->pixelart_sampler);
    if (FAILED(hr))
        return append_error_and_ret(set_error_and_ret(false, hr), "Failed to create texture sampler");

    return true;
}

static bool init_blend(device * dev)
{
    HRESULT hr;
    D3D11_BLEND_DESC desc;
    desc.AlphaToCoverageEnable = TRUE;
    desc.IndependentBlendEnable = FALSE;
    desc.RenderTarget[0].BlendEnable = TRUE;
    desc.RenderTarget[0].SrcBlend = D3D11_BLEND_SRC_ALPHA;
    desc.RenderTarget[0].DestBlend = D3D11_BLEND_INV_SRC_ALPHA;
    desc.RenderTarget[0].BlendOp = D3D11_BLEND_OP_ADD;
    desc.RenderTarget[0].SrcBlendAlpha = D3D11_BLEND_SRC_ALPHA;
    desc.RenderTarget[0].DestBlendAlpha = D3D11_BLEND_DEST_ALPHA;
    desc.RenderTarget[0].BlendOpAlpha = D3D11_BLEND_OP_ADD;
    desc.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL;

    hr = dev->d3d_device->CreateBlendState(&desc, &dev->alpha_blend);
    if (FAILED(hr))
        return append_error_and_ret(set_error_and_ret(false, hr), "Failed to create blend state");

    return true;
}

static bool init_raster(device * dev)
{
    HRESULT hr;
    D3D11_RASTERIZER_DESC desc;
    desc.FillMode = D3D11_FILL_SOLID;
    desc.CullMode = D3D11_CULL_NONE;
    desc.FrontCounterClockwise = true;
    desc.DepthBias = 0;
    desc.DepthBiasClamp = 0.0f;
    desc.SlopeScaledDepthBias = 0.0f;
    desc.DepthClipEnable = false;
    desc.ScissorEnable = false;
    desc.MultisampleEnable = true;
    desc.AntialiasedLineEnable = true;

    hr = dev->d3d_device->CreateRasterizerState(&desc, &dev->rasterizer);
    if (FAILED(hr))
        return append_error_and_ret(set_error_and_ret(false, hr), "Failed to create rasterizer");

    return true;
}

static bool init_sprite_quad(device * dev)
{
    static const sprite_vertex vertices[] =
    {
        { vec2{ -0.5f, 0.5f }, vec2{ 0, 0 } },
        { vec2{ -0.5f, -0.5f }, vec2{ 0, 1 } },
        { vec2{ 0.5f, -0.5f }, vec2{ 1, 1 } },

        { vec2{ -0.5f, 0.5f }, vec2{ 0, 0 } },
        { vec2{ 0.5f, -0.5f }, vec2{ 1, 1 } },
        { vec2{ 0.5f, 0.5f }, vec2{ 1, 0 } },
    };

    HRESULT hr;
    D3D11_BUFFER_DESC desc;
    desc.BindFlags = D3D11_BIND_VERTEX_BUFFER;
    desc.ByteWidth = sizeof(vertices);
    desc.CPUAccessFlags = 0;
    desc.MiscFlags = 0;
    desc.StructureByteStride = sizeof(sprite_vertex);
    desc.Usage = D3D11_USAGE_IMMUTABLE;

    D3D11_SUBRESOURCE_DATA subres = { 0 };
    subres.pSysMem = vertices;

    hr = dev->d3d_device->CreateBuffer(&desc, &subres, &dev->sprite_quad);
    if (FAILED(hr))
        return append_error_and_ret(set_error_and_ret(false, hr), "Failed to create sprite quad");

    return true;
}

static bool init_sprite_state(device * dev)
{
    return
        init_shaders(dev) &&
        init_samplers(dev) &&
        init_blend(dev) &&
        init_raster(dev) &&
        init_sprite_quad(dev);
}
