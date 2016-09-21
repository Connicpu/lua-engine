workspace "lua-engine"
    objdir "obj/%{cfg.system}/%{prj.name}/%{cfg.platform}/%{cfg.buildcfg}"
    targetdir "bin/%{cfg.system}/%{cfg.platform}/%{cfg.buildcfg}"
    pic "On"

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
        Source = { "**.cpp", "**.c", "**.m", "**.mm" },
        Utility = { "**.def", "**.manifest" }
    }

filter "configurations:Debug"
    defines { "DEBUG" }
    flags { "Symbols" }

filter "configurations:Release"
    defines { "NDEBUG" }
    optimize "On"

filter "action:vs*"
    defines { "NOMINMAX", "WIN32_LEAN_AND_MEAN" }
    characterset "MBCS"

filter "not action:vs*"
    toolset "clang"
    buildoptions { "-std=c++14" }

---------------------------------------
-- Windows

project "launcher"
    kind "WindowedApp"
    language "C++"

    files {
        "src/launcher/*.h",
        "src/launcher/*.cpp",
        "src/launcher/*.manifest"
    }

    filter "action:vs*"
        linkoptions { "/manifestinput:src/launcher/app.manifest" }

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
        pchheader "pch.h"
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

        pchheader "pch.h"
        pchsource "src/backends/dx11/pch.cpp"
end

if os.is("macosx") then
    project "rd-metal"
        kind "SharedLib"
        language "C++"

        files {
            "src/backends/metal/*.h",
            "src/backends/metal/*.cpp",
            "src/backends/metal/*.mm",
            "src/backends/metal/*.m"
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
            pchheader "pch.h"
            pchsource "src/backends/vulkan/pch.cpp"
end
