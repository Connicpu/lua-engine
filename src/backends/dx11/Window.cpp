#include "pch.h"
#include "Window.h"
#include "Instance.h"
#include "Device.h"
#include <VersionHelpers.h>
#include <ShellScalingAPI.h>
#include <algorithm>

static bool init_back_buffer(device * dev, window * win);

size_t rd_get_outputs(instance * inst, size_t len, adapter_output * outputs)
{
    size_t count = 0;
    auto dxgi = inst->dxgi_factory.p;
    com_ptr<IDXGIAdapter> adapter;
    for (UINT i = 0; dxgi->EnumAdapters(i, &adapter) == S_OK; ++i, ++count)
    {
        if (outputs && i < len)
        {
            DXGI_ADAPTER_DESC desc;
            adapter->GetDesc(&desc);

            outputs[i].process_index = i;
            outputs[i].id = *(uint64_t *)&desc.AdapterLuid;
            outputs[i].device_memory = desc.DedicatedVideoMemory;
            outputs[i].system_memory = desc.SharedSystemMemory;
            
            auto name = narrow(desc.Description);
            auto name_len = std::min(ARRAYSIZE(outputs[i].device_name) - 1, name.length());
            memcpy(outputs[i].device_name, name.c_str(), name_len);
            outputs[i].device_name[name_len] = 0;
        }

        adapter.Release();
    }
    return count;
}

window * rd_create_window(device * dev, const window_params * params)
{
    std::unique_ptr<window> win(new window);

    win->handler.assign(rd_create_wh(params), rd_free_wh);
    win->hwnd = (HWND)rd_get_wh_platform_handle(win->handler.get());

    if (!init_back_buffer(dev, win.get()))
        return nullptr;

    return win.release();
}

void rd_free_window(window * win)
{
    delete win;
}

bool rd_set_window_state(window * win, window_state state)
{
    if (state == win->state)
        return true;

    if (!rd_set_wh_state(win->handler, state))
        return false;

    HRESULT hr;

    if (state == windowed)
    {
        if (win->state == fullscreen)
        {
            hr = win->swap_chain->SetFullscreenState(false, nullptr);
            if (FAILED(hr))
                return set_error_and_ret(false, hr);
        }
    }
    else if (state == borderless)
    {
        if (win->state == fullscreen)
        {
            hr = win->swap_chain->SetFullscreenState(false, nullptr);
            if (FAILED(hr))
                return set_error_and_ret(false, hr);
        }
    }
    else if (state == fullscreen)
    {
        hr = win->swap_chain->SetFullscreenState(true, nullptr);
        if (FAILED(hr))
            return set_error_and_ret(false, hr);
    }
    else unreachable();

    win->state = state;
    return true;
}

render_target * rd_get_window_target(window * win)
{
    return &win->back_buffer;
}

void rd_get_window_dpi(window * win, float * dpix, float * dpiy)
{
    UINT dx, dy;
    if (IsWindows8Point1OrGreater())
    {
        static HMODULE shcore = LoadLibraryA("SHCore.dll");
        static auto GetDpi = LOAD_PFN(shcore, GetDpiForMonitor);

        HMONITOR mon = MonitorFromWindow(win->hwnd, MONITOR_DEFAULTTOPRIMARY);
        GetDpi(mon, MDT_EFFECTIVE_DPI, &dx, &dy);
    }
    else
    {
        HDC desktop = GetDC(nullptr);
        dx = (UINT)GetDeviceCaps(desktop, LOGPIXELSX);
        dy = (UINT)GetDeviceCaps(desktop, LOGPIXELSY);
    }

    *dpix = dx / 96.f;
    *dpiy = dy / 96.f;
}

bool rd_prepare_window_for_drawing(device * dev, window * win)
{
    if (rd_check_dirty_buffers(win->handler))
    {
        if (!init_back_buffer(dev, win))
            return append_error_and_ret("Error while recreating swap chain");
    }

    return true;
}

int rd_present_window(window * win)
{
    HRESULT hr;
    hr = win->swap_chain->Present(0, 0);
    if (hr == DXGI_STATUS_OCCLUDED)
        return 1;
    else if (FAILED(hr))
        return set_error_and_ret(-1, hr);

    return 0;
}

bool rd_test_window_occlusion(window * win)
{
    HRESULT hr;
    hr = win->swap_chain->Present(0, DXGI_PRESENT_TEST);
    return hr != DXGI_STATUS_OCCLUDED;
}

static bool init_back_buffer(device * dev, window * win)
{
    auto &swap = win->swap_chain;
    auto &bb = win->back_buffer;

    bb.buffer.Release();
    bb.rtv.Release();
    bb.surface.Release();
    swap.Release();

    RECT rect;
    GetClientRect(win->hwnd, &rect);

    UINT width = UINT(rect.right - rect.left);
    UINT height = UINT(rect.bottom - rect.top);

    HRESULT hr;
    DXGI_SWAP_CHAIN_DESC1 desc;
    desc.Width = width;
    desc.Height = height;
    desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    desc.Stereo = false;
    desc.SampleDesc = { 1, 0 };
    desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    desc.BufferCount = 16;
    desc.Scaling = DXGI_SCALING_STRETCH;
    desc.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
    desc.AlphaMode = DXGI_ALPHA_MODE_IGNORE;
    desc.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;

    DXGI_SWAP_CHAIN_FULLSCREEN_DESC full_desc;
    full_desc.RefreshRate = { 60, 1 };
    full_desc.Scaling = DXGI_MODE_SCALING_UNSPECIFIED;
    full_desc.ScanlineOrdering = DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED;
    full_desc.Windowed = (win->state != fullscreen);

    hr = dev->inst->dxgi_factory->CreateSwapChainForHwnd(
        dev->d3d_device,
        win->hwnd,
        &desc,
        &full_desc,
        nullptr,
        &swap
    );
    if (FAILED(hr))
        return set_error_and_ret(hr);

    hr = swap->GetBuffer(0, IID_PPV_ARGS(&bb.buffer));
    if (FAILED(hr))
        return set_error_and_ret(hr);

    D3D11_RENDER_TARGET_VIEW_DESC rtv_desc;
    rtv_desc.ViewDimension = D3D11_RTV_DIMENSION_TEXTURE2D;
    rtv_desc.Format = desc.Format;
    rtv_desc.Texture2D.MipSlice = 0;

    hr = dev->d3d_device->CreateRenderTargetView(
        bb.buffer,
        &rtv_desc,
        &bb.rtv
    );

    if (!rd_init_depth_buffer(dev, &win->back_buffer.depth, win->back_buffer.buffer))
        return set_error_and_ret("Error while initializing depth buffer");

    return true;
}
