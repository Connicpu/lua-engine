local ffi = require("ffi")

ffi.cdef[[
    struct color {
        float r, g, b, a;
    };
]]

local color_table
local color = {}
local color_mt = { __index = color }
local color_ct

function color.parse(str)
    if string.sub(str, 1, 1) == '#' then
        local r, g, b, a
        a = 1
        if #str == 4 then
            r = tonumber(string.sub(str, 2, 2), 16) / 15
            g = tonumber(string.sub(str, 3, 3), 16) / 15
            b = tonumber(string.sub(str, 4, 4), 16) / 15
        elseif #str == 7 or #str == 9 then
            r = tonumber(string.sub(str, 2, 3), 16) / 255
            g = tonumber(string.sub(str, 4, 5), 16) / 255
            b = tonumber(string.sub(str, 6, 7), 16) / 255
            if #str == 9 then
                a = tonumber(string.sub(str, 8, 9), 16) / 255
            end
        else
            return nil
        end
        return color_ct(r, g, b, a)
    else
        local name_end = string.find(str, ',')
        local alpha = 1
        if name_end then
            alpha = tonumber(string.sub(str, name_end + 1))
            str = string.sub(str, 1, name_end - 1)
        end
        local base_color = color_table[str]
        if base_color then
            return color_ct(base_color.r, base_color.g, base_color.b, alpha)
        end
    end
end

function color_mt:__tostring()
    return string.format("#%02X%02X%02X%02X", self.r*255, self.g*255, self.b*255, self.a*255)
end

color_ct = ffi.metatype("struct color", color_mt)

color_table = {
    AliceBlue = color.parse("#F0F8FF"),
    AntiqueWhite = color.parse("#FAEBD7"),
    Aqua = color.parse("#00FFFF"),
    Aquamarine = color.parse("#7FFFD4"),
    Azure = color.parse("#F0FFFF"),
    Beige = color.parse("#F5F5DC"),
    Bisque = color.parse("#FFE4C4"),
    Black = color.parse("#000000"),
    BlanchedAlmond = color.parse("#FFEBCD"),
    Blue = color.parse("#0000FF"),
    BlueViolet = color.parse("#8A2BE2"),
    Brown = color.parse("#A52A2A"),
    BurlyWood = color.parse("#DEB887"),
    CadetBlue = color.parse("#5F9EA0"),
    Chartreuse = color.parse("#7FFF00"),
    Chocolate = color.parse("#D2691E"),
    Coral = color.parse("#FF7F50"),
    CornflowerBlue = color.parse("#6495ED"),
    Cornsilk = color.parse("#FFF8DC"),
    Crimson = color.parse("#DC143C"),
    Cyan = color.parse("#00FFFF"),
    DarkBlue = color.parse("#00008B"),
    DarkCyan = color.parse("#008B8B"),
    DarkGoldenrod = color.parse("#B8860B"),
    DarkGray = color.parse("#A9A9A9"),
    DarkGreen = color.parse("#006400"),
    DarkKhaki = color.parse("#BDB76B"),
    DarkMagenta = color.parse("#8B008B"),
    DarkOliveGreen = color.parse("#556B2F"),
    DarkOrange = color.parse("#FF8C00"),
    DarkOrchid = color.parse("#9932CC"),
    DarkRed = color.parse("#8B0000"),
    DarkSalmon = color.parse("#E9967A"),
    DarkSeaGreen = color.parse("#8FBC8F"),
    DarkSlateBlue = color.parse("#483D8B"),
    DarkSlateGray = color.parse("#2F4F4F"),
    DarkTurquoise = color.parse("#00CED1"),
    DarkViolet = color.parse("#9400D3"),
    DeepPink = color.parse("#FF1493"),
    DeepSkyBlue = color.parse("#00BFFF"),
    DimGray = color.parse("#696969"),
    DodgerBlue = color.parse("#1E90FF"),
    Firebrick = color.parse("#B22222"),
    FloralWhite = color.parse("#FFFAF0"),
    ForestGreen = color.parse("#228B22"),
    Fuchsia = color.parse("#FF00FF"),
    Gainsboro = color.parse("#DCDCDC"),
    GhostWhite = color.parse("#F8F8FF"),
    Gold = color.parse("#FFD700"),
    Goldenrod = color.parse("#DAA520"),
    Gray = color.parse("#808080"),
    Green = color.parse("#008000"),
    GreenYellow = color.parse("#ADFF2F"),
    Honeydew = color.parse("#F0FFF0"),
    HotPink = color.parse("#FF69B4"),
    IndianRed = color.parse("#CD5C5C"),
    Indigo = color.parse("#4B0082"),
    Ivory = color.parse("#FFFFF0"),
    Khaki = color.parse("#F0E68C"),
    Lavender = color.parse("#E6E6FA"),
    LavenderBlush = color.parse("#FFF0F5"),
    LawnGreen = color.parse("#7CFC00"),
    LemonChiffon = color.parse("#FFFACD"),
    LightBlue = color.parse("#ADD8E6"),
    LightCoral = color.parse("#F08080"),
    LightCyan = color.parse("#E0FFFF"),
    LightGoldenrodYellow = color.parse("#FAFAD2"),
    LightGreen = color.parse("#90EE90"),
    LightGray = color.parse("#D3D3D3"),
    LightPink = color.parse("#FFB6C1"),
    LightSalmon = color.parse("#FFA07A"),
    LightSeaGreen = color.parse("#20B2AA"),
    LightSkyBlue = color.parse("#87CEFA"),
    LightSlateGray = color.parse("#778899"),
    LightSteelBlue = color.parse("#B0C4DE"),
    LightYellow = color.parse("#FFFFE0"),
    Lime = color.parse("#00FF00"),
    LimeGreen = color.parse("#32CD32"),
    Linen = color.parse("#FAF0E6"),
    Magenta = color.parse("#FF00FF"),
    Maroon = color.parse("#800000"),
    MediumAquamarine = color.parse("#66CDAA"),
    MediumBlue = color.parse("#0000CD"),
    MediumOrchid = color.parse("#BA55D3"),
    MediumPurple = color.parse("#9370DB"),
    MediumSeaGreen = color.parse("#3CB371"),
    MediumSlateBlue = color.parse("#7B68EE"),
    MediumSpringGreen = color.parse("#00FA9A"),
    MediumTurquoise = color.parse("#48D1CC"),
    MediumVioletRed = color.parse("#C71585"),
    MidnightBlue = color.parse("#191970"),
    MintCream = color.parse("#F5FFFA"),
    MistyRose = color.parse("#FFE4E1"),
    Moccasin = color.parse("#FFE4B5"),
    NavajoWhite = color.parse("#FFDEAD"),
    Navy = color.parse("#000080"),
    OldLace = color.parse("#FDF5E6"),
    Olive = color.parse("#808000"),
    OliveDrab = color.parse("#6B8E23"),
    Orange = color.parse("#FFA500"),
    OrangeRed = color.parse("#FF4500"),
    Orchid = color.parse("#DA70D6"),
    PaleGoldenrod = color.parse("#EEE8AA"),
    PaleGreen = color.parse("#98FB98"),
    PaleTurquoise = color.parse("#AFEEEE"),
    PaleVioletRed = color.parse("#DB7093"),
    PapayaWhip = color.parse("#FFEFD5"),
    PeachPuff = color.parse("#FFDAB9"),
    Peru = color.parse("#CD853F"),
    Pink = color.parse("#FFC0CB"),
    Plum = color.parse("#DDA0DD"),
    PowderBlue = color.parse("#B0E0E6"),
    Purple = color.parse("#800080"),
    Red = color.parse("#FF0000"),
    RosyBrown = color.parse("#BC8F8F"),
    RoyalBlue = color.parse("#4169E1"),
    SaddleBrown = color.parse("#8B4513"),
    Salmon = color.parse("#FA8072"),
    SandyBrown = color.parse("#F4A460"),
    SeaGreen = color.parse("#2E8B57"),
    SeaShell = color.parse("#FFF5EE"),
    Sienna = color.parse("#A0522D"),
    Silver = color.parse("#C0C0C0"),
    SkyBlue = color.parse("#87CEEB"),
    SlateBlue = color.parse("#6A5ACD"),
    SlateGray = color.parse("#708090"),
    Snow = color.parse("#FFFAFA"),
    SpringGreen = color.parse("#00FF7F"),
    SteelBlue = color.parse("#4682B4"),
    Tan = color.parse("#D2B48C"),
    Teal = color.parse("#008080"),
    Thistle = color.parse("#D8BFD8"),
    Tomato = color.parse("#FF6347"),
    Turquoise = color.parse("#40E0D0"),
    Violet = color.parse("#EE82EE"),
    Wheat = color.parse("#F5DEB3"),
    White = color.parse("#FFFFFF"),
    WhiteSmoke = color.parse("#F5F5F5"),
    Yellow = color.parse("#FFFF00"),
    YellowGreen = color.parse("#9ACD32"),
}

return {
    color = color_ct
}
