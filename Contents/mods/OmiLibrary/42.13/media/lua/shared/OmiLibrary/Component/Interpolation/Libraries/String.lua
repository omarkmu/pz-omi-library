---Contains interpolation functions for performing operations on strings.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local Helpers = require 'OmiLibrary/Component/Interpolation/Libraries/Helpers'
local MultiMap = require 'OmiLibrary/Component/Core/MultiMap'

---@class(partial) interpolate.libraries
local Libraries = require 'OmiLibrary/Component/Interpolation/Core/Libraries'

local unpack = unpack


---@class interpolate.libraries.String
local StringLib = {}


---Returns the internal numeric codes of characters in the given string as a multimap.
---@param interpolator Interpolator
---@param s any
---@param i any
---@param j any
---@return MultiMap?
StringLib.Byte = function(interpolator, s, i, j)
    i = tonumber(i or 1)
    if not i then
        return
    end

    j = tonumber(j or i)
    if not j then
        return
    end

    s = tostring(s or '')
    return Helpers.tryList(string.byte, interpolator, s, i, j)
end

---Capitalizes the first character in a string.
---@type fun(interpolator: Interpolator, ...: any): string
StringLib.Capitalize = Helpers.concatenateArgs(function(s) return s:sub(1, 1):upper() .. s:sub(2) end)

---Converts numeric codes into string characters and returns the values concatenated as a string.
---If a multimap is provided as the sole argument, the characters will be its values.
---@param interpolator Interpolator
---@param ...any
---@return string?
StringLib.Char = function(interpolator, ...)
    local args = {}

    local o = ...
    local nArgs = select('#', ...)
    if nArgs == 1 and core.isinstance(o, MultiMap) then
        for value in o:values() do
            local num = tonumber(tostring(interpolator:convert(value)))
            if not num then
                return
            end

            args[#args + 1] = num
        end

        return Helpers.try(string.char, unpack(args))
    end

    for i = 1, nArgs do
        local num = tonumber(tostring(interpolator:convert(select(i, ...))))
        if not num then
            return
        end

        args[#args + 1] = num
    end

    return Helpers.try(string.char, unpack(args))
end

---Concatenates the provided arguments into a single string.
---@param interpolator Interpolator
---@param ...any
---@return string
---@diagnostic disable-next-line: unused
StringLib.Concat = function(interpolator, ...) return core.concat({ ... }) end

---Concatenates the provided arguments into a single string using `sep` as a separator.
---@type fun(interpolator: Interpolator, ...: any): string
StringLib.Concats = Helpers.firstToString(function(sep, ...) return core.concat({ ... }, sep) end)

---Returns `true` if the given string contains another string.
---@type fun(interpolator: Interpolator, this: any, other: any): boolean
StringLib.Contains = Helpers.firstToString(function(this, other) return core.contains(this, tostring(other or '')) end)

---Returns `true` if the given string ends with another string.
---@type fun(interpolator: Interpolator, this: any, other: any): boolean
StringLib.EndsWith = Helpers.firstToString(function(this, other) return core.endsWith(this, tostring(other or '')) end)

---Escapes rich text in a string.
---@type fun(interpolator: Interpolator, ...: any): string
StringLib.EscapeRichText = Helpers.concatenateArgs(core.escapeRichText)

---Converts given arguments to a single string and returns the first character.
---@type fun(interpolator: Interpolator, ...: any): string
StringLib.First = Helpers.concatenateArgs(function(s) return s:sub(1, 1) end)

---Replaces all instances of `pattern` in `s` with `repl`.
---If `n` is provided, it will be the maximum number of replacements that occur.
---
---Returns the new string and the number of replacements that occurred as a multimap.
---@param interpolator Interpolator
---@param s any
---@param pattern any
---@param repl any
---@param n any
---@return MultiMap?
StringLib.Gsub = function(interpolator, s, pattern, repl, n)
    s = tostring(s or '')
    pattern = tostring(pattern or '')
    repl = tostring(repl or '')
    n = tonumber(n)

    return Helpers.tryList(string.gsub, interpolator, s, pattern, repl, n)
end

---Returns the character at the given index in a string.
---Negative indices will return characters from the end.
---@type fun(interpolator: Interpolator, s: any, index: any, default: any?): string
StringLib.Index = Helpers.firstToString(function(s, index, default)
    index = core.tointeger(index)
    if index and index < 0 then
        index = #s + index + 1
    end

    if not index or index > #s or index < 1 then
        return tostring(default or '')
    end

    return s:sub(index, index)
end)

---Converts given arguments to a single string and returns the last character.
---@type fun(...: any): string
StringLib.Last = Helpers.concatenateArgs(function(s) return s:sub(-1) end)

---Returns the length of the result of concatenating the given arguments.
---@param interpolator Interpolator
---@param ...any
---@return integer
---@diagnostic disable-next-line: unused
StringLib.Len = function(interpolator, ...) return #core.concat({ ... }) end

---Converts given arguments to a single string with all characters in lowercase.
---@type fun(...: any): string
StringLib.Lower = Helpers.concatenateArgs(string.lower)

---Matches a string against a pattern and returns the result of the match.
---@param interpolator Interpolator
---@param s any
---@param pattern any
---@param init any?
---@return MultiMap?
StringLib.Match = function(interpolator, s, pattern, init)
    s = tostring(s or '')
    pattern = tostring(pattern or '')
    init = tonumber(init) or 1
    return Helpers.tryList(string.match, interpolator, s, pattern, init)
end

---Adds punctuation to a string if it isn't already present.
---@type fun(interpolator: Interpolator, s: any, punctuation: any?, chars: any?): string
StringLib.Punctuate = Helpers.firstToString(function(s, punctuation, chars)
    punctuation = tostring(punctuation or '.')
    chars = tostring(chars or '')

    local patt
    if chars ~= '' then
        patt = table.concat { '[', core.escape(chars), ']$' }
    else
        patt = '%p$'
    end

    if not s:match(patt) then
        s = s .. punctuation
    end

    return s
end)

---Returns `n` repetitions of the string `s`.
---If provided, `sep` will act as a separator between repetitions.
---@type fun(interpolator: Interpolator, s: any, n: any, sep: any?): string?
StringLib.Rep = Helpers.firstToString(function(s, n, sep)
    n = tonumber(n)
    if not n or n < 1 then
        return
    end

    return Helpers.try(string.rep, s, n, tostring(sep or ''))
end)

---Reverses a string.
---@type fun(...: any): string
StringLib.Reverse = Helpers.concatenateArgs(string.reverse)

---Returns `true` if the given string starts with another string.
---@type fun(interpolator: Interpolator, this: any, other: any): boolean
StringLib.StartsWith = Helpers.firstToString(function(s, other) return core.startsWith(s, tostring(other or '')) end)

StringLib.Str = StringLib.Concat

---Returns a substring of `s` from `i` to `j`.
---@type fun(interpolator: Interpolator, s: any, i: any, j: any): string?
StringLib.Sub = Helpers.firstToString(function(s, i, j)
    i = core.tointeger(i)
    if not i then
        return
    end

    j = core.tointeger(j)
    return j and s:sub(i, j) or s:sub(i)
end)

---Trims whitespace on either side of a string.
---@type fun(interpolator: Interpolator, ...: any): string
StringLib.Trim = Helpers.concatenateArgs(core.trim)

---Trims whitespace on the left of a string.
---@type fun(interpolator: Interpolator, ...: any): string
StringLib.TrimLeft = Helpers.concatenateArgs(core.trimleft)

---Trims whitespace on the right of a string.
---@type fun(interpolator: Interpolator, ...: any): string
StringLib.TrimRight = Helpers.concatenateArgs(core.trimright)

---Converts given arguments to a single string with all characters in uppercase.
---@type fun(...: any): string
StringLib.Upper = Helpers.concatenateArgs(string.upper)


Libraries.string = StringLib
return StringLib
