---Fluent type representing a number.
---@namespace omi.l10n
---@using omi
---@using omi.l10n.fluent

local core = require 'OmiLibrary/Module/Utils'
local FluentType = require 'OmiLibrary/Component/L10N/FluentTypes/Type'

local modf = math.modf
local rep = string.rep
local tostring = tostring

---@class FluentNumber : FluentType<number>
---@field options FluentNumberOptions? Options for formatting the value.
local FluentNumber = FluentType:derive('FluentNumber')

---Format function for converting the number to a string.
---@return string
function FluentNumber:convert()
    -- this isn't really locale-aware
    -- if NumberFormat isn't exposed in b42, will need more CLDR data

    local opts = self.options or {}
    local minFrac = opts.minimumFractionDigits
    local maxFrac = opts.maximumFractionDigits

    -- default max to 3 unless min is specified
    if not maxFrac and not minFrac then
        maxFrac = 3
    end

    minFrac = minFrac or 0

    local int, frac = modf(self.value)

    local intStr = tostring(int)
    local intPeriod = intStr:find('.', 1, true)
    if intPeriod then
        intStr = intStr:sub(1, intPeriod - 1)
    end

    local fracStr = tostring(frac):sub(3)
    if #fracStr < minFrac then
        fracStr = fracStr .. rep('0', minFrac - #fracStr)
    end

    if maxFrac and #fracStr > maxFrac then
        fracStr = fracStr:sub(1, maxFrac)
    end

    if fracStr == '' or (fracStr == '0' and minFrac == 0) then
        return intStr
    end

    return intStr .. '.' .. fracStr
end

---Creates an instance of `FluentNumber` with the given value.
---@param value number The number value.
---@param options FluentNumberOptions? Options for formatting the value.
---@return FluentNumber
function FluentNumber:new(value, options)
    local this = core.new(self, FluentType.new, value)

    this.options = options

    return this
end


return FluentNumber

--#region Type Definitions

---@class FluentNumberOptions : NumberFormatOptions, PluralRulesOptions

--#endregion
