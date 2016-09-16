workspace "CnnrEngine"
    toolset "clang"
    buildoptions { "-std=c++14" }
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

filter "configurations:Debug"
    defines { "DEBUG" }
    flags { "Symbols" }

filter "configurations:Release"
    defines { "NDEBUG" }
    optimize "On"

filter "action:vs*"
    pchheader "pch.h"
    pchsource "pch.cpp"

---------------------------------------
-- Backends

project "rd-common"
    kind "StaticLib"
    language "C++"

    files {
        "src/backends/common/*.h",
        "src/backends/common/*.cpp"
    }

if os.is("windows") then
    project "rd-dx11"
        kind "SharedLib"
        language "C++"

        files {
            "src/backends/dx11/*.h",
            "src/backends/dx11/*.cpp"
        }
        links {
            "rd-common"
        }
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
end
