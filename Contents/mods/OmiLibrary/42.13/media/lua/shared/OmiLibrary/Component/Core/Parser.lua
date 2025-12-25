---Base string parser.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'


---@class Parser<TNode : ParseNode> : Class
---@field protected _errors ParserError<TNode>[] Errors that occurred while parsing.
---@field protected _warnings ParserError<TNode>[] Warnings that were generated while parsing.
---@field protected _ptr integer The current position in the text being parsed.
---@field protected _text string The current text being parsed.
---@field protected _node? TNode The current tree node.
---@field protected _tree TNode The parse tree.
---@field protected _treeNodeType string The type name to use for the base tree node.
---@field protected _raiseErrors boolean Whether to throw parser errors instead of continuing silently.
local Parser = core.class('Parser')


---Performs parsing and returns the tree.
---@param text string The text to parse.
---@return any
function Parser:parse(text)
    self:reset(text)
    self:perform()
    return self:postprocess()
end

---Resets the parser state.
---@param text string? If provided, sets the text to parse.
---@protected
function Parser:reset(text)
    self._ptr = 1
    self._text = tostring(text or self._text or '')
    self._errors = {}
    self._warnings = {}
    self._node = nil
    self:createTree()
end


---Adds a node to the current tree node.
---If there is no current node, this sets the current node.
---@param node TNode The node to add.
---@return TNode node The newly added node.
---@protected
function Parser:addNode(node)
    local parent = self._node

    if not parent then
        self:setCurrentNode(node)
        return node
    end

    if not parent.children then
        parent.children = {}
    end

    parent.children[#parent.children + 1] = node

    return node
end

---Creates a new tree node.
---@param type string The node type.
---@param node table? The table to use for the node.
---@return TNode
---@protected
function Parser:createNode(type, node)
    node = node or {}
    node.type = type
    node.range = node.range or {} --[[@as [integer, integer] ]]
    self:setNodeRange(node, node.range[1], node.range[2])

    return node
end

---Creates the parse tree.
---@protected
function Parser:createTree()
    local tree = self:addNode(self:createNode(self._treeNodeType))

    self:setNodeEnd(tree, self:len())

    self._tree = tree
end

---Reports a parser error.
---@param err string
---@param node TNode?
---@param start integer?
---@param stop integer?
---@param id string?
---@protected
function Parser:error(err, node, start, stop, id)
    node = node or self._tree
    self._errors[#self._errors + 1] = {
        message = err,
        id = id,
        node = node ~= self._tree and node or nil,
        range = {
            start or node.range[1],
            stop or node.range[2],
        },
    }

    if self._raiseErrors then
        error(err)
    end
end

---Reports a parser error at the current position.
---@param err string
---@param node TNode?
---@param len integer?
---@param id string?
---@protected
function Parser:errorHere(err, node, len, id)
    len = len or 1
    local pos = self._ptr
    self:error(err, node or self._tree, pos, pos + len - 1, id)
end

---Finds a pattern in the parser's current text.
---@param pattern string The string pattern.
---@param pos integer? A position to start from. Defaults to the current position.
---@return integer? start
---@return integer? end
---@return (any | nil)... captured
---@protected
function Parser:find(pattern, pos)
    return self._text:find(pattern, pos or self._ptr)
end

---Moves the parser pointer forward.
---@param inc integer? The value to move forward by. Defaults to `1`.
---@return integer
---@protected
function Parser:forward(inc)
    self._ptr = self._ptr + (inc or 1)
    return self._ptr
end

---Checks whether the parser pointer is within the string.
---@return boolean
---@protected
function Parser:hasNext()
    return self._ptr <= #self._text
end

---Returns a substring of the current text.
---@param i integer The index at which the substring should begin.
---@param n integer? The number of characters to return. Defaults to `1`.
---@return string
---@protected
function Parser:index(i, n)
    n = n or 1
    return self._text:sub(i, i + n - 1)
end

---Returns the length of the current text.
---@return integer
---@protected
function Parser:len()
    return #self._text
end

---Matches a string pattern against the parser's current text.
---@param pattern string The string pattern.
---@param pos integer? A position to start from. Defaults to the current position.
---@return any...
---@protected
function Parser:match(pattern, pos)
    return self._text:match(pattern, pos or self._ptr)
end

---Gets the current `n` bytes at the current pointer.
---@param n integer? The number of bytes to get. Defaults to `1`.
---@return string
---@protected
function Parser:peek(n)
    return self:index(self._ptr, n or 1)
end

---Gets the current `n` bytes at the current pointer.
---Returns `nil` if the bytes aren't found in the given set.
---@generic T : string
---@param set SetTable<T> The set of valid strings.
---@param n integer? The number of bytes to get. Defaults to 1.
---@param m integer? The maximum number of bytes to get. If given, `n` is treated as a minimum.
---@return T?
---@protected
function Parser:peekMatching(set, n, m)
    n = n or 1
    m = m or n

    local pos = self._ptr
    for i = m, n, -1 do
        local chars = self:index(pos, i)
        if set[chars] then
            return chars
        end
    end
end

---Performs the parsing operation.
---@protected
function Parser:perform()
    while self._ptr <= self:len() do
        if not self:readExpression() then
            local msg = string.format('unexpected character: `%s`', self:peek())
            self:errorHere(msg, self._tree, nil, 'BAD_CHAR')
            self._ptr = self._ptr + 1 -- avoid infinite loops
        end
    end
end

---Gets or sets the current pointer position.
---@param value integer?
---@return integer
---@protected
function Parser:pos(value)
    if value then
        self._ptr = value
    end

    return self._ptr
end

---Performs postprocessing on the tree.
---@return any
---@protected
function Parser:postprocess()
    return self._tree
end

---Reads the current `n` bytes at the current pointer and moves the pointer forward.
---@param n integer? The number of bytes to read. Defaults to `1`.
---@return string
---@protected
function Parser:read(n)
    n = n or 1

    local result = self:peek(n)
    self._ptr = self._ptr + n

    return result
end

---Reads the current `n` bytes at the current pointer and moves the pointer forward.
---Returns `nil` and does not move the pointer if the bytes aren't found in the given set.
---@generic T : string
---@param set SetTable<T> The set of valid strings.
---@param n integer? The number of bytes to get. Defaults to 1.
---@param m integer? The maximum number of bytes to get. If given, `n` is treated as a minimum.
---@return T?
---@protected
function Parser:readMatching(set, n, m)
    local result = self:peekMatching(set, n, m)
    if not result then
        return
    end

    self._ptr = self._ptr + #result
    return result
end

---Reads an expression.
---Must be implemented by subclasses.
---@return TNode?
---@protected
function Parser:readExpression()
    error('not implemented')
end

---Moves the parser pointer backwards.
---@param inc integer? The value to move backwards by. Defaults to `1`.
---@return integer
---@protected
function Parser:rewind(inc)
    self._ptr = self._ptr - (inc or 1)
    return self._ptr
end

---Sets the current tree node and returns the old node.
---@param node TNode?
---@return TNode? oldNode
---@protected
function Parser:setCurrentNode(node)
    local old = self._node
    self._node = node

    return old
end

---Sets the end position of a tree node's range.
---@param node TNode?
---@param stop integer? The end position. If omitted, the current pointer is used.
---@protected
function Parser:setNodeEnd(node, stop)
    if not node then
        return
    end

    self:setNodeRange(node, nil, stop or self._ptr)
end

---Sets the range of a tree node.
---@param node TNode
---@param start integer?
---@param stop integer?
---@protected
function Parser:setNodeRange(node, start, stop)
    local len = #self._text
    local pos = self._ptr
    node.range[1] = core.clamp(start or node.range[1] or pos, 1, len)
    node.range[2] = core.clamp(stop or node.range[2] or pos, 1, len)

    if node.range[2] < node.range[1] then
        node.range[2] = node.range[1]
    end
end

---Sets the start position of a tree node's range.
---@param node TNode
---@param start integer? The start position. If omitted, the current pointer is used.
---@protected
function Parser:setNodeStart(node, start)
    if not node then
        return
    end

    self:setNodeRange(node, start or self._ptr)
end

---Skips text if matched.
---@param pattern string
function Parser:skipMatch(pattern)
    local match = self:match(pattern)
    if type(match) == 'string' and #match > 0 then
        self._ptr = self._ptr + #match
    end
end

---Skips whitespace characters.
---This uses the `%s` string pattern.
function Parser:skipWhitespace()
    return self:skipMatch('^%s+')
end

---Reports a parser warning.
---@param err string
---@param node TNode?
---@param start integer?
---@param stop integer?
---@param id string?
---@protected
function Parser:warning(err, node, start, stop, id)
    node = node or self._tree
    self._warnings[#self._warnings + 1] = {
        message = err,
        id = id,
        node = node ~= self._tree and node or nil,
        range = {
            start or node.range[1],
            stop or node.range[2],
        },
    }
end

---Reports a parser warning at the current position.
---@param err string
---@param node TNode?
---@param len integer?
---@param id string?
---@protected
function Parser:warningHere(err, node, len, id)
    len = len or 1
    local pos = self._ptr
    self:warning(err, node or self._tree, pos, pos + len - 1, id)
end


---Creates a new parser.
---@generic TNode : ParseNode
---@param options Args.Parser?
---@return Parser<TNode>
function Parser:new(options)
    local this = core.new(self)

    options = options or {} --[[@as Args.Parser]]

    this._raiseErrors = options.raiseErrors or false
    this._treeNodeType = 'tree'
    this:reset()

    return this
end


return Parser

--#region Type Definitions

---@class Args.Parser
---@field raiseErrors? boolean Flag for whether errors created by the parser should be thrown.
---Defaults to `false`.


---@class ParserError<TNode : ParseNode>
---@field message string The error message.
---@field id? string The identifier of the error type.
---@field node? TNode The node at which the error occurred.
---@field range [integer, integer] The start and stop range of the error as a 2-element array.

---@class ParseNode
---@field type string The type of the node.
---@field range [integer, integer] The start and stop range of the node as a 2-element array.

---@class BasicParseNode : ParseNode
---@field value? string The value of the node.
---@field children? BasicParseNode[] The list of child nodes.

--#endregion
