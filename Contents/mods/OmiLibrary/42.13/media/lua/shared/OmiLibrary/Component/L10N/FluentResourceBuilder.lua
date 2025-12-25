---Helper for building a FluentResource from an AST.
---@namespace omi.l10n
---@using omi
---@using omi.l10n.fluent

local core = require 'OmiLibrary/Module/Utils'
local log = require 'OmiLibrary/Component/Logging/LibraryLogger'

local concat = table.concat
local format = string.format


---@class FluentResourceBuilder : Class
---@field ast AST.Resource The AST to convert into a resource.
---@field global boolean Flag for whether the resource should be added to the global bundle.
---@field bundle string? The target bundle of the resource.
---@field newlinesToSpaces boolean Flag for whether newlines should be converted to spaces.
local Builder = core.class('FluentResourceBuilder')


---Builds the resource.
---@param resource FluentResource
---@return FluentResource resource
function Builder:build(resource)
    local ast = self.ast

    local errors = {} ---@type string[]

    local body = resource.body
    for i = 1, #ast.body do
        local entry = ast.body[i]

        if entry.type == 'Message' or entry.type == 'Term' then
            body[#body + 1] = self:_convertMessage(entry --[[@as AST.Message | AST.Term]])
        elseif entry.type == 'ResourceComment' then
            self:_parseResourceAnnotations(entry --[[@as AST.ResourceComment]])
        elseif entry.type == 'Junk' then
            ---@cast entry AST.Junk
            local annotations = entry.annotations

            for j = 1, #annotations do
                local annot = annotations[j]
                local line, col = core.getLineAndColumn(ast.source, annot.range[1])
                errors[#errors + 1] = format('%s at line %d col %d', annot.message, line, col)
            end
        end
    end

    resource.global = self.global
    if not resource.global then
        resource.bundle = self.bundle
    end

    if #errors > 0 then
        local filename = resource.filename

        local errorsStr = #errors == 1 and 'Error' or 'Errors'
        local resourceStr = filename and ('resource ' .. filename) or 'loaded resource'
        local msg = { errorsStr .. ' in ' .. resourceStr .. ':' }

        for i = 1, #errors do
            msg[i + 1] = errors[i]
        end

        log.warn(concat(msg, #errors > 1 and '\n\t\t' or ' '))
    end

    return resource
end


---Converts an AST argument list into a simplified structure.
---@param args AST.CallArguments The argument list.
---@return (Expression | NamedArgument)[] converted
---@protected
function Builder:_convertArguments(args)
    local list = {} ---@type (Expression | NamedArgument)[]

    for i = 1, #args.positional do
        list[#list + 1] = self:_convertExpression(args.positional[i])
    end

    for i = 1, #args.named do
        local namedArg = args.named[i]
        local literal = self:_convertExpression(namedArg.value) --[[@as Literal]]

        list[#list + 1] = {
            type = 'namedArg',
            name = namedArg.name.name,
            value = literal,
        }
    end

    return list
end

---Converts an AST message or term into a simplified structure.
---@param entry AST.Message | AST.Term The message or term to convert.
---@return Message converted
---@protected
function Builder:_convertMessage(entry)
    local attributes = {} ---@type table<string, Pattern>

    for i = 1, #entry.attributes do
        local attr = entry.attributes[i]
        attributes[attr.id.name] = self:_convertPattern(attr.value)
    end

    local id = entry.id.name
    if entry.type == 'Term' then
        id = '-' .. id
    end

    return {
        id = id,
        value = entry.value and self:_convertPattern(entry.value),
        attributes = attributes,
    }
end

---Converts escapes in a string literal.
---@param value string
---@return string
---@protected
function Builder:_convertEscapes(value)
    local i = 1
    local rope = {}

    local backslash = value:find('\\', i, true)
    while backslash do
        rope[#rope + 1] = value:sub(i, backslash - 1)

        local basic = value:sub(backslash + 1, backslash + 1)
        if basic == '"' or basic == '\\' then
            rope[#rope + 1] = basic
            i = backslash + 2
        else
            local parsed, matched = core.parseUnicodeEscape(value, false, backslash)
            if parsed then
                rope[#rope + 1] = parsed
                i = i + #matched
            else
                rope[#rope + 1] = '\\'
                i = i + 1
            end
        end

        backslash = value:find('\\', i, true)
    end

    if i <= #value then
        rope[#rope + 1] = value:sub(i)
    end

    return concat(rope)
end

---Converts an AST expression into a simplified structure.
---@param expr AST.Expression The expression to convert.
---@return Expression converted
---@protected
function Builder:_convertExpression(expr)
    if expr.type == 'Placeable' then
        ---@cast expr AST.Placeable
        return self:_convertExpression(expr.expression)
    elseif expr.type == 'FunctionReference' then
        ---@cast expr AST.FunctionReference
        return {
            type = 'func',
            name = expr.id.name,
            args = expr.arguments and self:_convertArguments(expr.arguments),
        }
    elseif expr.type == 'MessageReference' then
        ---@cast expr AST.MessageReference
        return {
            type = 'message',
            name = expr.id.name,
            attr = expr.attribute and expr.attribute.name,
        }
    elseif expr.type == 'TermReference' then
        ---@cast expr AST.TermReference
        return {
            type = 'term',
            name = expr.id.name,
            attr = expr.attribute and expr.attribute.name,
            args = expr.arguments and self:_convertArguments(expr.arguments) or {},
        }
    elseif expr.type == 'VariableReference' then
        ---@cast expr AST.VariableReference
        return {
            type = 'var',
            name = expr.id.name,
        }
    elseif expr.type == 'StringLiteral' then
        ---@cast expr AST.StringLiteral
        return {
            type = 'str',
            value = self:_convertEscapes(expr.value),
        }
    elseif expr.type == 'NumberLiteral' then
        ---@cast expr AST.NumberLiteral
        local num = tonumber(expr.value) or 0

        local precision = 0
        local period = expr.value:find('.', 1, true)
        if period then
            precision = #expr.value:sub(period + 1)
        end

        return {
            type = 'num',
            value = num,
            precision = precision,
        }
    elseif expr.type == 'SelectExpression' then
        ---@cast expr AST.SelectExpression
        local variants = {}

        local defaultIndex = 1
        for i = 1, #expr.variants do
            local variant = expr.variants[i]

            local key
            if variant.key.type == 'Identifier' then
                key = {
                    type = 'str',
                    value = variant.key.name,
                }
            else
                key = self:_convertExpression(variant.key)
            end

            if variant.default then
                defaultIndex = i
            end

            variants[#variants + 1] = {
                key = key,
                value = self:_convertPattern(variant.value),
            }
        end

        return {
            type = 'select',
            selector = self:_convertExpression(expr.selector),
            variants = variants,
            defaultIndex = defaultIndex,
        }
    end

    error('Unrecognized expression type: ' .. tostring(expr.type))
end

---Converts an AST pattern into a simplified structure.
---@param pattern AST.Pattern The pattern to convert.
---@return Pattern converted
---@protected
function Builder:_convertPattern(pattern)
    local textRun = {} ---@type string[]
    local elements = {} ---@type PatternElement[]
    for i = 1, #pattern.elements do
        local el = pattern.elements[i]

        if el.type == 'TextElement' then
            ---@cast el AST.TextElement
            textRun[#textRun + 1] = el.value
        else
            ---@cast el AST.Placeable
            if #textRun > 0 then
                local value = concat(textRun)
                if self.newlinesToSpaces then
                    value = value:gsub('\n', ' ')
                end

                textRun = {}
                elements[#elements + 1] = value
            end

            elements[#elements + 1] = self:_convertExpression(el.expression)
        end
    end

    if #textRun > 0 then
        local value = concat(textRun)
        if self.newlinesToSpaces then
            value = value:gsub('\n', ' ')
        end

        elements[#elements + 1] = value
    end

    local foundNonString = false
    for i = 1, #elements do
        if type(elements[i]) ~= 'string' then
            foundNonString = true
            break
        end
    end

    if not foundNonString then
        return concat(elements)
    end

    return elements
end

---Handles annotations in a resource comment.
---@param entry AST.ResourceComment
function Builder:_parseResourceAnnotations(entry)
    local text = entry.content
    local matches = {} ---@type string[]
    for line in text:gmatch('[^\n]+\n?') do
        line = line:trim()
        if line:sub(1, 1) == '@' then
            matches[#matches + 1] = line
        end
    end

    for i = 1, #matches do
        local value = ''
        local annot = matches[i]
        local space = annot:find(' ')

        if space then
            value = annot:sub(space + 1):trim()
            annot = annot:sub(1, space - 1)
        end

        if annot == '@preserve-newlines' then
            self.newlinesToSpaces = value:lower() == 'false'
        elseif annot == '@global' then
            self.global = true
        elseif annot == '@bundle' then
            self.bundle = value ~= '' and value or nil
        end
    end
end


---Creates a new resource builder.
---@param ast AST.Resource
---@return FluentResourceBuilder
function Builder:new(ast)
    local this = core.new(self)

    this.ast = ast
    this.global = false
    this.newlinesToSpaces = true

    return this
end


return Builder
