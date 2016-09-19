workspace "lua-engine"
    objdir "obj/%{cfg.system}/%{prj.name}/%{cfg.platform}/%{cfg.buildcfg}"
    targetdir "bin/%{cfg.system}/%{cfg.platform}/%{cfg.buildcfg}"
    pic "On"

    libdirs { os.findlib("dxgi") }
    libdirs {
        "$(CONNORLIB_HOME)/bin/%{cfg.system}/%{cfg.platform}"
    }
    includedirs {
        "$(CONNORLIB_HOME)/include",
        "src"
    }

    configurations { "Debug", "Release" }
    platforms { "x86", "x64" }

    vpaths {
        Headers = "**.h",
        Source = { "**.cpp", "**.c", "**.m", "**.mm" }
    }

filter "configurations:Debug"
    defines { "DEBUG" }
    flags { "Symbols" }

filter "configurations:Release"
    defines { "NDEBUG" }
    optimize "On"

filter "action:vs*"
    pchheader "pch.h"
    defines { "NOMINMAX", "WIN32_LEAN_AND_MEAN", "VC_EXTRA_LEAN" }
    characterset "MBCS"

filter "not action:vs*"
    toolset "clang"
    buildoptions { "-std=c++14" }

---------------------------------------
-- Backends

project "rd-common"
    kind "StaticLib"
    language "C++"

    files {
        "src/backends/common/*.h",
        "src/backends/common/*.cpp"
    }

    filter "action:vs*"
        pchsource "src/backends/common/pch.cpp"

if os.is("windows") then
    project "rd-dx11"
        kind "SharedLib"
        language "C++"

        files {
            "src/backends/dx11/*.h",
            "src/backends/dx11/*.cpp",
            "src/backends/dx11/*.def"
        }
        links {
            "dwrite",
            "dxgi",
            "d3d11",
            "d2d1",
            "rd-common"
        }
        pchsource "src/backends/dx11/pch.cpp"
end

if os.is("macosx") then
    project "rd-metal"
        kind "SharedLib"
        language "C++"

        files {
            "src/backends/metal/*.h",
            "src/backends/metal/*.cpp"
        }
        links {
            "rd-common"
        }
end

if not os.is("macosx") then
    project "rd-vulkan"
        kind "SharedLib"
        language "C++"

        files {
            "src/backends/vulkan/*.h",
            "src/backends/vulkan/*.cpp"
        }
        links {
            "rd-common"
        }

        filter "action:vs*"
            files { "src/backends/vulkan/*.def" }
            pchsource "src/backends/vulkan/pch.cpp"
end
