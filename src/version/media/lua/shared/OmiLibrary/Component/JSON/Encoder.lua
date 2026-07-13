---Handles JSON encoding.
---Based on rxi/json; license included below.
---@namespace omi

-- json.lua
--
-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local core = require 'OmiLibrary/Module/Utils'

local type = type
local rawget = rawget
local concat = table.concat
local format = string.format
local isempty = table.isempty


---@class json.Encoder : Class
---@field protected _pretty boolean If `true`, the result will be encoded with newlines and spaces.
---@field protected _indent integer The number of spaces to use for each indentation level.
---@field protected _level integer The current level of depth in the JSON object.
---@field protected _conversionMap table<string, json.Encoder.ConversionFunction> A map of type names to conversion handler functions.
local Encoder = core.class('JSONEncoder')


local escapeCharMap = {
    ['"'] = '"',
    ['\\'] = '\\',
    ['\b'] = 'b',
    ['\f'] = 'f',
    ['\n'] = 'n',
    ['\r'] = 'r',
    ['\t'] = 't',
}


---Escapes a single character for JSON.
---@param char string
---@return string
local function escapeCharacter(char)
    return '\\' .. (escapeCharMap[char] or format('u%04x', char:byte()))
end


---Encodes a value as JSON.
---@param value any
---@param options Args.JSONEncoder?
---@return string
function Encoder:encode(value, options)
    local result, err = self:tryEncode(value, options)
    if err then
        error(err)
    end

    return result --[[@as string]]
end

---Attempts to encode a value as json.
---@param value any
---@param options Args.JSONEncoder?
---@return string? result
---@return string? error
function Encoder:tryEncode(value, options)
    if options then
        self:_setOptions(options)
    end

    local rope = {}
    local err = self:_encode(value, rope)
    if err then
        return nil, err
    end

    return concat(rope)
end


---Encodes a value into JSON.
---@param value any
---@param rope string[]
---@param seen table?
---@return string? error
---@protected
function Encoder:_encode(value, rope, seen)
    local valueType = type(value)

    local converter = self._conversionMap[valueType]
    if not converter then
        return 'cannot encode type `' .. valueType .. '`'
    end

    local err = converter(self, value, rope, seen)
    if err then
        return err
    end
end

---Encodes a table as a JSON array.
---@param value table
---@param rope string[]
---@param seen table
---@return string? error
---@protected
function Encoder:_encodeArray(value, rope, seen)
    if #value == 0 then
        rope[#rope + 1] = '[]'
        return
    end

    rope[#rope + 1] = self._pretty and '[\n' or '['

    self._level = self._level + 1

    for i = 1, #value do
        if self._pretty then
            rope[#rope + 1] = (' '):rep(self._indent * self._level)
        end

        local err = self:_encode(value[i], rope, seen)
        if err then
            return err
        end

        if i ~= #value then
            rope[#rope + 1] = self._pretty and ',\n' or ','
        end
    end

    self._level = self._level - 1

    if self._pretty then
        rope[#rope + 1] = '\n'
        rope[#rope + 1] = (' '):rep(self._indent * self._level)
    end

    rope[#rope + 1] = ']'
end

---Encodes a boolean as JSON.
---@param value boolean
---@param rope string[]
---@return string? error
---@protected
function Encoder:_encodeBoolean(value, rope)
    rope[#rope + 1] = tostring(value)
end

---Encodes `nil` as JSON.
---@param value nil
---@param rope string[]
---@return string? error
---@protected
---@diagnostic disable-next-line: unused
function Encoder:_encodeNil(value, rope)
    rope[#rope + 1] = 'null'
end

---Encodes a number as JSON.
---@param value number
---@param rope string[]
---@return string? error
---@protected
function Encoder:_encodeNumber(value, rope)
    if value ~= value or value <= -math.huge or value >= math.huge then
        return 'unexpected number value `' .. tostring(value) .. '`'
    end

    rope[#rope + 1] = format('%.14g', value)
end

---Encodes a table as a JSON array.
---@param value table
---@param rope string[]
---@param seen table
---@return string? error
---@protected
function Encoder:_encodeObject(value, rope, seen)
    rope[#rope + 1] = self._pretty and '{\n' or '{'
    self._level = self._level + 1

    for k, v in pairs(value) do
        if type(k) ~= 'string' then
            return 'invalid table: mixed or invalid key types'
        end

        if self._pretty then
            rope[#rope + 1] = (' '):rep(self._indent * self._level)
        end

        local err = self:_encodeString(k, rope)
        if err then
            return err
        end

        rope[#rope + 1] = self._pretty and ': ' or ':'
        err = self:_encode(v, rope, seen)
        if err then
            return err
        end

        rope[#rope + 1] = self._pretty and ',\n' or ','
    end

    self._level = self._level - 1
    rope[#rope] = nil

    if self._pretty then
        rope[#rope + 1] = '\n'
        rope[#rope + 1] = (' '):rep(self._indent * self._level)
    end

    rope[#rope + 1] = '}'
end

---Encodes a string as JSON.
---@param value string
---@param rope string[]
---@return string? error
---@protected
function Encoder:_encodeString(value, rope)
    rope[#rope + 1] = '"' .. value:gsub('[%z\1-\31\\"]', escapeCharacter) .. '"'
end

---Encodes a table as JSON.
---@param value table
---@param rope string[]
---@param seen table?
---@return string? error
---@protected
function Encoder:_encodeTable(value, rope, seen)
    seen = seen or {}
    if seen[value] then
        local t = seen[value]
        if type(t) ~= 'table' then
            return 'circular reference'
        end

        local start, stop = t[1], t[2]
        for i = start, stop do
            rope[#rope + 1] = rope[i]
        end

        return
    end

    seen[value] = true

    local start = #rope + 1
    local err
    if self:_isArray(value) then
        err = self:_encodeArray(value, rope, seen)
    else
        err = self:_encodeObject(value, rope, seen)
    end

    if not err then
        local stop = #rope
        seen[value] = { start, stop }
    end

    return err
end

---Checks whether a table should be treated as an array.
---@param value table
---@return boolean
---@protected
function Encoder:_isArray(value)
    if isempty(value) then
        return true
    end

    if rawget(value, 1) == nil then
        return false
    end

    local n = 0
    for k in pairs(value) do
        if type(k) ~= 'number' then
            return false
        end

        n = n + 1
    end

    return n == #value
end

---Sets the options to use for the encoder.
---@param options Args.JSONEncoder
---@protected
function Encoder:_setOptions(options)
    self._pretty = not not options.pretty
    self._indent = options.indent or 2
    self._level = 0
end


---Creates a new encoder.
---@param options Args.JSONEncoder?
---@return json.Encoder
function Encoder:new(options)
    local this = core.new(self)

    this._pretty = false
    this._indent = 2
    this._level = 0
    this._conversionMap = {
        ['nil'] = this._encodeNil,
        ['table'] = this._encodeTable,
        ['string'] = this._encodeString,
        ['number'] = this._encodeNumber,
        ['boolean'] = this._encodeBoolean,
    }

    if options then
        this:_setOptions(options)
    end

    return this
end


return Encoder

--#region Type Definitions

---@class Args.JSONEncoder
---@field pretty? boolean If `true`, the result will be encoded with newlines and spaces. Defaults to `false`.
---@field indent? integer The number of spaces to use for each indentation level. Defaults to `2`.

---@alias json.Encoder.ConversionFunction fun(self: json.Encoder, value: any, rope: string[], seen: table?): string?

--#endregion
