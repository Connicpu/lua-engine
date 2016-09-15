workspace "CnnrEngine"
    toolset "clang"
    buildoptions { "-std=c++1z" }
    objdir "obj/%{cfg.system}/%{prj.name}/%{cfg.platform}/%{cfg.buildcfg}"
    targetdir "bin/%{cfg.system}/%{cfg.platform}/%{cfg.buildcfg}"
    pic "On"

    libdirs {
        "$(CONNORLIB_HOME)/bin/%{cfg.system}/%{cfg.platform}"
    }
    includedirs {
        "$(CONNORLIB_HOME)/include"
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

if os.is("windows") then
    project "rd-dx11"
        kind "SharedLib"
        language "C++"



        files {
            "src/backends/dx11/*.h",
            "src/backends/dx11/*.cpp"
        }
        links {
            "AssetPipeline",
            "LuaInterface",
            "serialization",
            "imageload",
            "messageipc"
        }

end

if os.is("macosx") then
    project "rd-metal"

end

if not os.is("macosx") then
    project "rd-vulkan"

end
