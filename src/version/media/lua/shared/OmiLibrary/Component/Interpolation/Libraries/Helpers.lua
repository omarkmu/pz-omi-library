---Helper functions for interpolation libraries.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'

---@class(partial) interpolate.libraries
local Libraries = require 'OmiLibrary/Component/Interpolation/Core/Libraries'

local min = math.min
local pcall = pcall
local tostring = tostring
local unpack = unpack


---@class interpolate.libraries.Helpers
local Helpers = {}


---Wrapper for interpolation functions that expect multiple string arguments.
---@param f function
---@param maxArgs integer?
---@return fun(interpolator: Interpolator, ...: any): ...
function Helpers.argsToStrings(f, maxArgs)
    return function(interpolator, ...)
        local args = {}

        local nArgs = select('#', ...)
        maxArgs = maxArgs or nArgs

        for i = 1, min(nArgs, maxArgs) do
            args[i] = tostring(interpolator:convert(select(i, ...)))
        end

        return f(unpack(args))
    end
end

---Wrapper for functions that expect a single string argument.
---Concatenates arguments into one argument.
---@param f function
---@return fun(interpolator: Interpolator, ...: any): ...
function Helpers.concatenateArgs(f)
    return function(_, ...)
        return f(core.concat({ ... }))
    end
end

---Wrapper that converts the first argument to a string.
---@param f fun(s: string, ...: any): ...
---@return fun(interpolator: Interpolator, ...: any): ...
function Helpers.firstToString(f)
    return function(_, ...)
        return f(tostring((...) or ''), select(2, ...))
    end
end

---Wrapper for pcall in interpolation functions.
---@param f function
---@param ...any
---@return any...
function Helpers.try(f, ...)
    local results = { pcall(f, ...) }
    if not results[1] then
        return
    end

    return unpack(results, 2)
end

---Wrapper for pcall in interpolation functions.
---Wraps return values as a list.
---@param f function
---@param interpolator Interpolator
---@param ...any
---@return MultiMap?
function Helpers.tryList(f, interpolator, ...)
    local results = { pcall(f, ...) }

    if not results[1] then
        return
    end

    return Libraries.map.List(interpolator, unpack(results, 2))
end


Libraries.Helpers = Helpers
return Helpers
