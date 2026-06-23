---Contains interpolation functions for performing operations on multimaps.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local MultiMap = require 'OmiLibrary/Component/Core/MultiMap'

---@class(partial) interpolate.libraries
local Libraries = require 'OmiLibrary/Component/Interpolation/Core/Libraries'


---@class interpolate.Libraries.Map
local MapLib = {}


---Concatenates the values of the provided multimap.
---If a sole multimap is not provided, this falls back to string concatenation.
---@param interpolator Interpolator
---@param ...any
---@return string
MapLib.Concat = function(interpolator, ...)
    local obj = ...
    if select('#', ...) ~= 1 or not core.isinstance(obj, MultiMap) then
        return Libraries.string.Concat(interpolator, ...)
    end

    ---@cast obj MultiMap
    return obj:concat()
end

---Concatenates the values of the provided multimap using `sep` as a separator.
---If a sole multimap is not provided, this falls back to string concatenation.
---@param interpolator Interpolator
---@param sep string
---@param ...any
---@return string
MapLib.Concats = function(interpolator, sep, ...)
    local obj = ...
    if select('#', ...) ~= 1 or not core.isinstance(obj, MultiMap) then
        return Libraries.string.Concats(interpolator, sep, ...)
    end

    sep = tostring(sep or '')

    ---@cast obj MultiMap
    return obj:concat(sep)
end

---Returns the value of the first entry in a multimap.
---If a sole multimap is not provided, this falls back to the string `first` function.
---@param interpolator Interpolator
---@param ...any
---@return any
MapLib.First = function(interpolator, ...)
    local obj = ...
    if select('#', ...) ~= 1 or not core.isinstance(obj, MultiMap) then
        return Libraries.string.First(interpolator, ...)
    end

    ---@cast obj MultiMap
    return obj:first()
end

---Gets the first value associated with a key.
---@param interpolator Interpolator
---@param obj MultiMap
---@param key any
---@param default any?
---@return any | nil
---@diagnostic disable-next-line: unused
MapLib.Get = function(interpolator, obj, key, default)
    if not obj or not core.isinstance(obj, MultiMap) then
        return
    end

    return obj:get(key, default)
end

---Checks whether a multimap has entries associated with a given key.
---@param interpolator Interpolator
---@param obj MultiMap
---@param key any
---@return any | nil
---@diagnostic disable-next-line: unused
MapLib.Has = function(interpolator, obj, key)
    if not obj or not core.isinstance(obj, MultiMap) then
        return
    end

    return obj:has(key)
end

---Creates a list-style multimap of entries associated with a key.
---If a sole multimap is not provided, this falls back to the string `index` function.
---@param interpolator Interpolator
---@param obj MultiMap
---@param key any
---@param default any?
---@return any
MapLib.Index = function(interpolator, obj, key, default)
    if not core.isinstance(obj, MultiMap) then
        return Libraries.string.Index(interpolator, obj, key, default)
    end

    return obj:index(key, default)
end

---Returns the value of the last entry in a multimap.
---If a sole multimap is not provided, this falls back to the string `last` function.
---@param interpolator Interpolator
---@param ...any
---@return any
MapLib.Last = function(interpolator, ...)
    local o = ...
    if select('#', ...) ~= 1 or not core.isinstance(o, MultiMap) then
        return Libraries.string.Last(interpolator, ...)
    end

    return o:last()
end

---Creates a list from the given arguments.
---
---If a multimap is provided as the sole argument, its values will be used to populate the list.
---If no arguments are provided, returns `nil`.
---@param interpolator Interpolator
---@param ...any
---@return MultiMap?
MapLib.List = function(interpolator, ...)
    local obj = ...
    if not obj then
        return
    end

    local entries = {}
    local nArgs = select('#', ...)
    if nArgs ~= 1 or not core.isinstance(obj, MultiMap) then
        for i = 1, nArgs do
            entries[#entries + 1] = {
                interpolator:convertLiteral(#entries + 1),
                interpolator:convert(select(i, ...)),
            }
        end

        return MultiMap:new(entries)
    end

    ---@cast obj MultiMap
    for value in obj:values() do
        entries[#entries + 1] = {
            interpolator:convertLiteral(#entries + 1),
            interpolator:convert(value),
        }
    end

    return MultiMap:new(entries)
end

---Returns the number of entries in a multimap.
---If a sole multimap is not provided, this falls back to the string `len` function.
---@param interpolator Interpolator
---@param ...any
---@return integer
MapLib.Len = function(interpolator, ...)
    local o = ...
    if select('#', ...) ~= 1 or not core.isinstance(o, MultiMap) then
        return Libraries.string.Len(interpolator, ...)
    end

    ---@cast o MultiMap
    return o:size()
end

---Maps an interpolation function onto the values of a multimap.
---Returns a multimap of mapped entries.
---If the function is not found or a multimap is not provided, returns `nil`.
---@param interpolator Interpolator
---@param func string The name of the interpolation function to run.
---@param obj MultiMap The multimap containing values to map.
---@param ...any Additional arguments to pass to the function.
---@return MultiMap?
MapLib.Map = function(interpolator, func, obj, ...)
    func = tostring(func)
    if not interpolator:getFunction(func) then
        return
    end

    if not core.isinstance(obj, MultiMap) then
        return
    end

    local entries = {}
    ---@cast obj MultiMap
    for key, value in obj:pairs() do
        value = interpolator:convert(interpolator:execute(func, { value, ... }))
        entries[#entries + 1] = { key, value }
    end

    return MultiMap:new(entries)
end

---Returns the value of the `n`th entry in the multimap.
---If `n` is not provided or not present in the multimap, returns `nil`.
---@param interpolator Interpolator
---@param obj MultiMap
---@param n number?
---@return any | nil
---@diagnostic disable-next-line: unused
MapLib.NthValue = function(interpolator, obj, n)
    if not obj or not core.isinstance(obj, MultiMap) then
        return
    end

    n = core.tointeger(n)
    if not n then
        return
    end

    ---@cast obj MultiMap
    local entry = obj:entry(n)
    if entry then
        return entry[2]
    end
end

---Creates a multimap with only the unique values from the given multimap.
---@param interpolator Interpolator
---@param o MultiMap
---@return MultiMap?
---@diagnostic disable-next-line: unused
MapLib.Unique = function(interpolator, o)
    if core.isinstance(o, MultiMap) then
        return o:unique()
    end
end


Libraries.map = MapLib
return MapLib
