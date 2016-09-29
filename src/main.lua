local args = { ... }

if args[1] ~= "--skip-package-bs" then
    package.path = './src/?.lua;./src/?/init.lua'
end

local engine = require("engine")

local buildrd = table.findi(args, "--build-rd-header")
if buildrd then
    local ffi = require("engine.graphics.util.header_builder")
    ffi.rd_header.begin()
    require("engine.graphics.renderer")
    ffi.rd_header.finish()
    return
end

local build_bytecode = table.findi(args, "--build-bytecode")
if build_bytecode then
    local builder = require("engine.utility.bytecode_builder")
    builder.build()
    return
end

local build_moduledef = table.findi(args, "--build-module-def")
if build_moduledef then
    local builder = require("engine.graphics.util.module_def_builder")
    builder.build()
    return
end

local interactive = table.findi(args, "interactive")

if not interactive then
    engine.run()
end
