workspace "lua-engine"
    objdir "obj/%{cfg.system}/%{prj.name}/%{cfg.platform}/%{cfg.buildcfg}"
    targetdir "bin/%{cfg.system}/%{cfg.platform}/%{cfg.buildcfg}"
    pic "On"
    warnings "Extra"

    libdirs {
        --"$(CONNORLIB_HOME)/bin/%{cfg.system}/%{cfg.platform}",
        "vendor/bin/%{cfg.system}_%{cfg.platform}",
    }

    local includes = {
        "$(CONNORLIB_HOME)/include",
        "vendor/include",
        "src",
    }
    if os.is("macosx") then
        defines { "OBJC" }
        sysincludedirs(includes)
    else
        includedirs(includes)
    end

    configurations { "Debug", "Release", "Deploy" }

    if os.is("windows") then
        platforms { "x86", "x64" }
    else
        platforms { "x64" }
    end

    vpaths {
        Headers = "**.h",
        Source = { "**.cpp", "**.c", "**.m", "**.mm" },
        Utility = { "**.def", "**.manifest" },
        Shaders = { "**.hlsl", "**.vert", "**.frag" },
    }

    defines { "_USE_MATH_DEFINES" }

filter "configurations:Debug"
    defines { "DEBUG" }
    flags { "Symbols" }

filter "configurations:Release"
    defines { "NDEBUG" }
    flags { "Symbols" }
    optimize "On"

filter "configurations:Deploy"
    defines { "NDEBUG", "BAKED_CODE" }
    optimize "On"

filter "action:vs*"
    defines { "NOMINMAX", "WIN32_LEAN_AND_MEAN" }
    characterset "MBCS"
    postbuildcommands { "powershell -NoProfile -File build/windows/postbuild.ps1" }

filter "not action:vs*"
    toolset "clang"
    buildoptions { "-std=c++14" }
    if os.is("macosx") then
        buildoptions { "-fobjc-arc" }
        postbuildcommands { "build/macosx/postbuild.sh" }
    else
        postbuildcommands { "build/linux/postbuild.sh" }
    end

---------------------------------------
-- Launcher

project "launcher"
    kind "WindowedApp"
    language "C++"

    files {
        "src/launcher/*.h",
        "src/launcher/*.cpp"
    }

    filter "action:vs*"
        links { "lua51" }
    filter "not action:vs*"
        links { "luajit" } 

    -- Ensure building of the graphics libraries
    filter "system:windows"
        dependson "rd-dx11"
        
    filter "system:macosx"
        dependson "rd-metal"
        
    filter "not system:macosx"
        dependson "rd-vulkan"

    -- y tho, mike pall. pls explain.
    filter "system:macosx"
        linkoptions { "-pagezero_size 10000 -image_base 100000000" }

    filter "action:vs*"
        linkoptions {
            "/manifestinput:src/launcher/app.manifest",
            "/entry:WinMainCRTStartup",
        }
        files { "src/launcher/app.manifest" }

    filter "not action:vs*"
        removefiles { "src/launcher/winmain.cpp" }

---------------------------------------
-- Backends

local luajit
if os.is("windows") then
    luajit = [[%{wks.location}\vendor\bin\%{cfg.system}_%{cfg.platform}\luajit.exe]]
else
    luajit = "%{wks.location}/vendor/bin/%{cfg.system}_%{cfg.platform}/luajit"
end

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
    project "win32-handler"
        kind "StaticLib"
        language "C++"

        files {
            "src/backends/win32-handler/*.h",
            "src/backends/win32-handler/*.cpp",
        }
        
        pchheader "pch.h"
        pchsource "src/backends/win32-handler/pch.cpp"

    project "shaders-dx11"
        kind "Utility"
        files { "src/backends/shaders/dx11/*.hlsl" }
        prebuildcommands { luajit.." src/backends/shaders/build.lua dx11 %{cfg.objdir}" }
        dependson { "rd-common" }

    project "rd-dx11"
        kind "SharedLib"
        language "C++"

        dependson { "shaders-dx11" }
        files {
            "src/backends/dx11/*.h",
            "src/backends/dx11/*.cpp",
            "src/backends/dx11/*.def",
        }
        links {
            "dwrite",
            "dxgi",
            "d3d11",
            "d2d1",
            "rd-common",
            "win32-handler",
        }

        pchheader "pch.h"
        pchsource "src/backends/dx11/pch.cpp"
end

if os.is("macosx") then
    project "rd-metal"
        kind "SharedLib"
        language "C++"
        defines { "MACOS" }
        
        files {
            "src/backends/metal/*.h",
            "src/backends/metal/*.cpp",
            "src/backends/metal/*.mm",
            "src/backends/metal/*.m",
            "src/backends/metal/*.metal",
        }
        links {
            "rd-common",
            "Foundation.framework",
            "Metal.framework",
        }
end

if os.is("linux") then
    project "x11-handler"
        kind "StaticLib"
        language "C++"

        files {
            "src/backends/x11-handler/*.h",
            "src/backends/x11-handler/*.cpp",
        }
end

if not os.is("macosx") then
    project "shaders-vulkan"
        kind "Utility"
        files { "src/backends/shaders/vulkan/*.hlsl" }
        buildcommands { luajit.." src/backends/shaders/build.lua vulkan %{cfg.objdir}" }
        dependson { "rd-common" }

    project "rd-vulkan"
        kind "SharedLib"
        language "C++"

        dependson { "shaders-vulkan" }
        files {
            "src/backends/vulkan/*.h",
            "src/backends/vulkan/*.cpp"
        }
        links {
            "rd-common"
        }

        filter "system:windows"
            links { "win32-handler" }
        filter "system:linux"
            links { "x11-handler" }

        filter "action:vs*"
            files { "src/backends/vulkan/*.def" }
            pchheader "pch.h"
            pchsource "src/backends/vulkan/pch.cpp"
end


