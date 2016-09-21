#include "pch.h"
#include "Device.h"
#include "Instance.h"
#include <memory>

static ComPtr<IDXGIAdapter> find_adapter(const device *dev, const device_params *params)
{
    auto dxgi = dev->inst->dxgi_factory.p;

    bool use_adapter = false;
    ComPtr<IDXGIAdapter> adapter;
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

    D3D_FEATURE_LEVEL feature_levels[] = { D3D_FEATURE_LEVEL_10_1 };
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

    ComPtr<IDXGIDevice> dxgi_device;
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

    return dev.release();
}

void rd_free_device(device *dev)
{
    delete dev;
}
