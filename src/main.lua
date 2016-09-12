local args = { ... }

package.path = './src/?.lua;./src/?/init.lua'
local engine = require("engine")

local interactive = table.findi(args, "interactive")

if not interactive then
    engine.run()
end
