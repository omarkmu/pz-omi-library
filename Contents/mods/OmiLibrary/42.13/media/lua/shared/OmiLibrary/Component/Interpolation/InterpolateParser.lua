---Parser for the interpolated string format.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local BaseParser = require 'OmiLibrary/Component/Core/Parser'

local concat = table.concat


---@class InterpolateParser : Parser<BasicParseNode>
---@field protected _allowTokens boolean Whether tokens should be interpreted.
---@field protected _allowAtExpr boolean Whether at-maps should be interpreted.
---@field protected _allowFunctions boolean Whether functions should be interpreted.
---@field protected _allowCharEntities boolean Whether character entities should be interpreted.
local InterpolationParser = BaseParser:derive('InterpolationParser')


---Node types created by the parser.
---@enum interpolate.NodeType
InterpolationParser.NodeType = {
    at_expression = 'at_expression',
    at_key = 'at_key',
    at_value = 'at_value',
    text = 'text',
    token = 'token',
    string = 'string',
    call = 'call',
    escape = 'escape',
    argument = 'argument',
}


local NodeType = InterpolationParser.NodeType
local ERR = {
    BAD_CHAR = 'unexpected character: `%s`',
    WARN_UNTERM_FUNC = 'potentially unterminated function `%s`',
    UNTERM_FUNC = 'unterminated function `%s`',
    UNTERM_AT = 'unterminated at-expression',
}

-- text patterns for node types
local TEXT_PATTERNS = {
    -- $ = token/escape/call start, space = delimiter, ` = string start, ) = call end, & = entity start
    [NodeType.argument] = ' $%)&`',
    -- $ = token/escape/call start, @ = at-expression start, ; = delim, : = delim, ` = string start, ) = at-expression end, & = entity start
    [NodeType.at_key] = ':;$@%)&`',
    [NodeType.at_value] = ':;$@%)&`',
    -- $ = escape start, ` = string end
    [NodeType.string] = '$`',
}

local SPECIAL = {
    ['$'] = true,
    ['@'] = true,
    [':'] = true,
    [';'] = true,
    ['('] = true,
    [')'] = true,
    ['&'] = true,
    ['`'] = true,
}



---Performs parsing of an interpolation pattern.
---@param text string The pattern to parse.
---@return interpolate.ParseResult
function InterpolationParser:parse(text)
    return BaseParser.parse(self, text)
end


---Gets the value of a named or numeric entity.
---@param entity string
---@return string
---@protected
function InterpolationParser:getEntityValue(entity)
    return core.getEntityValue(entity) or entity
end

---Gets the pattern for text nodes given the current node type.
---@return string
---@protected
function InterpolationParser:getTextPattern()
    local type = self._node and self._node.type

    -- $ = token/escape/call start, @ = at-expression start, & = entity start
    local patt = TEXT_PATTERNS[type] or '$@&'
    return string.format('^([^%s])[%s]?', patt, patt)
end

---Returns a table with consecutive text nodes merged.
---@param tab BasicParseNode[]
---@return interpolate.Node[]
---@protected
function InterpolationParser:mergeTextNodes(tab)
    ---@type interpolate.Node[]
    local result = {}

    local last
    for i = 1, #tab do
        local node = tab[i]
        if node.type == NodeType.text then
            if last and last.parts and last.type == NodeType.text then
                last.parts[#last.parts + 1] = node.value
            else
                last = {
                    type = NodeType.text,
                    parts = { node.value },
                }

                result[#result + 1] = last --[[@as any]]
            end
        else
            result[#result + 1] = node --[[@as any]]
            last = node
        end
    end

    for i = 1, #result do
        local node = result[i]
        if node.parts and node.type == NodeType.text then
            node.value = concat(node.parts)
            node.parts = nil
        end
    end

    return result
end

---Reads an at-expression (e.g., `@(1)`, `@(A:B)`, `@(1;A:B)`).
---@return BasicParseNode?
---@protected
function InterpolationParser:readAtExpression()
    if not self._allowAtExpr then
        return
    end

    ---@type integer
    local start = self:match('^@%(()')
    if not start then
        return
    end

    local node = self:createNode(NodeType.at_expression)
    local parent = self:setCurrentNode(node)
    self._ptr = start

    local stop, keyNode, valueNode

    self:readSpaces()

    while self:hasNext() do
        while self:peek() == ';' do
            keyNode, valueNode = nil, nil
            self._ptr = self._ptr + 1
        end

        if self._ptr > self:len() then
            break
        end

        if not keyNode then
            self:readSpaces()
        end

        local c = self:peek()
        if c == ')' then
            break
        elseif c == ':' then
            local keyPos = self._ptr

            -- consume :
            repeat
                self._ptr = self._ptr + 1
            until self:peek() ~= ':'

            if self._ptr > self:len() then
                break
            end

            self:setCurrentNode(node)

            -- existing value node | no key node → add empty key node
            if valueNode or not keyNode then
                keyNode = self:addNode(self:createNode(NodeType.at_key))
                self:setNodeRange(keyNode, keyPos, keyPos)
            end

            self:readSpaces()

            valueNode = self:addNode(self:createNode(NodeType.at_value))
            self:setCurrentNode(valueNode)
        elseif not keyNode then
            self:setCurrentNode(node)
            keyNode = self:addNode(self:createNode(NodeType.at_key))
            self:setCurrentNode(keyNode)
        end

        c = self:peek()
        if c == ';' or c == ':' then
            -- ignore; avoid reading invalid value
        elseif c == ')' then
            if valueNode then
                local pos = self._ptr
                self:setNodeRange(valueNode, pos, pos)
            end

            break
        elseif not (self:readString() or self:readExpression()) then
            self:errorHere(ERR.BAD_CHAR:format(self:peek()), valueNode or keyNode or node, nil, 'BAD_CHAR')

            stop = self._ptr - 1
            self:setNodeEnd(self._node, stop)

            break
        elseif keyNode or valueNode then
            self:setNodeEnd(self._node, self._ptr - 1)
        end
    end

    self:setNodeEnd(node, stop)
    self:setCurrentNode(parent)

    if self:peek() ~= ')' then
        -- unterminated expression; read @ and rewind
        self:warning(ERR.UNTERM_AT, node)
        self._ptr = node.range[1]
        node = self:createNode(NodeType.text, { value = '@' })
    end

    self._ptr = self._ptr + 1
    return self:addNode(node)
end

---Reads a character entity (e.g., `&#171;`)
---@return BasicParseNode?
---@protected
function InterpolationParser:readCharacterEntity()
    if not self._allowCharEntities then
        return
    end

    ---@type string?, integer
    local entity, pos = self:match('^(&#x?%d+;)()')

    if not entity then
        ---@type string, integer
        entity, pos = self:match('^(&%a+;)()')
        if not entity then
            return
        end
    end

    local value = self:getEntityValue(entity)
    local node = self:createNode(NodeType.text, { value = value })
    self:setNodeEnd(node, pos - 1)
    self._ptr = pos

    return self:addNode(node)
end

---Reads a prefix followed by an escaped character.
---@return BasicParseNode?
---@protected
function InterpolationParser:readEscape()
    local value = self:match('^$([$@();:&`])')
    if not value then
        return
    end

    local node = self:createNode(NodeType.escape, { value = value })

    self:setNodeEnd(node, self._ptr + 1)
    self._ptr = self._ptr + 2

    return self:addNode(node)
end

---Reads a single acceptable expression.
---@return BasicParseNode?
---@protected
function InterpolationParser:readExpression()
    return self:readEscape()
        or self:readFunction()
        or self:readVariable()
        or self:readAtExpression()
        or self:readCharacterEntity()
        or self:readText()
        or self:readSpecialText()
end

---Reads a function and its arguments (e.g., `$upper(hello)`).
---@return BasicParseNode?
---@protected
function InterpolationParser:readFunction()
    if not self._allowFunctions then
        return
    end

    local name, start = self:match('^$([%w_]+)%(()')
    if not name then
        return
    end

    local node = self:createNode(NodeType.call, { value = name })
    local parent = self:setCurrentNode(node)
    self._ptr = start

    local argNode = self:createNode(NodeType.argument)
    self:setCurrentNode(argNode)

    local stop
    while self:hasNext() do
        local delimited = self:readSpaces()
        local done = self:peek() == ')'
        if delimited or done then
            self:setCurrentNode(node)

            if argNode.children and #argNode.children > 0 then
                self:addNode(argNode)
            end

            if done or self._ptr > self:len() then
                break
            end

            argNode = self:createNode(NodeType.argument)
            self:setCurrentNode(argNode)
        end

        if not (self:readString() or self:readExpression()) then
            self:errorHere(ERR.BAD_CHAR:format(self:peek()), argNode, nil, 'BAD_CHAR')
            stop = self._ptr - 1

            break
        end
    end

    self:setCurrentNode(parent)

    if self:peek() ~= ')' then
        -- unterminated function; read as var and rewind
        self._ptr = node.range[1]

        local variableNode = self:readVariable()
        if variableNode then
            self:warning(ERR.WARN_UNTERM_FUNC:format(name), node, nil, nil, 'UNTERM_FUNC')
            return variableNode
        end

        self:error(ERR.UNTERM_FUNC:format(name), node, nil, nil, 'UNTERM_FUNC')
    end

    self:setNodeEnd(node, stop)
    self._ptr = self._ptr + 1
    return self:addNode(node)
end

---Reads space characters and returns a literal string of spaces.
---@return string?
---@protected
function InterpolationParser:readSpaces()
    local spaces = self:match('^( +)')
    if not spaces then
        return
    end

    self._ptr = self._ptr + #spaces
    return spaces
end

---Reads a special character as-is.
---@return BasicParseNode?
---@protected
function InterpolationParser:readSpecialText()
    local value = self:peek()
    if not SPECIAL[value] then
        return
    end

    local node = self:createNode(NodeType.text, { value = value })
    self._ptr = self._ptr + 1

    return self:addNode(node)
end

---Reads a string of literal text delimited by backticks.
---Special characters can be escaped with $.
---@return BasicParseNode?
---@protected
function InterpolationParser:readString()
    if self:peek() ~= '`' then
        return
    end

    local stop
    local node = self:createNode(NodeType.string)
    local parent = self:setCurrentNode(node)
    self._ptr = self._ptr + 1

    while self:hasNext() do
        if self:peek() == '`' then
            break
        end

        if not (self:readEscape() or self:readText() or self:readSpecialText()) then
            self:errorHere(ERR.BAD_CHAR:format(self:peek()), node, nil, 'BAD_CHAR')
            stop = self._ptr - 1

            break
        end
    end

    self:setNodeEnd(node, stop)
    self:setCurrentNode(parent)

    if self:peek() ~= '`' then
        -- unterminated string; read as backtick and rewind
        self._ptr = node.range[1]
        node = self:createNode(NodeType.text, { value = '`' })
    end

    self._ptr = self._ptr + 1
    return self:addNode(node)
end

---Reads as much text as possible, up to the next special character.
---@return BasicParseNode?
---@protected
function InterpolationParser:readText()
    local value = self:match(self:getTextPattern())
    if not value then
        return
    end

    local node = self:createNode(NodeType.text, { value = value })

    self:setNodeEnd(node, self._ptr + #value - 1)
    self._ptr = self._ptr + #value

    return self:addNode(node)
end

---Reads a variable token (e.g., `$var`).
---@return BasicParseNode?
---@protected
function InterpolationParser:readVariable()
    if not self._allowTokens then
        return
    end

    ---@type string?, integer
    local name, pos = self:match('^$([%w_]+)()')
    if not name then
        return
    end

    local node = self:createNode(NodeType.token, { value = name })
    self:setNodeEnd(node, pos - 1)
    self._ptr = pos

    return self:addNode(node)
end

---Performs postprocessing on a result tree.
---@return interpolate.ParseResult
---@protected
function InterpolationParser:postprocess()
    local tree = self._tree
    local result = {}
    if #self._errors > 0 then
        return {
            success = false,
            warnings = #self._warnings > 0 and self._warnings or nil,
            errors = self._errors,
        }
    end

    if not tree.children then
        return { success = true, value = result }
    end

    for i = 1, #tree.children do
        local built = self:postprocessNode(tree.children[i])
        if built then
            result[#result + 1] = built
        end
    end

    return {
        success = true,
        warnings = #self._warnings > 0 and self._warnings or nil,
        value = self:mergeTextNodes(result),
    }
end

---Performs postprocessing on a tree node.
---@param node BasicParseNode
---@return (interpolate.Node | interpolate.Node[])?
---@protected
function InterpolationParser:postprocessNode(node)
    if node.type == NodeType.text or node.type == NodeType.escape then
        return {
            type = NodeType.text,
            value = node.value --[[@as string]],
        }
    elseif node.type == NodeType.token then
        return {
            type = node.type,
            value = node.value --[[@as string]],
        }
    elseif node.type == NodeType.string then
        -- convert string to basic text node
        local parts = {}
        if node.children then
            for i = 1, #node.children do
                local built = self:postprocessNode(node.children[i])
                if built and built.value then
                    parts[#parts + 1] = built.value
                end
            end
        end

        return {
            type = NodeType.text,
            value = concat(parts),
        }
    elseif node.type == NodeType.argument or node.type == NodeType.at_key or node.type == NodeType.at_value then
        -- convert node to list of child nodes
        local parts = {}
        if node.children then
            for i = 1, #node.children do
                local built = self:postprocessNode(node.children[i])
                if built then
                    parts[#parts + 1] = built
                end
            end
        end

        return self:mergeTextNodes(parts)
    elseif node.type == NodeType.call then
        local args = {} ---@type interpolate.Node[][]

        if node.children then
            for i = 1, #node.children do
                local child = node.children[i]
                local type = child.type
                if type == NodeType.argument then
                    args[#args + 1] = self:postprocessNode(child)
                end
            end
        end

        return {
            type = node.type,
            value = node.value --[[@as string]],
            args = args,
        }
    elseif node.type == NodeType.at_expression then
        local children = node.children or {}
        local entries = {}

        local i = 1
        while i <= #children do
            local key = children[i]
            local builtKey = key and key.type == NodeType.at_key and self:postprocessNode(key)

            if builtKey then
                local value = children[i + 1]
                local builtValue = value and value.type == NodeType.at_value and self:postprocessNode(value)

                if builtValue then
                    entries[#entries + 1] = {
                        key = builtKey,
                        value = builtValue,
                    }

                    i = i + 1
                else
                    builtValue = builtKey
                    entries[#entries + 1] = {
                        value = builtValue,
                    }
                end
            end

            i = i + 1
        end

        return {
            type = NodeType.at_expression,
            entries = entries,
        }
    end
end


---Creates a new interpolation parser.
---@param options Args.InterpolateParser?
---@return InterpolateParser
function InterpolationParser:new(options)
    local this = core.new(self, BaseParser.new, options)

    options = options or {}

    this._allowTokens = options.allowTokens ~= false
    this._allowAtExpr = options.allowAtExpressions ~= false
    this._allowFunctions = options.allowFunctions ~= false
    this._allowCharEntities = options.allowCharacterEntities ~= false

    return this
end


return InterpolationParser

--#region Type Definitions

---@class Args.InterpolateParser : Args.Parser
---@field allowTokens? boolean Whether tokens should be interpreted. If `false`, tokens will be treated as text. Defaults to `true`.
---@field allowAtExpressions? boolean Whether at-maps should be interpreted. If `false`, they will be treated as text. Defaults to `true`.
---@field allowFunctions? boolean Whether functions should be interpreted. If `false`, they will be treated as text. Defaults to `true`.
---@field allowCharacterEntities? boolean Whether character entities should be interpreted. If `false`, they will be treated as text. Defaults to `true`.


---@class interpolate.ParseResult
---@field success boolean Whether parsing was successful.
---@field value? interpolate.Node[] The result value of parsing the interpolation pattern.
---@field warnings? ParserError[] Warnings that were generated while parsing.
---@field errors? ParserError[] Errors that occurred while parsing.

---@class interpolate.ValueNode
---@field type interpolate.NodeType The type of the node.
---@field value string The node value.

---@class interpolate.CallNode : interpolate.ValueNode
---@field args interpolate.Node[][] The arguments to the function.

---@class interpolate.AtExpressionEntry
---@field key interpolate.ValueNode[] The key of the at-expression.
---@field value interpolate.ValueNode[] The value of the at-expression.

---@class interpolate.AtExpressionNode
---@field type 'at_expression' The type of the node.
---@field entries interpolate.AtExpressionEntry[] The entries in the at-expression.


---@alias interpolate.Node
---| interpolate.ValueNode
---| interpolate.CallNode
---| interpolate.AtExpressionNode

--#endregion
