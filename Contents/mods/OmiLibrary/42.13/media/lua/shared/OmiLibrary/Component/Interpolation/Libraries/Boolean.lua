---Contains interpolation functions for performing boolean operations.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local MultiMap = require 'OmiLibrary/Component/Core/MultiMap'

---@class(partial) interpolate.libraries
local Libraries = require 'OmiLibrary/Component/Interpolation/Core/Libraries'


---@class interpolate.libraries.Boolean
local BooleanLib = {}


---Wrapper for numeric comparison functions.
---@param f function
---@return fun(interpolator: Interpolator, this: any, other: any): boolean
local function comparator(f)
    return function(_, this, other)
        this = tostring(this or '')
        other = tostring(other or '')

        local nThis = tonumber(this)
        local nOther = tonumber(other)

        if nThis and nOther then
            return f(nThis, nOther)
        end

        return f(this, other)
    end
end


---Returns the last provided argument if all arguments are truthy, or `nil` if any are not.
---Uses interpolation logic to determine truthiness.
---@param interpolator Interpolator
---@param ...any
---@return any | nil
BooleanLib.All = function(interpolator, ...)
    local n = select('#', ...)
    if n == 0 then
        return
    end

    local value
    for i = 1, n do
        value = select(i, ...)
        if not interpolator:toBoolean(value) then
            return
        end
    end

    return value
end

---Returns the first truthy arguments, or `nil` if there are none.
---Uses interpolation logic to determine truthiness.
---@param interpolator Interpolator
---@param ...any
---@return any | nil
BooleanLib.Any = function(interpolator, ...)
    for i = 1, select('#', ...) do
        local value = select(i, ...)
        if interpolator:toBoolean(value) then
            return value
        end
    end
end

---Checks for equality (non-reference equality).
---If both arguments can be converted to numbers, this will use numeric comparison.
---Otherwise, string comparison is used.
BooleanLib.EQ = comparator(function(a, b) return a == b end)

---Checks whether the first argument is greater than the second argument.
---If both arguments can be converted to numbers, this will use numeric comparison.
---Otherwise, string comparison is used.
---@type fun(interpolator: Interpolator, a: any, b: any): boolean
BooleanLib.GT = comparator(function(a, b) return a > b end)

---Checks whether the first argument is greater than or equal to the second argument.
---If both arguments can be converted to numbers, this will use numeric comparison.
---Otherwise, string comparison is used.
---@type fun(interpolator: Interpolator, a: any, b: any): boolean
BooleanLib.GTE = comparator(function(a, b) return a >= b end)

---Returns the result of the concatenation of `...` if `condition` is truthy.
---Otherwise, returns `nil`.
---Uses interpolation logic to determine truthiness.
---
---If a single argument is provided after `condition`, it will be returned as-is instead of being concatenated when the value is truthy.
---@param interpolator Interpolator
---@param condition any
---@param ...any
---@return any | nil
BooleanLib.If = function(interpolator, condition, ...)
    if interpolator:toBoolean(condition) then
        if select('#', ...) == 1 then
            return ...
        end

        return core.concat({ ... })
    end
end

---Evaluates `condition` for truthiness and returns the key in `valueMap` corresponding to the truthiness.
---The value map will be checked for string keys `true` and `false`.
---If the matching value isn't present, returns `nil`.
---@param interpolator Interpolator
---@param condition any
---@param valueMap MultiMap
---@return any | nil
BooleanLib.IfElse = function(interpolator, condition, valueMap)
    if not valueMap or not core.isinstance(valueMap, MultiMap) then
        return
    end

    if interpolator:toBoolean(condition) then
        return valueMap:get('true')
    end

    return valueMap:get('false')
end

---Checks whether the first argument is less than the second argument.
---If both arguments can be converted to numbers, this will use numeric comparison.
---Otherwise, string comparison is used.
---@type fun(interpolator: Interpolator, a: any, b: any): boolean
BooleanLib.LT = comparator(function(a, b) return a < b end)

---Checks whether the first argument is less than or equal to the second argument.
---If both arguments can be converted to numbers, this will use numeric comparison.
---Otherwise, string comparison is used.
---@type fun(interpolator: Interpolator, a: any, b: any): boolean
BooleanLib.LTE = comparator(function(a, b) return a <= b end)

---Checks for inequality (non-reference equality).
---If both arguments can be converted to numbers, this will use numeric comparison.
---Otherwise, string comparison is used.
BooleanLib.NEQ = comparator(function(a, b) return a ~= b end)

---Returns a value with the opposite truth value to the given value.
---Uses interpolation logic to determine truthiness.
---@param interpolator Interpolator
---@param value any?
---@return boolean
BooleanLib.Not = function(interpolator, value)
    return not interpolator:toBoolean(value)
end

---Returns the result of the concatenation of `...` if `condition` is falsy.
---Otherwise, returns `nil`.
---Uses interpolation logic to determine truthiness.
---
---If a single argument is provided after `condition`, it will be returned as-is instead of being concatenated when the value is truthy.
---@param interpolator Interpolator
---@param condition any
---@param ...any
---@return any | nil
BooleanLib.Unless = function(interpolator, condition, ...)
    return BooleanLib.If(interpolator, not interpolator:toBoolean(condition), ...)
end


Libraries.boolean = BooleanLib
return BooleanLib
