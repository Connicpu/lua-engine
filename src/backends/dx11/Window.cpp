#include "pch.h"
#include "Window.h"
#include "Instance.h"
#include <VersionHelpers.h>
#include <ShellScalingAPI.h>
#include <algorithm>

size_t rd_get_outputs(instance * inst, size_t len, adapter_output * outputs)
{
    size_t count = 0;
    auto dxgi = inst->dxgi_factory.p;
    ComPtr<IDXGIAdapter> adapter;
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

window * rd_create_window(device * device, const window_params * params)
{
    return nullptr;
}

void rd_free_window(window * win)
{
}

render_target * rd_get_window_target(window * win)
{
    return nullptr;
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
