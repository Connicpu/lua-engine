#include "pch.h"
#include "Instance.h"
#include <memory>
#include <backends/common/SceneGraph2d.h>

extern "C" instance *rd_create_instance()
{
    HRESULT hr;
    std::unique_ptr<instance> inst(new instance);

    // Give us a DXGI factory for querying adapters
    hr = CreateDXGIFactory1(IID_PPV_ARGS(&inst->dxgi_factory));
    if (FAILED(hr))
        return set_error_and_ret(nullptr, hr);

    // Text rendering
    hr = DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, IID_PPV_ARGS_IUNK(&inst->dwrite_factory));
    if (FAILED(hr))
        return set_error_and_ret(nullptr, hr);

    // We're using D2D1 as our implementation of text rendering
    hr = D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &inst->d2d_factory);
    if (FAILED(hr))
        return set_error_and_ret(nullptr, hr);

    return inst.release();
}

extern "C" void rd_free_instance(instance *inst)
{
    delete inst;
}
