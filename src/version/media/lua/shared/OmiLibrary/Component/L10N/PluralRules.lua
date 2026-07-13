---Handler for determining plural categories.
---@namespace omi.l10n
---@using omi

local core = require 'OmiLibrary/Module/Utils'
local Helpers = require 'OmiLibrary/Module/L10N/Helpers'
local PLURAL_RULES = require 'OmiLibrary/Definition/L10N/CLDRPlurals'

local mod = math.fmod
local modf = math.modf
local floor = math.floor


---@class PluralRules : Class
---@field private _locale string The language tag for the locale of this plural rules object.
---@field private _type PluralRuleType The type of plurals the object retrieves.
---@field private _rules PluralRuleTable? The rule table to use for resolution.
local PluralRules = core.class('PluralRules')

---Cache for memoizing PluralRules objects.
---@type table<string, PluralRules>
---@private
PluralRules._memo = {}

---The order of evaluation for plural rules.
---The 'other' category is excluded, since it always has no rules.
---@type PluralCategory[]
---@private
---@readonly
PluralRules._ruleOrder = {
    'zero',
    'one',
    'two',
    'few',
    'many',
}

---Gets a cached PluralRules object for the given options,
---creating one if it doesn't exist.
---@param options Args.PluralRules
---@return PluralRules
function PluralRules.fromOptions(options)
    local locale = options.locale
    local pluralType = options.type or 'cardinal'

    local key = locale:lower() .. '_' .. pluralType
    local rules = PluralRules._memo[key]
    if not rules then
        rules = PluralRules:new(options)
        PluralRules._memo[key] = rules
    end

    return rules
end


---Gets the plural category to use for a number.
---@param n number The number to check.
---@return PluralCategory category
function PluralRules:select(n)
    local rules = self._rules
    if not rules then
        return 'other'
    end

    if n < 0 then
        n = -n
    end

    local computed = {}
    for i = 1, #PluralRules._ruleOrder do
        local category = PluralRules._ruleOrder[i]
        local orRules = rules[category]

        if orRules then
            for j = 1, #orRules do
                if self:_checkRules(n, orRules[j], computed) then
                    return category
                end
            end
        end
    end

    return 'other'
end


---Checks plural rules against a number. If any fail, it's considered a mismatch.
---@param n number The number to check.
---@param rules PluralExpression[] The rules to check.
---@param computed table<string, number?> Cache table for computed values.
---@return boolean isMatch
---@private
function PluralRules:_checkRules(n, rules, computed)
    for i = 1, #rules do
        local rule = rules[i]
        local operand = rule.op

        local name = operand ---@type string
        if rule.mod then
            name = name .. rule.mod
        end

        local value = computed[name]
        if not value then
            if not computed[operand] then
                if operand == 'n' then
                    computed.n = n
                elseif operand == 'i' then
                    computed.i = floor(n)
                elseif operand == 'e' or operand == 'c' then
                    -- always treat as 0 for number
                    computed.e = 0
                    computed.c = 0
                else
                    local int, frac = modf(n)
                    if frac == 0 then
                        computed.i = int
                        computed.v = 0
                        computed.w = 0
                        computed.f = 0
                        computed.t = 0
                    else
                        local str = tostring(frac)
                        local period = str:find('.', 1, true) or 1
                        local decimalStr = str:sub(period + 1)
                        local count = #decimalStr
                        computed.i = int
                        computed.v = count
                        computed.w = count

                        local decimal = tonumber(decimalStr) or 0
                        computed.f = decimal
                        computed.t = decimal
                    end
                end
            end

            value = computed[operand]
            if rule.mod and value then
                value = mod(value, rule.mod)
                computed[name] = value
            end
        end

        assert(value ~= nil, 'Unable to compute value')

        local checkEq = not rule.neq
        if rule.value then
            local isEq = value == rule.value
            if checkEq ~= isEq then
                return false
            end
        elseif rule.values then
            local foundMatch = false
            for j = 1, #rule.values do
                local range = rule.values[j]

                local withinRange
                if range.stop then
                    withinRange = range.start <= value and value <= range.stop
                else
                    withinRange = range.start == value
                end

                if checkEq == withinRange then
                    foundMatch = true
                    break
                end
            end

            if not foundMatch then
                return false
            end
        end
    end

    return true
end


---Creates a new PluralRules instance.
---Using `PluralRules.fromOptions` should be preferred.
---@see PluralRules.fromOptions
---@param options Args.PluralRules Options for creation of the instance.
---@return PluralRules
function PluralRules:new(options)
    local this = core.new(self)
    local locale = options.locale

    this._locale = locale
    locale = locale:lower()

    local ruleSet = options.type == 'ordinal' and PLURAL_RULES.ordinal or PLURAL_RULES.cardinal
    if ruleSet[locale] then
        this._rules = ruleSet[locale]
    else
        -- if not found, try again with just the primary language subtag
        -- if still not found, object will always return 'other'
        local lang = Helpers.extractLanguage(locale)
        this._rules = ruleSet[lang]
    end

    return this
end


return PluralRules


--#region Type Definitions

---@class Args.PluralRules
---@field locale string A BCP 47 language tag.
---@field type PluralRuleType? The type of plural rules to apply. Defaults to `cardinal`.

--#endregion
