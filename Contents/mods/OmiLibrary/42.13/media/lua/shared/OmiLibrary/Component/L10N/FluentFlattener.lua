---Flattener for fluent messages.
---Handles early evaluation of messages to avoid full resolution every time a message is retrieved.
---@namespace omi.l10n
---@using omi
---@using omi.l10n.fluent
---@diagnostic disable: access-invisible

local core = require 'OmiLibrary/Module/Utils'
local FluentNone = require 'OmiLibrary/Component/L10N/FluentTypes/None'
local Resolver = require 'OmiLibrary/Component/L10N/FluentResolver'

local type = type
local tostring = tostring
local concat = table.concat

---@class FluentFlattener : FluentResolver
---@field protected _messages table<string, Message> Messages from the resource.
---@field protected _terms table<string, Message> Terms from the resource.
local Flattener = Resolver:derive('Flattener')


---Flattens all messages in the provided bundle.
---@param skipIDs SetTable<string>? A set of message IDs to skip.
function Flattener:flattenBundle(skipIDs)
    skipIDs = skipIDs or {}
    local bundle = self.bundle

    for k, message in pairs(bundle._messages) do
        if not skipIDs[k] then
            message = core.deepcopy(message)
            self:_flattenMessage(message)

            bundle._messages[k] = message
        end
    end
end

---Flattens the messages in the provided resource.
---@param resource FluentResource The resource to flatten.
---@return FluentResource flattened
function Flattener:flattenResource(resource)
    resource = core.deepcopy(resource)

    -- collect messages and terms from resource
    local toFlatten = {} ---@type Message[]
    for i = 1, #resource.body do
        local msg = resource.body[i]
        if msg.id:sub(1, 1) == '-' then
            self._terms[msg.id] = msg
        else
            self._messages[msg.id] = msg
            toFlatten[#toFlatten + 1] = msg
        end
    end

    -- flatten resource messages
    for i = 1, #toFlatten do
        self:_flattenMessage(toFlatten[i])
    end

    return resource
end

---Returns a flag for whether the resolver is performing early evaluation.
---This should be checked in functions that always rely on runtime values.
---@return boolean
function Flattener:isEarlyEvaluation()
    return true
end



---Flattens a message's value and attributes, converting them to strings if possible.
---@param message Message
---@private
function Flattener:_flattenMessage(message)
    if message.value then
        message.value = self:_flattenPattern(message.value)
    end

    for k, v in pairs(message.attributes) do
        message.attributes[k] = self:_flattenPattern(v)
    end
end

---Flattens a pattern, converting it into a string if possible.
---@param pattern Pattern
---@return Pattern
---@private
function Flattener:_flattenPattern(pattern)
    if type(pattern) == 'string' then
        return pattern
    end

    -- reset state for overflow check
    self.placeables = 0

    local textRun = {} ---@type string[]
    local elements = {} ---@type PatternElement[]

    for i = 1, #pattern do
        local el = pattern[i]
        if type(el) == 'string' then
            textRun[#textRun + 1] = el
        else
            local failed = false

            local resolved = self:_resolveExpression(el)
            if type(resolved) == 'string' then
                textRun[#textRun + 1] = resolved
            elseif core.isinstance(resolved, FluentNone) then
                failed = true
            else
                local converted = resolved:convert()
                if core.isinstance(converted, FluentNone) then
                    failed = true
                else
                    textRun[#textRun + 1] = converted
                end
            end

            if failed then
                if #textRun > 0 then
                    elements[#elements + 1] = concat(textRun)
                    textRun = {}
                end

                elements[#elements + 1] = el
            end
        end
    end

    if #elements == 0 then
        return concat(textRun)
    end

    if #textRun > 0 then
        elements[#elements + 1] = concat(textRun)
    end

    return elements
end

---Resolves arguments for a call expression.
---@param args (Expression | NamedArgument)[]
---@return FluentValue[]? positional
---@return table<string, FluentValue>? named
---@protected
function Flattener:_getArguments(args)
    local positional = {}
    local named = {}

    for i = 1, #args do
        local argument = args[i]
        local resolved
        if argument.type == 'namedArg' then
            resolved = self:_resolveExpression(argument.value)
            named[argument.name] = resolved
        else
            resolved = self:_resolveExpression(argument)
            positional[#positional + 1] = resolved
        end

        if core.isinstance(resolved, FluentNone) then
            return
        end
    end

    return positional, named
end

---Gets a message by ID.
---@param id string
---@return Message?
---@protected
function Flattener:_getMessage(id)
    return self._messages[id] or self.bundle._messages[id]
end

---Gets a term by ID.
---@param id string
---@return Message?
---@protected
function Flattener:_getTerm(id)
    return self._terms[id] or self.bundle._terms[id]
end

---Inner logic for `resolveComplex`.
---@param pattern ComplexPattern The pattern to resolve.
---@return string[]?
---@protected
function Flattener:_resolveComplexInner(pattern)
    local result = {}
    for i = 1, #pattern do
        local el = pattern[i]
        if type(el) == 'string' then
            result[#result + 1] = el
        else
            self.placeables = self.placeables + 1
            if self.placeables > self.MAX_PLACEABLES then
                self:reportError(
                    'Too many placeables; expected max of %d, got %d',
                    self.MAX_PLACEABLES,
                    self.placeables
                )

                return
            end

            local resolved = self:_resolveExpression(el)
            if core.isinstance(resolved, FluentNone) then
                return
            end

            result[#result + 1] = tostring(resolved)
        end
    end

    return result
end

---Resolves a reference to a message.
---@param ref MessageReference
---@return FluentValue
---@protected
---@diagnostic disable-next-line: unused
function Flattener:_resolveMessageReference(ref)
    -- avoid flattening message references
    -- messages can be overriden, so they should remain dynamic
    return FluentNone:new()
end

---Resolves a value for a select expression when the selector is `FluentNone`.
---@param expr SelectExpression
---@return FluentValue
---@protected
---@diagnostic disable-next-line: unused
function Flattener:_resolveSelectExpressionNone(expr)
    return FluentNone:new()
end


---Creates a new flattener object.
---@param bundle FluentBundle The bundle containing the resource.
function Flattener:new(bundle)
    local this = core.new(self, Resolver.new, bundle)

    this._terms = {}
    this._messages = {}
    this._silentUnknown = true

    return this
end


return Flattener
