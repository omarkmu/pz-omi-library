---Contains interpolation functions for performing mathematical functions.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local Helpers = require 'OmiLibrary/Component/Interpolation/Libraries/Helpers'

---@class(partial) interpolate.libraries
local Libraries = require 'OmiLibrary/Component/Interpolation/Libraries/Core'

local select = select
local PI = math.pi
local NaN = tostring(0 / 0)


---@class interpolate.Libraries.Math
local MathLib = {}


---Wrapper for unary functions.
---@param f function
---@return fun(interpolator: Interpolator, ...: any): number?
local function unary(f)
    return function(_, ...)
        local value = tonumber(core.concat({ ... }))
        if value then
            return f(value)
        end
    end
end

---Wrapper for unary functions with multiple returns.
---@param f function
---@return fun(interpolator: Interpolator, ...: any): MultiMap?
local function unaryList(f)
    return function(self, ...)
        local value = tonumber(core.concat({ ... }))
        if not value then
            return
        end

        return Libraries.map.List(self, f(value))
    end
end

---Wrapper for binary functions.
---@param f function
---@return fun(interpolator: Interpolator, x: any, ...: any): number?
local function binary(f)
    return function(_, x, ...)
        x = tonumber(tostring(x))
        if not x then
            return
        end

        local y = tonumber(core.concat({ ... }))
        if y then
            return f(x, y)
        end
    end
end


MathLib.Abs = unary(math.abs)

MathLib.Acos = unary(math.acos)

MathLib.Add = binary(function(x, y) return x + y end)

MathLib.Asin = unary(math.asin)

MathLib.Atan = unary(math.atan)

MathLib.Atan2 = binary(math.atan2)

MathLib.Ceil = unary(math.ceil)

MathLib.Cos = unary(math.cos)

MathLib.Cosh = unary(math.cosh)

MathLib.Deg = unary(math.deg)

MathLib.Div = binary(function(x, y) return x / y end)

MathLib.Exp = unary(math.exp)

MathLib.Floor = unary(math.floor)

MathLib.Fmod = binary(math.fmod)

MathLib.Frexp = unaryList(math.frexp)

MathLib.Int = unary(math.modf)

---@param interpolator Interpolator
---@param n any
---@return boolean
---@diagnostic disable-next-line: unused
MathLib.IsNaN = function(interpolator, n) return tostring(n) == NaN end

MathLib.Ldexp = binary(math.ldexp)

MathLib.Log = unary(function(x) return Helpers.try(math.log, x) end)

MathLib.Log10 = unary(function(x) return Helpers.try(math.log10, x) end)

---Returns the maximum value of the given arguments.
---If all arguments are numbers, numeric comparison is used.
---Otherwise, string comparison is used.
---@param interpolator Interpolator
---@param ...any
---@return (string | number)?
---@diagnostic disable-next-line: unused
MathLib.Max = function(interpolator, ...)
    local max
    local strComp = not core.all(tonumber, { ... })

    for i = 1, select('#', ...) do
        local arg = select(i, ...)
        arg = strComp and tostring(arg) or tonumber(arg)

        if not max or (arg and arg > max) then
            max = arg
        end
    end

    return max
end

---Returns the minimum value of the given arguments.
---If all arguments are numbers, numeric comparison is used.
---Otherwise, string comparison is used.
---@param interpolator Interpolator
---@param ...any
---@return (string | number)?
---@diagnostic disable-next-line: unused
MathLib.Min = function(interpolator, ...)
    local min
    local strComp = not core.all(tonumber, { ... })

    for i = 1, select('#', ...) do
        local arg = select(i, ...)
        arg = strComp and tostring(arg) or tonumber(arg)

        if not min or (arg and arg < min) then
            min = arg
        end
    end

    return min
end

MathLib.Mod = binary(function(x, y) return x % y end)

MathLib.Modf = unaryList(math.modf)

MathLib.Mul = binary(function(x, y) return x * y end)

---Returns the result of converting the given value to a number.
---@type fun(interpolator: Interpolator, ...: any): number?
MathLib.Num = Helpers.concatenateArgs(tonumber)

---@return number
MathLib.PI = function() return PI end

MathLib.Pow = binary(math.pow)

MathLib.Rad = unary(math.rad)

MathLib.Sin = unary(math.sin)

MathLib.Sinh = unary(math.sinh)

MathLib.Subtract = binary(function(x, y) return x - y end)

MathLib.Sqrt = unary(math.sqrt)

MathLib.Tan = unary(math.tan)

MathLib.Tanh = unary(math.tanh)


Libraries.math = MathLib
return MathLib
