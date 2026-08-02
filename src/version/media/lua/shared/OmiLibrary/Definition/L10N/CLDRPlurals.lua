---Information used for pluralization.
---@namespace omi.l10n

local getCLDRData = require 'OmiLibrary/Definition/Generated/CLDRPluralData'

local Data = {}

---Associates language tags to pluralization rules for cardinal numbers.
---@type table<string, PluralRuleTable>
Data.cardinal = {}

---Associates language tags to pluralization rules for ordinal numbers.
---@type table<string, PluralRuleTable>
Data.ordinal = {}

do
    local cldrData = getCLDRData()

    ---Associates language tags in plural data to their rules for quick access.
    local function mapLocales(pluralType)
        local list = cldrData[pluralType]
        local out = Data[pluralType]
        for i = 1, #list do
            local data = list[i] ---@type any
            for j = 1, #data.locales do
                local locale = data.locales[j]:lower()
                out[locale] = out[locale] or {}

                for k, v in pairs(data.rules) do
                    out[locale][k] = v
                end
            end
        end
    end

    mapLocales('cardinal')
    mapLocales('ordinal')
end

return Data

--#region Type Definitions

---@class PluralExpression
---@field op PluralOperand The operand to check.
---@field neq boolean? Flag for whether the check should be not equals instead of equals.
---@field value integer? A value to check against.
---@field values PluralValueRange[]? Ranges of values to check against.
---@field mod integer? A modulus value to apply to the operand.

---@class PluralValueRange
---@field start integer The start value of the range.
---@field stop integer? The stop value of the range. If this is absent, it's the same as the start value.

---A list of conditions for plural rule logic.
---
---Each inner rule table should be evaluated with `AND` logic; all
---of the expressions must be true for a match.
---
---The outer list uses `OR` logic—if any of the inner rule lists match, it's a match.
---@alias PluralConditions PluralExpression[][]

---Associates plural categories to a list of conditions for matching.
---@alias PluralRuleTable table<PluralCategory, PluralConditions>

---@alias PluralOperand
---| 'n' The absolute value of a number.
---| 'i' The integer digits of a number.
---| 'v' The number of visible fraction digits in a number, with trailing zeroes.
---| 'w' The number of visible fraction digits in a number, without trailing zeroes.
---| 'f' The visible fraction digits in a number, with trailing zeroes, as an integer.
---| 't' The visible fraction digits in a number, without trailing zeroes, as an integer.
---| 'c' Compact decimal exponent value (not supported).
---| 'e' Deprecated synonym for `c` (not supported).

---@alias PluralRuleType 'cardinal' | 'ordinal'

---@alias PluralCategory
---| 'zero'
---| 'one'
---| 'two'
---| 'few'
---| 'many'
---| 'other'

--#endregion
