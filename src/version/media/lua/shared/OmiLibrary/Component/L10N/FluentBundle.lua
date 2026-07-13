---Structure for resolving localization entries.
---@namespace omi.l10n
---@using omi
---@using omi.l10n.fluent

local core = require 'OmiLibrary/Module/Utils'
local FluentResolver = require 'OmiLibrary/Component/L10N/FluentResolver'
local FluentFlattener = require 'OmiLibrary/Component/L10N/FluentFlattener'

local type = type
local tostring = tostring

---@class FluentBundle : Class
---@field name string The name of the bundle.
---@field locale string Language tag representing the locale of the bundle.
---@field log Logger? Logger for logging format errors.
---@field protected _messages table<string, Message> Messages stored in the bundle.
---@field protected _terms table<string, Message> Terms stored in the bundle.
---@field protected _functions table<string, FluentFunction> Functions callable from messages and terms.
---@field protected _resolver FluentResolver Resolver used for formatting patterns.
local FluentBundle = core.class('FluentBundle')


---Adds messages and terms from a resource.
---@param resource FluentResource The resource to add.
---@param flatten boolean? Flag for whether flattening should occur. Defaults to `true`.
function FluentBundle:addResource(resource, flatten)
    if flatten ~= false then
        local flattener = FluentFlattener:new(self)
        resource = flattener:flattenResource(resource)
    end

    for i = 1, #resource.body do
        local msg = resource.body[i]
        if msg.id:sub(1, 1) == '-' then
            self._terms[msg.id] = msg
        else
            self._messages[msg.id] = msg
        end
    end
end

---Flattens all messages in the bundle.
---@param skipIDs SetTable<string>? A set of message IDs to skip.
function FluentBundle:flatten(skipIDs)
    local flattener = FluentFlattener:new(self)
    flattener:flattenBundle(skipIDs)
end

---Gets a message from the bundle.
---@param id string The message ID.
---@return Message?
function FluentBundle:getMessage(id)
    return self._messages[id]
end

---Gets a message from the bundle.
---@param id string The message ID to check.
---@return boolean
function FluentBundle:hasMessage(id)
    return self._messages[id] ~= nil
end

---Returns an iterator over bundle messages.
---@return fun(): string, Message
function FluentBundle:messages()
    return pairs(self._messages)
end

---Formats a pattern into a string.
---@param pattern Pattern The pattern to format.
---@param args table<string, FluentVariable?>? Arguments for message formatting.
---@return string result The result of formatting.
---@return string[]? errors Errors that occurred during formatting.
function FluentBundle:formatPattern(pattern, args)
    if type(pattern) == 'string' then
        -- simple string pattern → nothing to format
        return pattern
    end

    local value = self._resolver:resolveComplex(pattern, args)
    local errors = self._resolver.errors

    if #errors > 0 then
        return tostring(value), errors
    end

    return tostring(value)
end

---Creates a new bundle.
---@param options Args.FluentBundle? Options for the bundle.
---@return FluentBundle
function FluentBundle:new(options)
    local this = core.new(self)

    options = options or {} --[[@as Args.FluentBundle]]
    this.name = options.name or '?'
    this.locale = options.locale or 'en'
    this.log = options.logger

    this._terms = {}
    this._messages = {}
    this._resolver = FluentResolver:new(this)
    this._functions = core.copy(options.functions)

    return this
end


return FluentBundle

--#region Type Definitions

---@class Args.FluentBundle
---@field name? string The name of the bundle. Defaults to `'?'`.
---@field locale? string The language tag that represents the bundle's locale. Defaults to `'en'`.
---@field logger? Logger Logger to use to log errors.
---@field functions? table<string, FluentFunction> Functions that should be available to the bundle in addition to built-in functions.
---@field flatten? boolean Flag for whether added resources should be flattened. Defaults to `true`.

--#endregion
