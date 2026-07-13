---Handles string interpolation.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local Cache = require 'OmiLibrary/Component/Cache/Cache'
local MultiMap = require 'OmiLibrary/Component/Core/MultiMap'
local InterpolationParser = require 'OmiLibrary/Component/Interpolation/InterpolateParser'

local table = table
local newrandom = newrandom
local unpack = unpack
local NodeType = InterpolationParser.NodeType
local Libraries = require 'OmiLibrary/Component/Interpolation/Libraries'


---@class Interpolator : Class
---@field protected _tokens table The current tokens of the interpolator.
---@field protected _functions table<string, function> Mapping of interpolator-specific interpolation functions.
---@field protected _library table<string, function> Mapping of library functions.
---@field protected _allowTokens boolean Whether tokens should be interpreted.
---@field protected _allowMultiMaps boolean Whether at-maps should be interpreted.
---@field protected _allowFunctions boolean Whether functions should be interpreted.
---@field protected _allowCharacterEntities boolean Whether character entities should be interpreted.
---@field protected _checkNumericTokens boolean Whether tokens should be converted to numbers and checked again when missing.
---@field protected _caseSensitiveFunctions boolean Whether functions should be treated as case-sensitive.
---@field protected _requireCustomTokenUnderscore boolean Whether custom tokens should require a leading underscore.
---@field protected _cache Cache<InterpolatorCacheData> Cache for interpolation parsing results.
---@field protected _parser? InterpolateParser The parser used to parse interpolation string pattern.
---@field protected _rand? Random The random number generator used by random interpolation functions.
local Interpolator = core.class('Interpolator')


---Contains registered interpolation functions.
---@type table<string, function>
---@private
Interpolator._registered = {}


---Registers an interpolator function.
---@param name string The name of the new interpolation function.
---@param func InterpolatorFunction The function to execute when the interpolation function is used.
function Interpolator.register(name, func)
    Interpolator._registered[name] = func
end


---Adds additional functions that should be usable on the interpolator.
---@param libraries table<string, function> Map of names to interpolator functions.
function Interpolator:addLibraries(libraries)
    local caseInsensitive = not self._caseSensitiveFunctions
    for k, v in pairs(libraries) do
        if type(v) == 'function' then
            if caseInsensitive then
                k = k:lower()
            end

            self._library[k] = v
        end
    end
end

---Converts a value to a type that can be used in interpolation functions.
---@param value any
---@return any
function Interpolator:convert(value)
    if type(value) == 'string' then
        return value
    end

    if core.isinstance(value, MultiMap) then
        return self._allowMultiMaps and value or tostring(value)
    end

    if not value then
        return ''
    end

    return tostring(value)
end

---Converts a value to a type that can be used in interpolation functions.
---@param value number | string | boolean | table
---@return any
function Interpolator:convertLiteral(value)
    if not value then
        return ''
    end

    return tostring(value)
end

---Executes an interpolation function.
---@param name string
---@param args any[]
---@return any | nil
function Interpolator:execute(name, args)
    local func = self:getFunction(name)
    if not func then
        return
    end

    return func(self, unpack(args))
end

---Resolves a function given its name.
---@param name string
---@return function?
function Interpolator:getFunction(name)
    local func = self._functions[name] or self._library[name]
    if func then
        return func
    elseif self._caseSensitiveFunctions then
        return
    end

    name = name:lower()
    return self._functions[name] or self._library[name]
end

---Gets a copy of the current tokens table.
---@return table
function Interpolator:getTokens()
    return core.copy(self._tokens)
end

---Performs string interpolation and returns a string.
---@param text string The interpolation text.
---@param tokens table? Interpolation tokens. If excluded, an empty table will be used.
---@return string
function Interpolator:interpolate(text, tokens)
    return tostring(self:interpolateRaw(text, tokens))
end

---Performs string interpolation.
---@param text string The interpolation text.
---@param tokens table? Interpolation tokens. If excluded, an empty table will be used.
---@return any
function Interpolator:interpolateRaw(text, tokens)
    text = text or ''
    self._tokens = tokens or {}

    local data = self._cache:getRequired(text)
    local parts = {}
    local nodes = data.nodes
    for i = 1, #nodes do
        self:_evaluateNode(nodes[i], parts)
    end

    return self:_mergeParts(parts)
end

---Loads library functions into the interpolator.
---@param include SetTable<string>? A set of functions or modules to allow.
---@param exclude SetTable<string>? A set of functions or modules to disallow.
---@param additional table<string, function>? Additional functions to include.
function Interpolator:loadLibraries(include, exclude, additional)
    local caseInsensitive = not self._caseSensitiveFunctions
    self._library = Libraries:load(include, exclude, caseInsensitive)
    self:addLibraries(additional or {})
end

---Returns a random number.
---@param m integer?
---@param n integer?
---@return number
function Interpolator:random(m, n)
    self._rand = self._rand or newrandom()

    return self._rand:random(m, n)
end

---Returns a random element from a table of options.
---@param options table
---@return any | nil
function Interpolator:randomChoice(options)
    if #options == 0 then
        return
    end

    self._rand = self._rand or newrandom()
    return options[self._rand:random(#options)]
end

---Sets the random seed for this interpolator.
---@param seed any
function Interpolator:randomseed(seed)
    self._rand = self._rand or newrandom()
    self._rand:seed(seed)
end

---Sets the value of an interpolation token.
---@param token any
---@param value any
function Interpolator:setToken(token, value)
    self._tokens[token] = value
end

---Sets the value of an interpolation token with additional validation.
---This is called by the `$set` interpolator function.
---@param token any
---@param value any
function Interpolator:setTokenValidated(token, value)
    if self._requireCustomTokenUnderscore and token:sub(1, 1) ~= '_' and self:token(token) == nil then
        return
    end

    self:setToken(token, self:convert(value))
end

---Converts a value to a boolean using interpolation logic.
---@param value any
---@return boolean
function Interpolator:toBoolean(value)
    if core.isinstance(value, MultiMap) then
        value = tostring(value)
    end

    return not not (value and value ~= '')
end

---Gets the value of an interpolation token.
---@param token any
---@return any | nil
function Interpolator:token(token)
    local value = self._tokens[token]
    if value ~= nil or not self._checkNumericTokens then
        return value
    end

    local num = token and tonumber(token)
    if num then
        return self._tokens[num]
    end
end

---Gets the value of an interpolation token as a boolean, using interpolator boolean logic.
---@param token any
---@return boolean
function Interpolator:tokenBoolean(token)
    return self:toBoolean(self:token(token))
end

---Gets the value of an interpolation token as a number, or `nil` if it doesn't exist or isn't a number.
---@param token any
---@return number?
function Interpolator:tokenNumber(token)
    local value = self:token(token)
    if not value then
        return
    end

    return tonumber(value)
end

---Gets the value of an interpolation token as a string, or the empty string if the token doesn't exist.
---@param token any
---@return string
function Interpolator:tokenString(token)
    local value = self:token(token)
    return tostring(value or '')
end


---Creates an interpolator cache item.
---@param text string The interpolator text.
---@return InterpolatorCacheData
---@protected
function Interpolator:_createCacheItem(text)
    text = text or ''
    local parser = self._parser
    if not parser then
        parser = self:_createParser()
        self._parser = parser
    end

    local result = parser:parse(text)
    if not result.success then
        local list = {}

        local errors = result.errors or {} --[[@as ParserError[] ]]
        for i = 1, #errors do
            list[#list + 1] = errors[i].message
        end

        error(string.format('Failed to parse pattern `%s`: %s', text, table.concat(list, ', ')))
    end

    ---@type InterpolatorCacheData
    return {
        text = text,
        nodes = result.value or {},
    }
end

---Creates a parser for this interpolator.
---@return InterpolateParser
---@protected
function Interpolator:_createParser()
    return InterpolationParser:new({
        allowTokens = self._allowTokens,
        allowFunctions = self._allowFunctions,
        allowAtExpressions = self._allowMultiMaps,
        allowCharacterEntities = self._allowCharacterEntities,
    })
end

---Evaluates an at map expression.
---@param node interpolate.AtExpressionNode
---@return MultiMap
---@protected
function Interpolator:_evaluateAtExpression(node)
    if not node.entries or #node.entries == 0 then
        return MultiMap:new()
    end

    ---@type Entry[]
    local entries = {}
    for i = 1, #node.entries do
        local e = node.entries[i]
        local key = self:_evaluateNodeArray(e.key)
        local value = self:_evaluateNodeArray(e.value)

        if value and not e.key then
            if core.isinstance(value, MultiMap) then
                -- @(@(A;B) @(C)) → @(A;B;C)
                for entryKey, entryValue in value:pairs() do
                    if self:toBoolean(entryKey) then
                        entries[#entries + 1] = { entryKey, entryValue }
                    end
                end
            else
                -- @(A) → @(A:A)
                local keyValue = tostring(value)
                if self:toBoolean(keyValue) then
                    entries[#entries + 1] = { keyValue, value }
                end
            end
        elseif core.isinstance(key, MultiMap) then
            -- @(@(A;B): C) → @(A:C;B:C)
            for _, entryValue in key:pairs() do
                local keyValue = tostring(entryValue)
                if self:toBoolean(keyValue) then
                    entries[#entries + 1] = { keyValue, value }
                end
            end
        elseif self:toBoolean(key) then
            -- @(A:B)
            entries[#entries + 1] = { key, value }
        end
    end

    return MultiMap:new(entries)
end

---Evaluates a function call expression.
---@param node interpolate.CallNode
---@return any | nil
---@protected
function Interpolator:_evaluateCallNode(node)
    local args = {}

    for i = 1, #node.args do
        local argument = node.args[i]
        local parts = {}

        for j = 1, #argument do
            self:_evaluateNode(argument[j], parts)
        end

        args[i] = self:convert(self:_mergeParts(parts))
    end

    return self:execute(node.value, args)
end

---Evaluates a tree node.
---@param node interpolate.Node The input tree node.
---@param target table? Table to which the result will be appended.
---@return table target The table provided for `target`, or a new table.
---@protected
function Interpolator:_evaluateNode(node, target)
    target = target or {}

    local nodeType = node.type
    local result
    if nodeType == NodeType.text then
        result = node.value
    elseif self._allowTokens and nodeType == NodeType.token then
        result = self:token(node.value)
    elseif self._allowMultiMaps and nodeType == NodeType.at_expression then
        ---@cast node interpolate.AtExpressionNode
        result = self:_evaluateAtExpression(node)
    elseif self._allowFunctions and nodeType == NodeType.call then
        ---@cast node interpolate.CallNode
        result = self:_evaluateCallNode(node)
    end

    if result then
        target[#target + 1] = self:convert(result)
    end

    return target
end

---Evaluates a node array as a single expression.
---This is used to handle at-map key/value expressions.
---@param nodes interpolate.ValueNode[]
---@return any | nil
---@protected
function Interpolator:_evaluateNodeArray(nodes)
    if not nodes then
        return
    end

    local parts = {}
    for i = 1, #nodes do
        self:_evaluateNode(nodes[i], parts)
    end

    return self:_mergeParts(parts)
end

---Merges a table of parts.
---If only one part is present, it is returned as-is. Otherwise, the parts are stringified and concatenated.
---@param parts table
---@return any
---@protected
function Interpolator:_mergeParts(parts)
    if #parts == 1 then
        return parts[1]
    end

    return core.concat(parts)
end


---Creates a new interpolator.
---@param options Args.Interpolator?
---@return Interpolator
function Interpolator:new(options)
    local this = core.new(self)

    options = options or {} --[[@as Args.Interpolator]]
    this._tokens = {}
    this._library = {}
    this._functions = setmetatable({}, Interpolator._registered)
    this._checkNumericTokens = options.checkNumericTokens ~= false
    this._caseSensitiveFunctions = options.caseSensitiveFunctions ~= false
    this._allowTokens = options.allowTokens ~= false
    this._allowMultiMaps = options.allowMultiMaps ~= false
    this._allowFunctions = options.allowFunctions ~= false
    this._allowCharacterEntities = options.allowCharacterEntities ~= false
    this._requireCustomTokenUnderscore = options.requireCustomTokenUnderscore ~= false

    this._cache = Cache:new({
        primaryKey = 'text',
        ttl = options.cacheTtl,
        capacity = options.cacheCapacity or 128,
        onCreateItemTarget = this,
        onCreateItem = this._createCacheItem,
    })

    this:loadLibraries(options.libraryInclude, options.libraryExclude, options.libraryExtra)
    return this
end


return Interpolator

--#region Type Definitions

---@class Args.Interpolator : InterpolationOptions
---@field libraryInclude? SetTable<string> Set of library functions or modules to allow. If absent, all will be allowed.
---@field libraryExclude? SetTable<string> Set of library functions or modules to exclude. If absent, none will be excluded.
---@field libraryExtra? table<string, function> Set of additional library functions to include.
---@field cacheCapacity? integer Capacity to use for the interpolator cache. Defaults to `128`.
---@field cacheTtl? integer The time-to-live for cache elements, in milliseconds. By default, cache items have no time-to-live limit.


---@class InterpolationOptions
---@field allowTokens? boolean Whether tokens should be interpreted. If `false`, tokens will be treated as text. Defaults to `true`.
---@field allowMultiMaps? boolean Whether at-maps should be interpreted. If `false`, they will be treated as text. Defaults to `true`.
---@field allowFunctions? boolean Whether functions should be interpreted. If `false`, they will be treated as text. Defaults to `true`.
---@field allowCharacterEntities? boolean Whether character entities should be interpreted. If `false`, they will be treated as text. Defaults to `true`.
---@field caseSensitiveFunctions? boolean Whether functions should be treated as case-sensitive. Defaults to `true`.
---@field checkNumericTokens? boolean Whether tokens should be converted to numbers and checked again when missing. Defaults to `true`.
---@field requireCustomTokenUnderscore? boolean Whether custom tokens should require a leading underscore. Defaults to `true`.

---@class InterpolatorCacheData
---@field text string The interpolation text.
---@field nodes interpolate.Node[] The result of parsing the interpolation string pattern.


---@alias InterpolatorFunction fun(interpolator: Interpolator, ...: any)

--#endregion
