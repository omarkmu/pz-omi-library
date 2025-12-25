---Utilities related to colors.
---@namespace omi

local concat = table.concat
local format = string.format
local tonumber = tonumber
local type = type
local min = math.min
local max = math.max
local floor = math.floor
local gameCore = getCore()


---Contains utilities related to colors.
---@class color
---@field bad01 ColorTableRGBA<number> The bad highlight color with values in [0.0, 1.0].
---@field bad ColorTableRGBA<integer> The bad highlight color with values in [0, 255].
---@field good01 ColorTableRGBA<number> The good highlight color with values in [0.0, 1.0].
---@field good ColorTableRGBA<integer> The good highlight color with values in [0, 255].
local color = {}

---Named colors that have been defined.
---@private
---@type table<string, ColorTable<integer>>?
color._namedColors = nil

---An error that can occur while reading a color from a string.
color.ReadError = {
    EMPTY = 'EMPTY',
    INVALID_FORMAT = 'INVALID_FORMAT',
    ABOVE_MAX = 'ABOVE_MAX',
    BELOW_MIN = 'BELOW_MIN',
}


---Returns a color table for the color black.
---@return ColorTable<integer>
function color.black()
    return { r = 0, g = 0, b = 0 }
end

---Returns a new color table with the RGB color values in `colorTable` clamped to within the provided range.
---@generic T : number
---@param colorTable ColorTable<T> An RGB color table.
---@param minVal T The minimum value for components.
---@param maxVal T The maximum value for components.
---@return ColorTable<T>
function color.clamp(colorTable, minVal, maxVal)
    return {
        r = min(max(colorTable.r, minVal), maxVal),
        g = min(max(colorTable.g, minVal), maxVal),
        b = min(max(colorTable.b, minVal), maxVal),
    }
end

---Returns a new color table with the RGBA color values in `colorTable` clamped to within the provided range.
---@generic T : number
---@param colorTable ColorTableRGBA<T> An RGB color table.
---@param minVal T The minimum value for components.
---@param maxVal T The maximum value for components.
---@return ColorTableRGBA<T>
function color.clampRGBA(colorTable, minVal, maxVal)
    return {
        r = min(max(colorTable.r, minVal), maxVal),
        g = min(max(colorTable.g, minVal), maxVal),
        b = min(max(colorTable.b, minVal), maxVal),
        a = min(max(colorTable.a, minVal), maxVal),
    }
end

---Returns a copy of the given color table.
---@generic T : number
---@param colorTable ColorTable<T>
---@return ColorTable<T>
function color.copy(colorTable)
    return {
        r = colorTable.r,
        g = colorTable.g,
        b = colorTable.b,
    }
end

---Returns a copy of the given RGBA color table.
---@generic T : number
---@param colorTable ColorTableRGBA<T>
---@return ColorTableRGBA<T>
function color.copyRGBA(colorTable)
    return {
        r = colorTable.r,
        g = colorTable.g,
        b = colorTable.b,
        a = colorTable.a,
    }
end

---Converts a decimal color table to an integer color table.
---@param colorTable ColorTable<number>
---@return ColorTable<integer>
function color.decimalToInteger(colorTable)
    return {
        r = floor(colorTable.r * 255),
        g = floor(colorTable.g * 255),
        b = floor(colorTable.b * 255),
    }
end

---Creates a default color table with the given values if a color table is not given.
---@generic T : number
---@param colorTable ColorTable<T>?
---@param r T
---@param g T
---@param b T
---@return ColorTable<T>
function color.default(colorTable, r, g, b)
    if not colorTable then
        return { r = r, g = g, b = b }
    end

    return colorTable
end

---Creates a default color table with the given values if a color table is not given.
---@generic T : number
---@param colorTable ColorTableRGBA<T>?
---@param r T
---@param g T
---@param b T
---@param a T
---@return ColorTableRGBA<T>
function color.defaultRGBA(colorTable, r, g, b, a)
    if not colorTable then
        return { r = r, g = g, b = b, a = a }
    end

    return colorTable
end

---Converts a `ColorInfo` object to a decimal color table.
---@param info ColorInfo
---@return ColorTableRGBA<number>
function color.fromColorInfo(info)
    return {
        r = info:getR(),
        g = info:getG(),
        b = info:getB(),
        a = info:getA(),
    }
end

---Converts a `ColorInfo` object to an integer color table.
---@param info ColorInfo
---@return ColorTableRGBA<integer>
function color.fromColorInfoInteger(info)
    return {
        r = floor(info:getR() * 255),
        g = floor(info:getG() * 255),
        b = floor(info:getB() * 255),
        a = floor(info:getA() * 255),
    }
end

---Converts a `Color` object to a decimal color table.
---@param info Color
---@return ColorTableRGBA<number>
function color.fromColorObject(info)
    return {
        r = info:getR(),
        g = info:getG(),
        b = info:getB(),
        a = info:getAlphaFloat(),
    }
end

---Converts a `Color` object to an integer color table.
---@param info Color
---@return ColorTableRGBA<integer>
function color.fromColorObjectInteger(info)
    return {
        r = info:getRed(),
        g = info:getGreen(),
        b = info:getBlue(),
        a = info:getAlpha(),
    }
end

---Converts a hex or RGB color string to a color table.
---Returns `nil` and an error code on failure.
---@param text string A color string, in RGB or hex format.
---@param options Args.ColorValidation? Options for validation.
---@return ColorTable<integer>? result
---@return string? error
function color.fromString(text, options)
    if not text or text == '' then
        return nil, color.ReadError.EMPTY
    end

    local r, g, b = color._read(text)
    if not r or not g or not b then
        return nil, color.ReadError.INVALID_FORMAT
    end

    options = options or {} ---@type Args.ColorValidation

    local maxColor = options.maxColorValue or 255
    if r > maxColor or g > maxColor or b > maxColor then
        return nil, color.ReadError.ABOVE_MAX
    end

    local minColor = options.minColorValue or 0
    if r < minColor or g < minColor or b < minColor then
        return nil, color.ReadError.BELOW_MIN
    end

    if options.validate then
        local err = options.validate(r, g, b)
        if err then
            return nil, err
        end
    end

    return { r = r, g = g, b = b }
end

---Gets a named color.
---@return ColorTable<integer>?
function color.getByName(name)
    local namedColors = color._namedColors or color._loadNamedColors()
    return namedColors[name]
end

---Gets a table associating names to color tables.
---@param lowercase boolean Flag for whether color names should be converted to lowercase.
---@return table<string, ColorTable<integer>>
function color.getNamed(lowercase)
    local namedColors = color._namedColors or color._loadNamedColors()
    local copy = {}

    for k, v in pairs(namedColors) do
        copy[lowercase and k:lower() or k] = v
    end

    return copy
end

---Converts an integer color table to a decimal color table.
---@param colorTable ColorTable<integer>
---@return ColorTable<number>
function color.integerToDecimal(colorTable)
    return {
        r = colorTable.r / 255,
        g = colorTable.g / 255,
        b = colorTable.b / 255,
    }
end

---Checks a color table for validity.
---@generic T : number
---@param colorTable (ColorTable<T?> | any)? The color table to check.
---@return TypeGuard<ColorTable<T>>
function color.isValid(colorTable)
    if type(colorTable) ~= 'table' then
        return false
    end

    local r, g, b = colorTable.r, colorTable.g, colorTable.b

    if type(r) ~= 'number' or r < 0 or r > 255 then
        return false
    end

    if type(g) ~= 'number' or g < 0 or g > 255 then
        return false
    end

    if type(b) ~= 'number' or b < 0 or b > 255 then
        return false
    end

    return true
end

---Converts a color table to a hex string.
---@param colorTable ColorTable<integer> The color table to convert.
---@return string
function color.toHexString(colorTable)
    return format('%02x%02x%02x', colorTable.r, colorTable.g, colorTable.b)
end

---Converts a color table to an RGB string.
---@param colorTable ColorTable<integer> The color table to convert.
---@param delimiter string? The delimiter to use. Defaults to `,`.
---@return string
function color.toRGBString(colorTable, delimiter)
    return concat({
        format('%d', colorTable.r),
        format('%d', colorTable.g),
        format('%d', colorTable.b),
    }, delimiter or ',')
end

---Converts a color table to a color string for rich text.
---@param colorTable ColorTable<integer>? The color table to convert.
---@param push boolean? If `true`, PUSHRGB format will be used.
---@return string
function color.toRichText(colorTable, push)
    if not colorTable or not color.isValid(colorTable) then
        return ''
    end

    return concat {
        ' <',
        push and 'PUSH' or '',
        'RGB:',
        format('%.7f', colorTable.r / 255):gsub('(%d)0+$', '%1'),
        ',',
        format('%.7f', colorTable.g / 255):gsub('(%d)0+$', '%1'),
        ',',
        format('%.7f', colorTable.b / 255):gsub('(%d)0+$', '%1'),
        '> ',
    }
end

---Returns the red, green, blue, and alpha values of a color.
---@generic T : number
---@param colorTable ColorTableRGBA<T> | ColorTable<T>
---@return T, T, T, T
---@overload fun(colorTable: ColorTable<T>): T, T, T
---@overload fun(colorTable: ColorTableRGBA<T>): T, T, T, T
function color.unpack(colorTable)
    return colorTable.r, colorTable.g, colorTable.b, colorTable.a
end

---Returns a color table for the color white.
---@return ColorTable<integer>
function color.white()
    return { r = 255, g = 255, b = 255 }
end

---Loads named colors into a cache.
---@return table<string, ColorTable<number>>
---@protected
function color._loadNamedColors()
    local colorMap = {}
    local names = Colors.GetColorNames()
    for i = 0, names:size() - 1 do
        local name = names:get(i)
        local namedColor = Colors.GetColorByName(names:get(i))

        colorMap[name] = {
            r = namedColor:getRed(),
            g = namedColor:getGreen(),
            b = namedColor:getBlue(),
        }
    end

    color._namedColors = colorMap
    return colorMap
end

---Attempts to read an RGB or hex color from a string.
---@param text string
---@return integer?
---@return integer?
---@return integer?
---@protected
function color._read(text)
    local r, g, b = text:match('^%s*(%d%d?%d?)[,%s]+(%d%d?%d?)[,%s]+(%d%d?%d?)%s*$')
    if r and g and b then
        return tonumber(r, 10), tonumber(g, 10), tonumber(b, 10)
    end

    r, g, b = text:match('^%s*#?(%x)(%x)(%x)%s*$')
    if r then
        r = r .. r
        g = g .. g
        b = b .. b
    else
        r, g, b = text:match('^%s*#?(%x%x)%s*(%x%x)%s*(%x%x)%s*$')
    end

    if not r or not g or not b then
        return
    end

    return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

---Updates the cached bad highlight color.
---@protected
function color._updateBad()
    local bhc = gameCore:getBadHighlitedColor()
    color.bad01 = color.fromColorInfo(bhc)
    color.bad = color.fromColorInfoInteger(bhc)
end

---Updates the cached good highlight color.
---@protected
function color._updateGood()
    local ghc = gameCore:getGoodHighlitedColor()
    color.good01 = color.fromColorInfo(ghc)
    color.good = color.fromColorInfoInteger(ghc)
end

color._updateBad()
color._updateGood()
return color

--#region Type Definitions

---@class Args.ColorValidation
---@field minColorValue? integer Minimum color value in [0, 255]. Defaults to `0`.
---@field maxColorValue? integer Maximum color value in [0, 255]. Defaults to `255`.
---@field validate? Callback.ValidateColor Validator function. Returns an error code on validation failure.


---@alias Callback.ValidateColor fun(r: number, g: number, b: number): string?

--#endregion
