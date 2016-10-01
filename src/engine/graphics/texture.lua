local ffi = require("engine.graphics.renderer")
local rd_err = require("engine.graphics.error")

local C = ffi.C
local check_ptr = rd_err.check_ptr
local ffi_new = ffi.new
local ffi_cast = ffi.cast
local ffi_gc = ffi.gc
local ffi_string = ffi.string

local tparams = ffi.typeof("struct texture_array_params")

local TextureArray_t = ffi.typeof("struct{texture_array *tary;}")
local TextureArray = {}
local TextureArray_mt = { __index = TextureArray }
local TextureArray_ct

local Texture_t = ffi.typeof("struct{texture *tex;}")
local Texture = {}
local Texture_mt = { __index = Texture }
local Texture_ct

function TextureArray.build_placeholder(colors, device)
    device = device or colors.device
    local height = #colors
    local width = #colors[1]
    local buffer = ffi_cast("uint8_t(*)[4]", C.malloc(width * height * 4))
    local buffers = ffi_new("const uint8_t *[1]", buffer[0])

    for i, row in ipairs(colors) do
        for j, color in ipairs(row) do
            local idx = (i - 1) * width + j - 1
            buffer[idx][0] = color.r * 255
            buffer[idx][1] = color.g * 255
            buffer[idx][2] = color.b * 255
            buffer[idx][3] = color.a * 255
        end
    end
    
    local params = ffi_new(tparams)
    params.streaming = false
    params.sprite_count = 1
    params.sprite_width = width
    params.sprite_height = height
    params.buffers = buffers
    params.pixel_art = true

    return TextureArray_ct(device, params)
end

function TextureArray_mt.__new(tp, dev, params)
    local tary = check_ptr(__rd.rd_create_texture_array(dev.dev, params))
    return ffi_new(tp, tary)
end

function TextureArray_mt:__gc()
    self:destroy()
end

function TextureArray:destroy()
    if self.tary ~= nil then
        __rd.rd_free_texture_array(self.tary)
        self.tary = nil
    end
end

function TextureArray:get(i)
    local tex = check_ptr(__rd.rd_get_texture(self.tary, i))
    return Texture_ct(tex)
end

TextureArray_ct = ffi.metatype(TextureArray_t, TextureArray_mt)
Texture_ct = ffi.metatype(Texture_t, Texture_mt)

return {
    TextureArray = TextureArray,
}
