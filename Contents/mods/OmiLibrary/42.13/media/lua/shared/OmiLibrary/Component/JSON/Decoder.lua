---Handles JSON decoding.
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
local createSet = (require 'OmiLibrary/Module/Set').table
local format = string.format


---@class json.Decoder : Class
---@field protected _null? any The value to use for `null` values.
---@field protected _conversionMap table<string, json.Decoder.ConversionFunction> A map of initial value strings to conversion handler functions.
local Decoder = core.class('JSONDecoder')


local spaceChars = createSet { ' ', '\t', '\r', '\n' }
local delimChars = createSet { ' ', '\t', '\r', '\n', ']', '}', ',' }
local literals = createSet { 'true', 'false', 'null' }

local literalMap = {
    ['true'] = true,
    ['false'] = false,
}
local escapeCharMap = {
    ['"'] = '"',
    ['/'] = '/',
    ['\\'] = '\\',
    ['b'] = '\b',
    ['f'] = '\f',
    ['n'] = '\n',
    ['r'] = '\r',
    ['t'] = '\t',
}


---Decodes a JSON string.
---Throws an error on failure.
---@param str string
---@return json.JSONType
function Decoder:decode(str)
    local success, result = self:tryDecode(str)
    if not success then
        error(result)
    end

    return result
end

---Attempts to decode a JSON string.
---@param str string
---@return boolean success
---@return json.JSONType resultOrError
function Decoder:tryDecode(str)
    if type(str) ~= 'string' then
        return false, 'expected argument of type string, got ' .. type(str)
    end

    local success, result, idx = self:_parse(str, self:_nextChar(str, 1, spaceChars, true))
    if not success then
        return success, result
    end

    idx = self:_nextChar(str, idx, spaceChars, true)
    if idx <= #str then
        return false, 'trailing garbage'
    end

    return true, result
end

---Creates the return values for a decoding error.
---@param str string
---@param idx integer
---@param message string
---@return false success
---@return string message
---@return integer index
---@protected
function Decoder:_error(str, idx, message)
    local line, column = core.getLineAndColumn(str, idx)

    return false, format('%s at line %d col %d', message, line, column), idx
end

---Gets the index of the next readable character based on the input set.
---@param str string
---@param idx integer
---@param set SetTable<string>
---@param negate true?
---@return integer index
---@protected
function Decoder:_nextChar(str, idx, set, negate)
    for i = idx, #str do
        if set[str:sub(i, i)] ~= negate then
            return i
        end
    end

    return #str + 1
end

---Parses a JSON string.
---@param str string
---@param idx integer
---@return boolean success
---@return json.JSONType resultOrError
---@return integer index
---@protected
function Decoder:_parse(str, idx)
    if idx > #str then
        return self:_error(str, idx, 'unexpected end of input')
    end

    local c = str:sub(idx, idx)
    local converter = self._conversionMap[c]
    if not converter then
        return self:_error(str, idx, 'unexpected character `' .. c .. '`')
    end

    return converter(self, str, idx)
end

---Parses a JSON array.
---@param str string
---@param idx integer
---@return boolean success
---@return any[] | string resultOrError
---@return integer index
---@protected
function Decoder:_parseArray(str, idx)
    local res = {}
    local n = 1
    idx = idx + 1
    while true do
        local success, x
        idx = self:_nextChar(str, idx, spaceChars, true)
        -- Empty / end of array?
        if str:sub(idx, idx) == ']' then
            idx = idx + 1
            break
        end

        -- Read token
        success, x, idx = self:_parse(str, idx)
        if not success then
            return success, x --[[@as string]], idx
        end

        res[n] = x
        n = n + 1

        -- Next token
        idx = self:_nextChar(str, idx, spaceChars, true)
        local chr = str:sub(idx, idx)
        idx = idx + 1

        if chr == ']' then
            break
        elseif chr ~= ',' then
            return self:_error(str, idx - 1, 'expected `]` or `,`')
        end
    end

    return true, res, idx
end

---Parses `true`, `false`, or `null` from JSON.
---@param str string
---@param idx integer
---@return boolean success
---@return json.JSONType resultOrError
---@return integer index
---@protected
function Decoder:_parseLiteral(str, idx)
    local x = self:_nextChar(str, idx, delimChars)
    local word = str:sub(idx, x - 1)
    if not literals[word] then
        return self:_error(str, idx, 'invalid literal `' .. word .. '`')
    end

    local value = literalMap[word]
    if value == nil then
        value = self._null
    end

    return true, value, x
end

---Parses a number from JSON.
---@param str string
---@param idx integer
---@return boolean success
---@return number | string resultOrError
---@return integer index
---@protected
function Decoder:_parseNumber(str, idx)
    local x = self:_nextChar(str, idx, delimChars)
    local s = str:sub(idx, x - 1)
    local n = tonumber(s)
    if not n then
        return self:_error(str, idx, 'invalid number `' .. s .. '`')
    end

    return true, n, x
end

---Parses a JSON object.
---@param str string
---@param idx integer
---@return boolean success
---@return table | string resultOrError
---@return integer index
---@protected
function Decoder:_parseObject(str, idx)
    local res = {}
    idx = idx + 1
    while true do
        local success, key, val
        idx = self:_nextChar(str, idx, spaceChars, true)

        -- Empty / end of object?
        if str:sub(idx, idx) == '}' then
            idx = idx + 1
            break
        end

        -- Read key
        if str:sub(idx, idx) ~= '"' then
            return self:_error(str, idx, 'expected string for key')
        end

        success, key, idx = self:_parse(str, idx)

        if not success or not key then
            return success, key --[[@as string]], idx
        end

        -- Read ':' delimiter
        idx = self:_nextChar(str, idx, spaceChars, true)
        if str:sub(idx, idx) ~= ':' then
            return self:_error(str, idx, 'expected `:` after key')
        end

        -- Read value
        idx = self:_nextChar(str, idx + 1, spaceChars, true)
        success, val, idx = self:_parse(str, idx)

        if not success then
            return success --[[@as any]], val --[[@as string]], idx
        end

        -- Set
        res[key] = val

        -- Next token
        idx = self:_nextChar(str, idx, spaceChars, true)
        local chr = str:sub(idx, idx)
        idx = idx + 1

        if chr == '}' then
            break
        elseif chr ~= ',' then
            return self:_error(str, idx - 1, 'expected `}` or `,`')
        end
    end

    return true, res, idx
end

---Parses a string from JSON.
---@param str string
---@param idx integer
---@return boolean success
---@return string resultOrError
---@return integer index
---@protected
function Decoder:_parseString(str, idx)
    local res = ''
    local j = idx + 1
    local k = j

    while j <= #str do
        local x = str:byte(j)

        if x < 32 then
            return self:_error(str, j, 'control character in string')
        elseif x == 92 then -- `\`: Escape
            res = res .. str:sub(k, j - 1)
            j = j + 1
            local c = str:sub(j, j)
            if c == 'u' then
                local parsed, hex = core.parseUnicodeEscape(str, true, j - 1)
                if not parsed then
                    return self:_error(str, j - 1, 'invalid unicode escape in string')
                end

                res = res .. parsed
                j = j + #hex - 2
            else
                if not escapeCharMap[c] then
                    return self:_error(str, j - 1, 'invalid escape char `' .. c .. '` in string')
                end

                res = res .. escapeCharMap[c]
            end

            k = j + 1
        elseif x == 34 then -- `"`: End of string
            res = res .. str:sub(k, j - 1)
            return true, res, j + 1
        end

        j = j + 1
    end

    return self:_error(str, idx, 'expected closing quote for string')
end


---Creates a new decoder.
---@param options Args.JSONDecoder?
---@return json.Decoder
function Decoder:new(options)
    local this = core.new(self)

    options = options or {}
    this._null = options.null

    this._conversionMap = {
        ['"'] = this._parseString,
        ['0'] = this._parseNumber,
        ['1'] = this._parseNumber,
        ['2'] = this._parseNumber,
        ['3'] = this._parseNumber,
        ['4'] = this._parseNumber,
        ['5'] = this._parseNumber,
        ['6'] = this._parseNumber,
        ['7'] = this._parseNumber,
        ['8'] = this._parseNumber,
        ['9'] = this._parseNumber,
        ['-'] = this._parseNumber,
        ['t'] = this._parseLiteral,
        ['f'] = this._parseLiteral,
        ['n'] = this._parseLiteral,
        ['['] = this._parseArray,
        ['{'] = this._parseObject,
    }

    return this
end


return Decoder

--#region Type Definitions

---@class Args.JSONDecoder
---@field null? any The value to use for `null` values.

---@alias json.Decoder.ConversionFunction fun(...): boolean, any, integer

--#endregion
