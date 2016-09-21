local args = { ... }

package.path = './src/?.lua;./src/?/init.lua'
local engine = require("engine")

local buildrd = table.findi(args, "--build-rd-header")
if buildrd then
    local ffi = require("engine.graphics.header_builder")
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

local interactive = table.findi(args, "interactive")

if not interactive then
    engine.run()
end
