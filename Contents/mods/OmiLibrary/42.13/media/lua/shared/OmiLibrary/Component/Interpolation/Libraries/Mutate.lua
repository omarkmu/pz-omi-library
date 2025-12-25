---Contains interpolation functions for performing operations that can mutate the interpolator.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local MultiMap = require 'OmiLibrary/Component/Core/MultiMap'

---@class(partial) interpolate.libraries
local Libraries = require 'OmiLibrary/Component/Interpolation/Libraries/Core'

local select = select
local tonumber = tonumber
local tostring = tostring


---@class interpolate.libraries.Mutate
local MutateLib = {}

---Returns a random argument from the given arguments.
---If the sole argument provided is a multimap, a value is chosen from its values.
---@param interpolator Interpolator
---@param ...any
---@return any | nil
MutateLib.Choose = function(interpolator, ...)
    local obj = ...
    if select('#', ...) ~= 1 then
        return interpolator:randomChoice({ ... })
    elseif not core.isinstance(obj, MultiMap) then
        return obj
    end

    return interpolator:randomChoice(core.pack(obj:values()))
end

---Generates a random number.
---
---If neither `m` nor `n` are given, the value will be in `[0, 1)`.
---If only `m` is given, the value will be in `[1, n]`.
---If both `m` and `n` are given, the value will be in `[m, n]`.
---@param interpolator Interpolator
---@param m integer?
---@param n integer?
---@return number?
MutateLib.Random = function(interpolator, m, n)
    if m and not tonumber(m) then
        return
    end

    if n and not tonumber(n) then
        return
    end

    return interpolator:random(m, n)
end

---Sets the seed to use for random number generation.
---@param interpolator Interpolator
---@param seed any?
MutateLib.Randomseed = function(interpolator, seed)
    interpolator:randomseed(seed)
end

---Sets the value of an interpolation token.
---@param interpolator Interpolator
---@param token any
---@param ...any
MutateLib.Set = function(interpolator, token, ...)
    local value
    if select('#', ...) > 1 then
        value = core.concat({ ... })
    else
        value = ...
    end

    interpolator:setTokenValidated(tostring(token), value)
end


Libraries.mutate = MutateLib
return MutateLib
