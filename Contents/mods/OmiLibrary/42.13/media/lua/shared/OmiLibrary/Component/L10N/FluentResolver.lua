---Base resolver for fluent messages.
---@namespace omi.l10n
---@using omi
---@using omi.l10n.fluent
---@diagnostic disable: access-invisible

local core = require 'OmiLibrary/Module/Utils'
local l10n = require 'OmiLibrary/Module/Core/L10N'
local builtin = require 'OmiLibrary/Module/L10N/FluentBuiltins'
local FluentNone = require 'OmiLibrary/Component/L10N/FluentTypes/None'
local FluentNumber = require 'OmiLibrary/Component/L10N/FluentTypes/Number'
local FluentDateTime = require 'OmiLibrary/Component/L10N/FluentTypes/DateTime'
local FluentType = require 'OmiLibrary/Component/L10N/FluentTypes/Type'
local PluralRules = require 'OmiLibrary/Component/L10N/PluralRules'

local type = type
local concat = table.concat
local format = string.format

---@class FluentResolver : Class
---@field bundle FluentBundle The bundle for which resolution is occurring.
---@field errors string[] The list of errors encountered during resolution.
---@field args table<string, FluentVariable?> Arguments provided for resolution.
---@field dirty SetTable<Pattern> Patterns that are currently being resolved, to prevent cycles.
---@field placeables integer The number of placeables seen so far, to detect overloading the resolution.
---@field params? table<string, FluentValue> Current table of parameters for term reference resolution.
---@field protected _paramsStack table<string, FluentValue>[] Stack of param tables for term references.
---@field protected _silentUnknown boolean? Flag to silence errors for unknown elements.
local Resolver = core.class('FluentResolver')


---The maximum number of placeables that can be expanded before aborting.
---@protected
Resolver.MAX_PLACEABLES = 100


---Returns a flag for whether the resolver is performing early evaluation.
---This should be checked in functions that always rely on runtime values.
---@return boolean
function Resolver:isEarlyEvaluation()
    return false
end

---Adds an error to the resolution context.
---@param err string The error string.
---@param ...any Format arguments for the string.
function Resolver:reportError(err, ...)
    self.errors[#self.errors + 1] = format(err, ...)
end

---Clears outdated information from the resolver.
---@param args table? New arguments for the resolver.
---Arguments are set to an empty table if not provided.
function Resolver:reset(args)
    self.args = args or {}
    self.errors = {}
    self.dirty = {}
    self.placeables = 0

    self.params = nil
    self._paramsStack = {}
end

---Resolves a Fluent pattern.
---@param pattern Pattern The pattern to resolve.
---@param args table? Arguments for resolution. Defaults to an empty table.
---@return FluentValue resolved
function Resolver:resolve(pattern, args)
    self:reset(args)
    return self:_resolve(pattern)
end

---Resolves a Fluent complex pattern.
---@param pattern ComplexPattern The pattern to resolve.
---@param args table? Arguments for resolution. Defaults to an empty table.
---@return FluentValue resolved
function Resolver:resolveComplex(pattern, args)
    self:reset(args)
    return self:_resolveComplex(pattern)
end


---Resolves arguments for a call expression.
---@param args (Expression | NamedArgument)[]
---@return FluentValue[]? positional
---@return table<string, FluentValue>? named
---@protected
function Resolver:_getArguments(args)
    local positional = {}
    local named = {}

    for i = 1, #args do
        local argument = args[i]
        if argument.type == 'namedArg' then
            named[argument.name] = self:_resolveExpression(argument.value)
        else
            positional[#positional + 1] = self:_resolveExpression(argument)
        end
    end

    return positional, named
end

---Gets the default variant of a selector.
---@param expr SelectExpression
---@return FluentValue
---@protected
function Resolver:_getDefaultVariant(expr)
    local variants = expr.variants
    local defaultIdx = expr.defaultIndex

    local defaultVariant = variants[defaultIdx]
    if not defaultVariant then
        self:reportError('No default variant')
        return FluentNone:new()
    end

    return self:_resolve(defaultVariant.value)
end

---Gets a message by ID.
---@param id string
---@return Message?
---@protected
function Resolver:_getMessage(id)
    return self.bundle._messages[id]
end

---Gets a term by ID.
---@param id string
---@return Message?
---@protected
function Resolver:_getTerm(id)
    return self.bundle._terms[id]
end

---Matches a variant selector against a key.
---@param selector FluentValue
---@param key FluentValue
---@return boolean
---@protected
function Resolver:_matchVariant(selector, key)
    if selector == key then
        return true
    end

    local isSelectorNum = core.isinstance(selector, FluentNumber)
    if isSelectorNum and core.isinstance(key, FluentNumber) then
        return selector.value == key.value
    end

    if isSelectorNum and type(key) == 'string' then
        ---@cast selector FluentNumber

        local opts = core.copy(selector.options) --[[@as Args.PluralRules]]
        opts.locale = self.bundle.locale

        if key == PluralRules.fromOptions(opts):select(selector.value) then
            return true
        end
    end

    return false
end

---Resolves a Fluent pattern.
---@param pattern Pattern The pattern to resolve.
---@return FluentValue resolved
---@protected
function Resolver:_resolve(pattern)
    if type(pattern) == 'string' then
        return pattern
    end

    return self:_resolveComplex(pattern)
end

---Resolves a Fluent complex pattern.
---@param pattern ComplexPattern The pattern to resolve.
---@return FluentValue resolved
---@protected
function Resolver:_resolveComplex(pattern)
    if self.dirty[pattern] then
        self:reportError('Cyclic reference')
        return FluentNone:new()
    end

    self.dirty[pattern] = true

    local result = self:_resolveComplexInner(pattern)
    if not result then
        return FluentNone:new()
    end

    self.dirty[pattern] = nil
    return concat(result)
end

---Inner logic for `resolveComplex`.
---@param pattern ComplexPattern The pattern to resolve.
---@return string[]?
---@protected
function Resolver:_resolveComplexInner(pattern)
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
            result[#result + 1] = tostring(resolved)
        end
    end

    return result
end

---Resolves an expression.
---@param expr Expression
---@return FluentValue
---@protected
function Resolver:_resolveExpression(expr)
    if expr.type == 'str' then
        ---@cast expr StringLiteral
        return expr.value
    elseif expr.type == 'num' then
        ---@cast expr NumberLiteral
        local opts = expr.precision > 0 and { minimumFractionDigits = expr.precision } or nil

        return FluentNumber:new(expr.value, opts)
    elseif expr.type == 'var' then
        ---@cast expr VariableReference
        return self:_resolveVariableReference(expr)
    elseif expr.type == 'message' then
        ---@cast expr MessageReference
        return self:_resolveMessageReference(expr)
    elseif expr.type == 'term' then
        ---@cast expr TermReference
        return self:_resolveTermReference(expr)
    elseif expr.type == 'func' then
        ---@cast expr FunctionReference
        return self:_resolveFunctionReference(expr)
    elseif expr.type == 'select' then
        ---@cast expr SelectExpression
        return self:_resolveSelectExpression(expr)
    end

    return FluentNone:new()
end

---Resolves a function call.
---@param ref FunctionReference
---@return FluentValue
---@protected
function Resolver:_resolveFunctionReference(ref)
    local name = ref.name
    local func = self.bundle._functions[name] or builtin.functions[name]
    if not func then
        name = name .. '()'

        if not self._silentUnknown then
            self:reportError('Unknown function: %s', name)
        end

        return FluentNone:new(name)
    end

    local positional, named = self:_getArguments(ref.args)
    if not positional or not named then
        return FluentNone:new()
    end

    local result, err = func(positional, named, self)
    if err then
        self:reportError(err)
        return FluentNone:new(name .. '()')
    end

    return result
end

---Resolves a reference to a message.
---@param ref MessageReference
---@return FluentValue
---@protected
function Resolver:_resolveMessageReference(ref)
    local name = ref.name
    local msg = self:_getMessage(name)
    if not msg then
        if not self._silentUnknown then
            self:reportError('Unknown message: %s', name)
        end

        return FluentNone:new(name)
    end

    if ref.attr then
        local attr = msg.attributes[ref.attr]
        if not attr then
            if not self._silentUnknown then
                self:reportError('Unknown attribute: %s', ref.attr)
            end

            return FluentNone:new(name .. '.' .. ref.attr)
        end

        return self:_resolve(attr)
    end

    if msg.value then
        return self:_resolve(msg.value)
    end

    self:reportError('No value: %s', name)
    return FluentNone:new(name)
end

---Resolves a select expression.
---@param expr SelectExpression
---@return FluentValue
---@protected
function Resolver:_resolveSelectExpression(expr)
    local selector = self:_resolveExpression(expr.selector)
    if core.isinstance(selector, FluentNone) then
        return self:_resolveSelectExpressionNone(expr)
    end

    local variants = expr.variants
    for i = 1, #variants do
        local variant = variants[i]
        local key = self:_resolveExpression(variant.key)
        if self:_matchVariant(selector, key) then
            return self:_resolve(variant.value)
        end
    end

    return self:_getDefaultVariant(expr)
end

---Resolves a value for a select expression when the selector is `FluentNone`.
---@param expr SelectExpression
---@return FluentValue
---@protected
function Resolver:_resolveSelectExpressionNone(expr)
    return self:_getDefaultVariant(expr)
end

---Resolves a reference to a term.
---@param ref TermReference
---@return FluentValue
---@protected
function Resolver:_resolveTermReference(ref)
    local id = '-' .. ref.name
    local term = self:_getTerm(id)
    if not term then
        if not self._silentUnknown then
            self:reportError('Unknown term: %s', id)
        end

        return FluentNone:new(id)
    end

    if ref.attr then
        local attr = term.attributes[ref.attr]
        if not attr then
            if not self._silentUnknown then
                self:reportError('Unknown attribute: %s', ref.attr)
            end

            return FluentNone:new(id .. '.' .. ref.attr)
        end

        local _, params = self:_getArguments(ref.args)
        if not params then
            return FluentNone:new()
        end

        self.params = params
        self._paramsStack[#self._paramsStack + 1] = params

        local resolved = self:_resolve(attr)
        self._paramsStack[#self._paramsStack] = nil
        self.params = self._paramsStack[#self._paramsStack]

        return resolved
    end

    local _, params = self:_getArguments(ref.args)
    if not params then
        return FluentNone:new()
    end

    self.params = params
    self._paramsStack[#self._paramsStack + 1] = params

    local resolved = self:_resolve(term.value --[[@as string]])
    self._paramsStack[#self._paramsStack] = nil
    self.params = self._paramsStack[#self._paramsStack]

    return resolved
end

---Resolves a variable reference.
---@param ref VariableReference
---@return FluentValue
---@protected
function Resolver:_resolveVariableReference(ref)
    local name = ref.name

    ---@type FluentVariable
    local var

    if self.params then
        -- inside a term reference → check for param
        if self.params[name] then
            var = self.params[name]
        else
            return FluentNone:new('$' .. name)
        end
    else
        local varVal = self.args[name]
        if not varVal then
            if not self._silentUnknown then
                self:reportError('Missing variable: $%s', name)
            end

            return FluentNone:new('$' .. name)
        end

        var = varVal
    end

    if core.isinstance(var, FluentType) then
        return var
    end

    local varType = type(var)
    if varType == 'string' then
        return var
    elseif varType == 'number' then
        return FluentNumber:new(var --[[@as number]])
    elseif l10n.isDateLike(var) then
        return FluentDateTime:new(var)
    end

    self:reportError('Variable type not supported: $%s, %s', name, varType)
    return FluentNone:new('$' .. name)
end


---Creates a new resolver object.
---@param bundle FluentBundle The bundle for resolution.
---@return FluentResolver
function Resolver:new(bundle)
    local this = core.new(self)

    this.bundle = bundle
    this:reset()

    return this
end

return Resolver
