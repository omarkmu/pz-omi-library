---Parser for Fluent resources.
---Based on the implementation in fluent.js.
---@namespace omi.l10n
---@using omi
---@using omi.l10n
---@diagnostic disable: preferred-local-alias

local core = require 'OmiLibrary/Module/Utils'
local set = require 'OmiLibrary/Module/Set'
local BaseParser = require 'OmiLibrary/Component/Core/Parser'
local ParseError = require 'OmiLibrary/Component/L10N/FluentParseError'

local EOF = ''
local EOL = '\n'
local INF = math.huge --[[@as integer]]
local concat = table.concat

local SPECIAL_LINE_START_CHARS = set.table { '}', '.', '[', '*' }


---@class FluentParser : Parser<AST.Node>
---@field protected _entries AST.Node[] The nodes read during parsing.
local Parser = BaseParser:derive('Parser')


---@enum FluentNodeType
Parser.NodeType = {
    Resource = 'Resource',
    Message = 'Message',
    Term = 'Term',
    Identifier = 'Identifier',
    Attribute = 'Attribute',
    Pattern = 'Pattern',
    TextElement = 'TextElement',
    Placeable = 'Placeable',
    SelectExpression = 'SelectExpression',
    Variant = 'Variant',
    StringLiteral = 'StringLiteral',
    NumberLiteral = 'NumberLiteral',
    FunctionReference = 'FunctionReference',
    MessageReference = 'MessageReference',
    TermReference = 'TermReference',
    VariableReference = 'VariableReference',
    CallArguments = 'CallArguments',
    NamedArgument = 'NamedArgument',
    Junk = 'Junk',
    Annotation = 'Annotation',
    Comment = 'Comment',
    GroupComment = 'GroupComment',
    ResourceComment = 'ResourceComment',
}

local NodeType = Parser.NodeType


---Performs parsing and returns a resource.
---@param source string The source string to parse.
---@return AST.Resource resource
function Parser:parse(source)
    self:reset(source)
    self:perform()

    local entries = self._entries
    self._entries = nil

    return self:createNode(NodeType.Resource, {
        body = entries,
        source = self._text,
        range = { 1, #self._text },
    })
end

---Performs the parsing operation.
---@protected
function Parser:perform()
    self:skipBlankBlock()

    local lastComment ---@type AST.Comment?
    while self:hasNext() do
        local entry = self:getEntryOrJunk()
        local blankLines = self:skipBlankBlock()

        -- save comment to attach to a message or term
        if entry.type == 'Comment' and #blankLines == 0 and self:hasNext() then
            lastComment = entry --[[@as AST.Comment]]
        elseif lastComment then
            if entry.type == 'Message' or entry.type == 'Term' then
                entry.comment = lastComment
                entry.range[1] = lastComment.range[1]
            else
                self._entries[#self._entries + 1] = lastComment
            end

            lastComment = nil
            self._entries[#self._entries + 1] = entry
        else
            self._entries[#self._entries + 1] = entry
        end
    end
end

---Resets the parser state.
---@param text string? If provided, sets the text to parse.
---@protected
function Parser:reset(text)
    self._entries = {}
    BaseParser.reset(self, text)
end


---Creates a new node.
---@param type FluentNodeType The node type.
---@param node table? The table to use for the node.
---@return AST.Node
---@protected
function Parser:createNode(type, node)
    if node and node.range and not node.range[2] then
        node.range[2] = self._ptr - 1
    end

    return BaseParser.createNode(self, type, node) --[[@as AST.Node]]
end

---Dedents text elements by their common indentation.
---Also, merges indents into text elements.
---@param elements (AST.PatternElement | AST.Indent)[]
---@param commonIndent integer
---@return AST.PatternElement[] elements
---@protected
function Parser:dedent(elements, commonIndent)
    local trimmed = {} ---@type AST.PatternElement[]

    for i = 1, #elements do
        local el = elements[i]
        if el.type == 'Placeable' then
            ---@cast el AST.Placeable
            trimmed[#trimmed + 1] = el
        else
            ---@cast el -AST.Placeable
            if el.type == 'Indent' then
                ---@cast el AST.Indent
                el.value = el.value:sub(1, #el.value - commonIndent)
            end

            if #el.value > 0 then
                local prev = trimmed[#trimmed]
                if prev and prev.type == 'TextElement' then
                    ---@cast prev AST.TextElement
                    local newEl = self:createNode(NodeType.TextElement, {
                        value = prev.value .. el.value,
                        range = { prev.range[1], el.range[2] },
                    })

                    trimmed[#trimmed] = newEl
                else
                    if el.type == 'Indent' then
                        el = self:createNode(NodeType.TextElement, {
                            value = el.value,
                            range = el.range,
                        })
                    end

                    trimmed[#trimmed + 1] = el
                end
            end
        end
    end

    -- remove trailing whitespace
    local lastEl = trimmed[#trimmed]
    if lastEl and lastEl.type == 'TextElement' then
        ---@cast lastEl AST.TextElement
        lastEl.value = lastEl.value:gsub('[ \r\n]+$', '')
        if #lastEl.value == 0 then
            trimmed[#trimmed] = nil
        end
    end

    return trimmed
end

---Returns a parse error if the current character is not the given character.
---Updates the pointer to move past the character.
---@return FluentParseError? error
---@protected
function Parser:expectChar(c)
    if self:peek() == c then
        self._ptr = (self._ptr + 1) --[[@as integer]]
        return
    end

    return ParseError:new('E0003', c)
end

---Returns a parse error if the current character is not a valid line ending.
---Updates the pointer to move past the line ending.
---@return FluentParseError? error
---@protected
function Parser:expectLineEnd()
    local pos = self._ptr
    local c = self:index(pos)

    if c == EOF then
        return
    end

    -- treat CRLF as LF
    if c == '\r' and self:index(pos + 1) == EOL then
        self._ptr = pos + 2
        return
    end

    if c == EOL then
        self._ptr = pos + 1
        return
    end

    return ParseError:new('E0003', '\\n')
end

---Reads a single attribute.
---@return AST.Attribute? attr
---@return FluentParseError? error
---@protected
function Parser:getAttribute()
    local start = self._ptr
    local err = self:expectChar('.')
    if err then
        return nil, err
    end

    local key
    key, err = self:getIdentifier()
    if not key then
        return nil, err
    end

    self:skipBlankInline()
    err = self:expectChar('=')
    if err then
        return nil, err
    end

    local value
    value, err = self:tryGetPattern()
    if err then
        return nil, err
    elseif not value then
        return nil, ParseError:new('E0012')
    end

    return self:createNode(NodeType.Attribute, {
        id = key,
        value = value,
        range = { start },
    })
end

---Reads attributes for a message or term.
---@return AST.Attribute[]? attrs
---@return FluentParseError? error
---@protected
function Parser:getAttributes()
    local attrs = {} ---@type AST.Attribute[]

    local resetPos = self._ptr
    self:skipBlank()

    if self:peek() ~= '.' then
        self._ptr = resetPos
        return attrs
    end

    repeat
        local attr, err = self:getAttribute()
        if err then
            return nil, err
        end

        attrs[#attrs + 1] = attr

        resetPos = self._ptr
        self:skipBlank()
    until self:peek() ~= '.'

    self._ptr = resetPos
    return attrs
end

---Reads a single call argument node.
---@return (AST.InlineExpression | AST.NamedArgument)? expr
---@return FluentParseError? error
---@protected
function Parser:getCallArgument()
    local start = self._ptr
    local expr, err = self:getInlineExpression()
    if not expr then
        return nil, err
    end

    self:skipBlank()

    if self:peek() ~= ':' then
        return expr
    end

    if expr.type == 'MessageReference' and not expr.attribute then
        self._ptr = self._ptr + 1
        self:skipBlank()

        local value
        value, err = self:getLiteral()
        if not value then
            return nil, err
        end

        return self:createNode(NodeType.NamedArgument, {
            name = expr.id,
            value = value,
            range = { start },
        })
    end

    return nil, ParseError:new('E0009')
end

---Reads a call arguments node.
---@return AST.CallArguments? expr
---@return FluentParseError? error
---@protected
function Parser:getCallArguments()
    local positional = {}
    local named = {}
    local argumentNameSet = {}

    local start = self._ptr
    local err = self:expectChar('(')
    if err then
        return nil, err
    end

    self:skipBlank()

    while true do
        if self:peek() == ')' then
            break
        end

        local argument
        argument, err = self:getCallArgument()
        if not argument then
            return nil, err
        end

        if argument.type == 'NamedArgument' then
            if argumentNameSet[argument.name.name] then
                return nil, ParseError:new('E0022')
            end

            named[#named + 1] = argument
            argumentNameSet[argument.name.name] = true
        elseif #named > 0 then
            return nil, ParseError:new('E0021')
        else
            positional[#positional + 1] = argument
        end

        self:skipBlank()
        if self:peek() ~= ',' then
            break
        end

        self._ptr = self._ptr + 1
        self:skipBlank()
    end

    err = self:expectChar(')')
    if err then
        return nil, err
    end

    return self:createNode(NodeType.CallArguments, {
        positional = positional,
        named = named,
        range = { start },
    })
end

---Reads a comment.
---@return AST.Comments? comment
---@return FluentParseError? error
---@protected
function Parser:getComment()
    -- 0 = comment, 1 = group comment, 2 = resource comment
    local level = -1
    local content = {}

    local start = self._ptr
    while true do
        local i = -1
        while self:peek() == '#' and i < (level == -1 and 2 or level) do
            self._ptr = self._ptr + 1
            i = i + 1
        end

        if level == -1 then
            level = i
        end

        if not self:isEOL() then
            local err = self:expectChar(' ')
            if err then
                return nil, err
            end

            local nextEOL = self:find('\r?\n') or (self:len() + 1)
            content[#content + 1] = self._text:sub(self._ptr, nextEOL - 1)
            self._ptr = nextEOL
        end

        if self:isNextLineComment(level) then
            content[#content + 1] = self:skipEOL()
        else
            break
        end
    end

    local commentType ---@type FluentNodeType
    if level == 0 then
        commentType = NodeType.Comment
    elseif level == 1 then
        commentType = NodeType.GroupComment
    else
        commentType = NodeType.ResourceComment
    end

    return self:createNode(commentType, {
        content = concat(content),
        range = { start },
    })
end

---Reads a series of digit characters.
---Returns an error if not dig
---@return string? digits
---@return FluentParseError? error
---@protected
function Parser:getDigits()
    local chars = {}
    while self:hasNext() do
        local c = self:peek()
        local code = c:byte()
        if not code or not (code >= 48 and code <= 57) then -- 0-9
            break
        end

        chars[#chars + 1] = c
        self._ptr = self._ptr + 1
    end

    if #chars == 0 then
        return nil, ParseError:new('E0004', '0-9')
    end

    return concat(chars)
end

---Gets the next entry node.
---@return AST.Entry? entry
---@return FluentParseError? error
---@protected
function Parser:getEntry()
    local c = self:peek()
    if c == '#' then
        return self:getComment()
    elseif c == '-' then
        return self:getTerm()
    elseif self:isCharIdStart(c) then
        return self:getMessage()
    end

    return nil, ParseError:new('E0002')
end

---Gets the next entry node, or a junk node if an error occurred.
---@return AST.Entry entry
---@protected
function Parser:getEntryOrJunk()
    local entryStartPos = self._ptr
    local entry, err = self:getEntry()
    if entry then
        err = self:expectLineEnd()
    end

    if not entry or err then
        err = err or ParseError:new('E0001')

        if self._raiseErrors then
            error(err.message)
        end

        local errPos = self._ptr
        self:skipToNextEntryStart(entryStartPos)

        local nextPos = self._ptr
        if nextPos < errPos then
            errPos = nextPos
        end

        ---@type AST.Junk
        local junk = self:createNode(NodeType.Junk, {
            content = self._text:sub(entryStartPos, nextPos - 1),
            annotations = {},
            range = { entryStartPos, nextPos - 1 },
        })

        errPos = core.clamp(errPos, 1, self:len())

        ---@type AST.Annotation
        local annot = {
            type = 'Annotation',
            code = err.code,
            arguments = err.args,
            message = err.message,
            range = { errPos, errPos },
        }

        junk.annotations[1] = annot
        return junk
    end

    return entry
end

---Reads a string escape sequence.
---@return string? escape
---@return FluentParseError? error
---@protected
function Parser:getEscapeSequence()
    local c = self:peek()
    if c == '\\' or c == '"' then
        self._ptr = self._ptr + 1
        return '\\' .. c
    end

    if c == 'u' then
        return self:getUnicodeEscapeSequence(c, 4)
    elseif c == 'U' then
        return self:getUnicodeEscapeSequence(c, 6)
    end

    return nil, ParseError:new('E0025', c)
end

---Reads an expression node.
---@return (AST.Expression | AST.Placeable)? expr
---@return FluentParseError? error
---@protected
function Parser:getExpression()
    local start = self._ptr
    local expr, err = self:getInlineExpression()
    if not expr then
        return nil, err
    end

    self:skipBlank()

    if self:peek() ~= '-' then
        if expr.type == 'TermReference' and expr.attribute then
            return nil, ParseError:new('E0019')
        end

        return expr
    end

    self._ptr = self._ptr + 1
    if self:peek() ~= '>' then
        self._ptr = self._ptr - 1
        return expr
    end

    -- expr is selector; validate it
    if expr.type == 'MessageReference' then
        return nil, ParseError:new(expr.attribute and 'E0018' or 'E0016')
    elseif expr.type == 'Placeable' then
        return nil, ParseError:new('E0029')
    elseif expr.type == 'TermReference' and not expr.attribute then
        return nil, ParseError:new('E0017')
    end

    self._ptr = self._ptr + 1
    self:skipBlankInline()

    err = self:expectLineEnd()
    if err then
        return nil, err
    end

    local variants
    variants, err = self:getVariants()
    if not variants then
        return nil, err
    end

    return self:createNode(NodeType.SelectExpression, {
        selector = expr,
        variants = variants,
        range = { start },
    })
end

---Gets an identifier node.
---@return AST.Identifier? ident
---@return FluentParseError? error
---@protected
function Parser:getIdentifier()
    local start = self._ptr

    local first, err = self:readIDStart()
    if not first then
        return nil, err
    end

    return self:createNode(NodeType.Identifier, {
        name = self:readIDChars(first),
        range = { start },
    })
end

---Reads an inline expression node.
---@return AST.InlineExpression? expr
---@return FluentParseError? error
---@protected
function Parser:getInlineExpression()
    local start = self._ptr
    local c = self:index(start)
    if c == '{' then
        return self:getPlaceable()
    end

    if c == '"' then
        return self:getString()
    end

    if self:isNumberStart() then
        return self:getNumber()
    end

    -- variable reference
    if c == '$' then
        self._ptr = self._ptr + 1
        local id, err = self:getIdentifier()
        if not id then
            return nil, err
        end

        return self:createNode(NodeType.VariableReference, {
            id = id,
            range = { start },
        })
    end

    -- term reference
    if c == '-' then
        self._ptr = self._ptr + 1

        local id, err = self:getIdentifier()
        if not id then
            return nil, err
        end

        local attr
        if self:peek() == '.' then
            self._ptr = self._ptr + 1
            attr, err = self:getIdentifier()
            if not attr then
                return nil, err
            end
        end

        local resetPos = self._ptr
        self:peekBlank()

        local args
        if self:peek() == '(' then
            args, err = self:getCallArguments()
            if not args then
                return nil, err
            end
        else
            self._ptr = resetPos
        end

        return self:createNode(NodeType.TermReference, {
            id = id,
            attribute = attr,
            arguments = args,
            range = { start },
        })
    end

    if self:isCharIdStart(c) then
        local id, err = self:getIdentifier()
        if not id then
            return nil, err
        end

        local resetPos = self._ptr
        self:peekBlank()

        c = self:peek()
        if c == '(' then
            -- ensure function is uppercase
            if not id.name:match('^[A-Z][A-Z0-9_-]*$') then
                return nil, ParseError:new('E0008')
            end

            local args
            args, err = self:getCallArguments()
            if not args then
                return nil, err
            end

            return self:createNode(NodeType.FunctionReference, {
                id = id,
                arguments = args,
                range = { start },
            })
        else
            self._ptr = resetPos
        end

        local attr
        if c == '.' then
            self._ptr = self._ptr + 1
            attr, err = self:getIdentifier()
            if not attr then
                return nil, err
            end
        end

        return self:createNode(NodeType.MessageReference, {
            id = id,
            attribute = attr,
        })
    end

    return nil, ParseError:new('E0028')
end

---Reads a number or string literal node.
---@return AST.Literal? expr
---@return FluentParseError? error
---@protected
function Parser:getLiteral()
    if self:peek() == '"' then
        return self:getString()
    end

    if self:isNumberStart() then
        return self:getNumber()
    end

    return nil, ParseError:new('E0014')
end

---Gets a message node.
---@return AST.Message? message
---@return FluentParseError? error
---@protected
function Parser:getMessage()
    local start = self._ptr
    local id, err = self:getIdentifier()
    if not id then
        return nil, err
    end

    self:skipBlankInline()
    err = self:expectChar('=')
    if err then
        return nil, err
    end

    local value
    value, err = self:tryGetPattern()
    if err then
        return nil, err
    end

    local attrs
    attrs, err = self:getAttributes()
    if not attrs then
        return nil, err
    end

    if not value and #attrs == 0 then
        return nil, ParseError:new('E0005', id.name)
    end

    return self:createNode(NodeType.Message, {
        id = id,
        value = value,
        attributes = attrs,
        range = { start },
    })
end

---Reads a number literal node.
---@return AST.NumberLiteral? expr
---@return FluentParseError? error
---@protected
function Parser:getNumber()
    local start = self._ptr

    local chars = {}
    if self:peek() == '-' then
        self._ptr = self._ptr + 1
        chars[#chars + 1] = '-'
    end

    local digits, err = self:getDigits()
    if not digits then
        return nil, err
    end

    chars[#chars + 1] = digits

    if self:peek() == '.' then
        self._ptr = self._ptr + 1
        chars[#chars + 1] = '.'

        digits, err = self:getDigits()
        if not digits then
            return nil, err
        end

        chars[#chars + 1] = digits
    end

    return self:createNode(NodeType.NumberLiteral, {
        value = concat(chars),
        range = { start },
    })
end

---Gets a pattern node.
---@return AST.Pattern? pattern
---@return FluentParseError? error
---@protected
function Parser:getPattern(isBlock)
    ---@type (AST.PatternElement | AST.Indent)[]
    local elements = {}

    local start = self._ptr
    local commonIndentLength
    if isBlock then
        -- block pattern starts on new line; store indent for dedent logic
        local blankStart = self._ptr
        local indent = self:skipBlankInline()
        elements[#elements + 1] = {
            type = 'Indent',
            value = indent,
            range = { blankStart, self._ptr },
        }

        commonIndentLength = #indent
    else
        commonIndentLength = INF
    end

    while self:hasNext() do
        if self:isEOL() then
            local blankStart = self._ptr
            local blankLines = self:skipBlankBlock()
            if not self:isValueContinuation() then
                self._ptr = blankStart
                break
            end

            local indent = self:skipBlankInline()
            commonIndentLength = #indent < commonIndentLength and #indent or commonIndentLength
            elements[#elements + 1] = {
                type = 'Indent',
                value = blankLines .. indent,
                range = { blankStart, self._ptr },
            }
        else
            local c = self:peek()
            if c == '}' then
                return nil, ParseError:new('E0027')
            elseif c == '{' then
                local placeable, err = self:getPlaceable()
                if not placeable then
                    return nil, err
                end

                elements[#elements + 1] = placeable
            else
                elements[#elements + 1] = self:getTextElement()
            end
        end
    end

    return self:createNode(NodeType.Pattern, {
        elements = self:dedent(elements, commonIndentLength),
        range = { start },
    })
end

---Reads a placeable.
---@return AST.Placeable? placeable
---@return FluentParseError? error
---@protected
function Parser:getPlaceable()
    local start = self._ptr
    local err = self:expectChar('{')
    if err then
        return nil, err
    end

    self:skipBlank()

    local expr
    expr, err = self:getExpression()
    if not expr then
        return nil, err
    end

    err = self:expectChar('}')
    if err then
        return nil, err
    end

    return self:createNode(NodeType.Placeable, {
        expression = expr,
        range = { start },
    })
end

---Reads a string literal node.
---@return AST.StringLiteral? expr
---@return FluentParseError? error
---@protected
function Parser:getString()
    local start = self._ptr
    local err = self:expectChar('"')
    if err then
        return nil, err
    end

    local chars = {}
    while self:hasNext() do
        local c = self:peek()
        if c == '"' then
            break
        end

        local value
        if c == '\\' then
            self._ptr = self._ptr + 1
            value, err = self:getEscapeSequence()
            if not value then
                return nil, err
            end
        else
            value = c
            self._ptr = self._ptr + 1
        end

        chars[#chars + 1] = value
    end

    if self:isEOL() then
        return nil, ParseError:new('E0020')
    end

    err = self:expectChar('"')
    if err then
        return nil, err
    end

    return self:createNode(NodeType.StringLiteral, {
        value = concat(chars),
        range = { start },
    })
end

---Gets a term node.
---@return AST.Term? term
---@return FluentParseError? error
---@protected
function Parser:getTerm()
    local start = self._ptr
    local err = self:expectChar('-')
    if err then
        return nil, err
    end

    local id
    id, err = self:getIdentifier()
    if not id then
        return nil, err
    end

    self:skipBlankInline()
    err = self:expectChar('=')
    if err then
        return nil, err
    end

    local value
    value, err = self:tryGetPattern()
    if err then
        return nil, err
    elseif not value then
        return nil, ParseError:new('E0006', id.name)
    end

    local attrs
    attrs, err = self:getAttributes()
    if not attrs then
        return nil, err
    end

    return self:createNode(NodeType.Term, {
        id = id,
        value = value,
        attributes = attrs,
        range = { start },
    })
end

---Gets a text element node.
---@return AST.TextElement
---@protected
function Parser:getTextElement()
    local start = self._ptr
    local nextBrace = self:find('[{}]')
    local nextEOL = self:find('\r?\n')

    local nextPos = nextBrace or nextEOL
    if nextBrace and nextEOL then
        nextPos = nextBrace < nextEOL and nextBrace or nextEOL
    end

    local value
    if nextPos then
        value = self._text:sub(start, nextPos - 1)
        self._ptr = nextPos
    else
        value = self._text:sub(start)
        self._ptr = self:len() + 1
    end

    return self:createNode(NodeType.TextElement, {
        value = value,
        range = { start },
    })
end

---Reads a Unicode escape sequence.
---@param u string The unicode escape start character.
---@param digits integer The number of digits expected.
---@return string? escape
---@return FluentParseError? error
---@protected
function Parser:getUnicodeEscapeSequence(u, digits)
    local err = self:expectChar(u)
    if err then
        return nil, err
    end

    local chars = { '\\', u }
    for _ = 1, digits do
        local c = self:read()
        if c == '' then
            return nil, ParseError:new('E9999')
        end

        chars[#chars + 1] = c
        local code = c:byte()
        local isHex = (code >= 48 and code <= 57) -- 0-9
            or (code >= 65 and code <= 70)        -- A-F
            or (code >= 97 and code <= 102)       -- a-f

        if not isHex then
            return nil, ParseError:new('E0026', concat(chars))
        end
    end

    return concat(chars)
end

---Gets a selector variant node.
---@param hasDefault boolean Flag for whether there's already a default variant.
---@return AST.Variant? variant
---@return FluentParseError? error
---@protected
function Parser:getVariant(hasDefault)
    local isDefault = false

    local start = self._ptr
    if self:peek() == '*' then
        if hasDefault then
            return nil, ParseError:new('E0015')
        end

        self._ptr = self._ptr + 1
        isDefault = true
    end

    local err = self:expectChar('[')
    if err then
        return nil, err
    end

    self:skipBlank()

    local key
    key, err = self:getVariantKey()
    if not key then
        return nil, err
    end

    self:skipBlank()
    err = self:expectChar(']')
    if err then
        return nil, err
    end

    local value
    value, err = self:tryGetPattern()
    if err then
        return nil, err
    elseif not value then
        return nil, ParseError:new('E0012')
    end

    return self:createNode(NodeType.Variant, {
        key = key,
        value = value,
        default = isDefault,
        range = { start },
    })
end

---Gets a selector variant key node.
---@return (AST.Identifier | AST.NumberLiteral)? variantKey
---@return FluentParseError? error
---@protected
function Parser:getVariantKey()
    local c = self:peek()
    if c == EOF then
        return nil, ParseError:new('E0013')
    end

    local code = c:byte()
    if code == 45 or (code >= 48 and code <= 57) then -- 0-9, -
        return self:getNumber()
    end

    return self:getIdentifier()
end

---Reads selector variants.
---@return AST.Variant[]? variants
---@return FluentParseError? error
---@protected
function Parser:getVariants()
    local variants = {}
    local hasDefault = false

    self:skipBlank()
    while self:isVariantStart() do
        local variant, err = self:getVariant(hasDefault)
        if not variant then
            return nil, err
        end

        if variant.default then
            hasDefault = true
        end

        variants[#variants + 1] = variant
        err = self:expectLineEnd()
        if err then
            return nil, err
        end

        self:skipBlank()
    end

    if #variants == 0 then
        return nil, ParseError:new('E0011')
    end

    if not hasDefault then
        return nil, ParseError:new('E0010')
    end

    return variants
end

---Checks whether a character is a valid identifier start character.
---@param c string The character to check.
---@return boolean
---@protected
function Parser:isCharIdStart(c)
    local code = c:byte()

    -- a-z, A-Z
    return (code >= 97 and code <= 122) or (code >= 65 and code <= 90)
end

---Checks whether the current character is an end-of-line character.
---@return boolean
---@protected
function Parser:isEOL()
    local pos = self._ptr
    local c = self:index(pos)

    if c == '\r' then
        return self:index(pos + 1) == EOL
    end

    return c == EOL
end

---Checks whether the next line is a comment with the given level.
---@param level integer The expected level.
---@return boolean
---@protected
function Parser:isNextLineComment(level)
    if not self:isEOL() then
        return false
    end

    local i = 0
    local startPos = self._ptr
    while i <= level do
        self._ptr = self._ptr + 1
        if self:peek() ~= '#' then
            if i <= level then
                self._ptr = startPos
                return false
            end

            break
        end

        i = i + 1
    end

    self._ptr = self._ptr + 1
    if self:peek() == ' ' or self:isEOL() then
        self._ptr = startPos
        return true
    end

    self._ptr = startPos
    return false
end

---Checks whether the current character is a valid number start character.
---@return boolean
---@protected
function Parser:isNumberStart()
    local ptr = self._ptr
    local c = self:index(ptr)
    if c == '-' then
        c = self:index(ptr + 1)
    end

    if c == EOF then
        return false
    end

    local code = c:byte()
    return code >= 48 and code <= 57 -- 0-9
end

---Checks whether the current position is a continuation of a value.
---@return boolean isContinuation
---@protected
function Parser:isValueContinuation()
    local pos = self._ptr
    local _, peekedPos = self:peekBlankInline()
    local c = self:index(peekedPos)
    if c == '{' then
        return true
    end

    if peekedPos == pos then
        return false
    end

    if c ~= EOF and not SPECIAL_LINE_START_CHARS[c] then
        return true
    end

    return false
end

---Checks whether the current character is a valid variant start character.
---@return boolean
---@protected
function Parser:isVariantStart()
    local ptr = self._ptr
    local c = self:index(ptr)
    if c == '*' then
        c = self:index(ptr + 1)
    end

    return c == '['
end

---Returns the next position of a character other than space or EOL.
---@return integer
---@protected
function Parser:peekBlank()
    local i = self._ptr
    while i <= self:len() do
        local c = self:index(i)
        if c == '\r' then
            if self:index(i + 1) ~= EOL then
                i = i + 1
                break
            end
        elseif c ~= ' ' and c ~= EOL then
            break
        end

        i = i + 1
    end

    return i
end

---Returns a substring of blank spaces starting at the current position.
---@return string peeked
---@return integer nextPos
---@protected
function Parser:peekBlankBlock()
    local chars = {}
    local start = self._ptr
    while true do
        local lineStart = self._ptr
        self:skipBlankInline()

        if self:isEOL() then
            chars[#chars + 1] = self:skipEOL()
        elseif self:peek() == '' then
            break
        else
            self._ptr = lineStart
            break
        end
    end

    local pos = self._ptr
    self._ptr = start
    return concat(chars), pos
end

---Returns a substring of blank spaces starting at the current position.
---@return string peeked
---@return integer nextPos
---@protected
function Parser:peekBlankInline()
    local start = self._ptr
    local nextNonSpace = self:find('[^ ]')
    if not nextNonSpace then
        return '', start
    end

    local peeked = self._text:sub(start, nextNonSpace - 1)
    return peeked, nextNonSpace
end

---Reads identifier characters.
---@param start string The start character.
---@return string chars
---@protected
function Parser:readIDChars(start)
    local chars = { start }

    while self:hasNext() do
        local c = self:peek()
        local code = c:byte()

        -- a-z, A-Z
        local canTake = code == 95 or code == 45 -- _-
            or (code >= 97 and code <= 122)      -- a-z
            or (code >= 65 and code <= 90)       -- A-Z
            or (code >= 48 and code <= 57)       -- 0-9

        if not canTake then
            break
        end

        chars[#chars + 1] = c
        self._ptr = self._ptr + 1
    end

    return concat(chars)
end

---Reads an identifier start character.
---@return string? start
---@return FluentParseError? error
---@protected
function Parser:readIDStart()
    local c = self:peek()
    if self:isCharIdStart(c) then
        self._ptr = self._ptr + 1
        return c
    end

    return nil, ParseError:new('E0004', 'a-zA-Z')
end

---Skips to the next character that is not space or EOL.
---@protected
function Parser:skipBlank()
    self._ptr = self:peekBlank()
end

---Skips blank blocks.
---@return string spaces
---@protected
function Parser:skipBlankBlock()
    local blank, pos = self:peekBlankBlock()
    self._ptr = pos
    return blank
end

---Skips space characters.
---@return string spaces
---@protected
function Parser:skipBlankInline()
    local blank, pos = self:peekBlankInline()
    self._ptr = pos
    return blank
end

---Skips past an EOL character at the current position.
---Returns an EOL character if found. Otherwise, returns the empty string.
---@return string
---@protected
function Parser:skipEOL()
    local pos = self._ptr
    local c = self:index(pos)

    if c == '\r' and self:index(pos + 1) == EOL then
        self._ptr = pos + 2
        return EOL
    end

    if c == EOL then
        self._ptr = pos + 1
        return EOL
    end

    return ''
end

---Skips to the next character that looks like the beginning of an entry.
---@param junkStart integer
---@protected
function Parser:skipToNextEntryStart(junkStart)
    local substr = self._text:sub(1, self._ptr)
    local _, lastNewline = substr:find('.+\n')
    lastNewline = lastNewline or -1

    if junkStart < lastNewline then
        -- last newline is after junk start → rewind
        self._ptr = lastNewline
    end

    while self:hasNext() do
        -- skip to next start of a line
        if self:peek() ~= EOL then
            self._ptr = self._ptr + 1
        else
            self._ptr = self._ptr + 1
            local c = self:peek()
            if c == '-' or c == '#' or self:isCharIdStart(c) then
                break
            end
        end
    end
end

---Attempts to read a pattern.
---@return AST.Pattern? pattern
---@return FluentParseError? error
---@protected
function Parser:tryGetPattern()
    local start = self._ptr
    local _, peekedPos = self:peekBlankInline()
    self._ptr = peekedPos
    if self:hasNext() and not self:isEOL() then
        return self:getPattern(false)
    end

    _, peekedPos = self:peekBlankBlock()
    self._ptr = peekedPos

    if self:isValueContinuation() then
        return self:getPattern(true)
    end

    self._ptr = start
    return
end


---Creates a new Fluent parser.
---@param options Args.Parser?
---@return FluentParser
function Parser:new(options)
    local this = core.new(self, BaseParser.new, options)

    this._entries = {}

    return this
end


return Parser
