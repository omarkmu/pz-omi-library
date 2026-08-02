---Parser for dice expressions.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'
local BaseParser = require 'OmiLibrary/Component/Core/Parser'
local ParseError = require 'OmiLibrary/Component/Dice/DiceParseError'

---@class dice.DiceParser : Parser<AST.BaseNode>
---@field protected _allowIdentifiers boolean Flag for whether identifiers should be read.
local Parser = BaseParser:derive('DiceParser')

---@enum dice.AST.NodeType
Parser.NodeType = {
    BinOp = 'BinOp',
    UnOp = 'UnOp',
    Literal = 'Literal',
    Dice = 'Dice',
    Set = 'Set',
    Parenthetical = 'Parenthetical',
    Identifier = 'Identifier',
}

local NodeType = Parser.NodeType

local COMPARISON_OPS = {
    ['>'] = true,
    ['<'] = true,
    ['=='] = true,
    ['!='] = true,
    ['>='] = true,
    ['<='] = true,
}

local ADD_SUB_OPS = {
    ['+'] = true,
    ['-'] = true,
}

local MUL_DIV_OPS = {
    ['*'] = true,
    ['/'] = true,
    ['//'] = true,
    ['%'] = true,
}

local SET_OPS = {
    k = true,
    p = true,
}

local SELECTOR_TYPES = {
    l = true,
    h = true,
    ['>'] = true,
    ['<'] = true,
}

local DICE_OPS = core.extendCopy(SET_OPS, {
    rr = true,
    ro = true,
    ra = true,
    e = true,
    mi = true,
    ma = true,
})

local NO_MERGE_OPS = {
    mi = true,
    ma = true,
}


---Performs parsing of dice expression.
---@return AST.Expression?
---@return DiceParseError?
function Parser:parse(text)
    self:reset(text)

    local expr, err = self:readExpression()
    if err or not expr then
        return nil, err
    end

    local c = self:peek()
    if c ~= '' then
        return self:throw('UnexpectedCharacter', c)
    end

    return expr
end


---Attempts to read an addition or subtraction operation.
---
---Reads multiplication, a unary operator, or a number expression
---if no matching operation is found.
---@return AST.Expression?
---@return DiceParseError?
---@protected
function Parser:readAddition()
    return self:readBinOp(self.readMultiplication, ADD_SUB_OPS)
end

---Attempts to read a binary operation.
---Handles consecutive operations of the same type.
---Returns the left node if no matching operator is found.
---@param readNode fun(self: DiceParser): AST.Expression?, DiceParseError?
---@param set SetTable<string> The set to pass to `peekMatching` and `readMatching`.
---@param ... any Arguments for `peekMatching` and `readMatching`.
---@return AST.Expression?
---@return DiceParseError?
---@protected
function Parser:readBinOp(readNode, set, ...)
    local left ---@type AST.Expression?
    local err ---@type DiceParseError?
    while self:hasNext() do
        left, err = self:readBinOpInner(readNode, left, set, ...)

        if err or not left then
            return nil, err
        end

        if not self:peekMatching(set, ...) then
            break
        end
    end

    return left
end

---Attempts to read a binary operation.
---Returns the left node if no matching operator is found.
---@param readNode fun(self: DiceParser): AST.Expression?, DiceParseError?
---@param left AST.Expression? The left node to use. Read if not given.
---@param ... any Arguments for `readMatching`.
---@return AST.Expression?
---@return DiceParseError?
---@protected
function Parser:readBinOpInner(readNode, left, ...)
    local start = self._ptr
    local err ---@type DiceParseError?

    if not left then
        left, err = readNode(self)
    end

    if err then
        return nil, err
    elseif not left then
        return
    end

    self:skipWhitespace()

    local op = self:readMatching(...)
    if not op then
        return left
    end

    self:skipWhitespace()

    local right
    right, err = readNode(self)
    if err then
        return nil, err
    elseif not right then
        return self:throw('MissingExpression', op)
    end

    self:skipWhitespace()

    return self:createNode(NodeType.BinOp, {
        range = { start },
        op = op,
        left = left,
        right = right,
    })
end

---Attempts to read a comparison operation.
---Reads any expression of lower precedence if no matching operator is found.
---@return AST.Expression?
---@return DiceParseError?
---@protected
function Parser:readComparison()
    return self:readBinOp(self.readAddition, COMPARISON_OPS, 1, 2)
end

---Reads a decimal number.
---@return number?
---@protected
function Parser:readDecimal()
    local chars = self:match('^%d*%.%d*')
    if not chars or chars == '.' then
        return
    end

    self._ptr = self._ptr + #chars
    return tonumber(chars)
end

---Reads a dice expression.
---@return AST.Dice?
---@return DiceParseError?
---@protected
function Parser:readDiceExpression()
    local start = self._ptr
    local count = self:readInteger()

    if self:peek() ~= 'd' then
        self._ptr = start
        return
    end

    self._ptr = self._ptr + 1

    ---@type (integer | '%')?
    local size
    if self:peek() == '%' then
        size = '%'
        self._ptr = self._ptr + 1
    else
        size = self:readInteger()
    end

    if not size then
        return self:throw('MissingDiceValue')
    end

    ---@type AST.Dice
    local node = self:createNode(NodeType.Dice, {
        range = { start },
        count = count,
        size = size,
        annotations = {},
        operations = {},
    })

    local err = self:readOperations(node.operations, DICE_OPS)
    if err then
        return nil, err
    end

    return node
end

---Reads a single acceptable expression.
---@return AST.Expression?
---@return DiceParseError?
---@protected
function Parser:readExpression()
    self:skipWhitespace()
    local expr, err = self:readComparison()

    if err then
        return nil, err
    elseif expr then
        return expr
    end

    local c = self:peek()
    if c == '' then
        return self:throw('Empty')
    else
        return self:throw('UnexpectedCharacter', c)
    end
end

---Reads an identifier expression.
---@return AST.Identifier?
---@protected
function Parser:readIdentifier()
    -- avoid matching on what should be treated as a dice expression
    if self:match('^d$') or self:match('^d[^_%a]') then
        return
    end

    local name = self:match('^[%a_]+')
    if not name then
        return
    end

    local start = self._ptr
    self._ptr = self._ptr + #name

    ---@type AST.Identifier
    local node = self:createNode(NodeType.Identifier, {
        range = { start },
        name = name,
        annotations = {},
    })

    return node
end

---Reads a series of digits and converts them into a number.
---@return integer?
---@protected
function Parser:readInteger()
    local digits = self:match('^%d+')
    if not digits then
        return
    end

    self._ptr = self._ptr + #digits
    return tonumber(digits) --[[@as integer]]
end

---Attempts to read a multiplication or division operation.
---Reads a unary operator or number expression if no matching operation is found.
---@return AST.Expression?
---@return DiceParseError?
---@protected
function Parser:readMultiplication()
    return self:readBinOp(self.readUnOp, MUL_DIV_OPS, 1, 2)
end

---Attempts to read a number expression (dice, set, or literal) with an annotation.
---@return AST.NumberExpression?
---@return DiceParseError?
---@protected
function Parser:readNumberAnnotated()
    local expr, err = self:readNumberExpression()
    if not expr then
        return nil, err
    end

    self:skipWhitespace()

    while true do
        ---@type string?
        local annot = self:match('^%[(.-)%]')
        if not annot then
            break
        end

        expr.annotations[#expr.annotations + 1] = '[' .. annot:trim() .. ']'
        self._ptr = self._ptr + #annot + 2
        self:skipWhitespace()
    end

    return expr
end

---Reads a number expression (dice, set, or literal).
---@return AST.NumberExpression?
---@return DiceParseError?
---@protected
function Parser:readNumberExpression()
    local start = self._ptr

    local setExpr, err = self:readParenthetical()
    if err then
        return nil, err
    elseif setExpr then
        return setExpr
    end

    local decimal = self:readDecimal()
    if decimal then
        return self:createNode(NodeType.Literal, {
            range = { start },
            value = decimal,
            annotations = {},
        })
    end

    if self._allowIdentifiers then
        local identExpr = self:readIdentifier()
        if identExpr then
            return identExpr
        end
    end

    local diceExpr
    diceExpr, err = self:readDiceExpression()
    if err then
        return nil, err
    elseif diceExpr then
        return diceExpr
    end

    local integer = self:readInteger()
    if integer then
        return self:createNode(NodeType.Literal, {
            range = { start },
            value = integer,
            annotations = {},
        })
    end
end

---Reads operations on a dice or set.
---@generic T : string
---@param operations Operation<T>[] Destination for operations.
---@param opSet table<T, true> Set of accepted operator types.
---@return DiceParseError?
---@protected
function Parser:readOperations(operations, opSet)
    while self:hasNext() do
        local op = self:readMatching(opSet, 1, 2)
        if not op then
            break
        end

        local sel, err = self:readSelector()
        if not sel then
            return err
        end

        local last = operations[#operations]
        if not NO_MERGE_OPS[op] and last and last.type == op then
            last.selectors[#last.selectors + 1] = sel
        else
            operations[#operations + 1] = {
                type = op,
                selectors = { sel },
            }
        end
    end
end

---Reads a selector.
---Raises an error if a selector cannot be read.
---@return Selector?
---@return DiceParseError?
---@protected
function Parser:readSelector()
    local selType = self:readMatching(SELECTOR_TYPES)
    local value = self:readInteger()

    if not value then
        return self:throw('MissingSelectorValue')
    end

    return {
        type = selType,
        value = value,
    }
end

---Attempts to read a set or parenthetical expression.
---@return (AST.Set | AST.Parenthetical)?
---@return DiceParseError?
---@protected
function Parser:readParenthetical()
    local start = self._ptr
    if self:peek() ~= '(' then
        return
    end

    self._ptr = self._ptr + 1
    self:skipWhitespace()

    local hasComma = false
    local values = {} ---@type AST.Expression[]

    while self:hasNext() do
        local expr, err = self:readExpression()
        if err or not expr then
            return nil, err
        end

        values[#values + 1] = expr

        local c = self:peek()
        if c == ',' then
            hasComma = true

            self._ptr = self._ptr + 1
            self:skipWhitespace()

            c = self:peek()
        end

        if c == ')' then
            break
        end
    end

    if self:peek() ~= ')' then
        return self:throw('MissingEndParenthesis')
    end

    self._ptr = self._ptr + 1
    self:skipWhitespace()

    local node
    if #values == 1 and not hasComma then
        ---@type AST.Parenthetical
        node = self:createNode(NodeType.Parenthetical, {
            range = { start },
            value = values[1],
            annotations = {},
            operations = {},
        })
    else
        ---@type AST.Set
        node = self:createNode(NodeType.Set, {
            range = { start },
            values = values,
            annotations = {},
            operations = {},
        })
    end


    local err = self:readOperations(node.operations, SET_OPS)
    if err then
        return nil, err
    end

    return node
end

---Reads a unary operation or number expression.
---@return (AST.UnOp | AST.NumberExpression)?
---@return DiceParseError?
---@protected
function Parser:readUnOp()
    local start = self._ptr

    local op = self:peek()
    if op ~= '+' and op ~= '-' then
        return self:readNumberAnnotated()
    end

    self._ptr = self._ptr + 1
    self:skipWhitespace()
    local value, err = self:readNumberAnnotated()
    if err then
        return nil, err
    elseif not value then
        return self:throw('MissingExpression', op)
    end

    return self:createNode(NodeType.UnOp, {
        range = { start },
        op = op,
        value = value,
    })
end

---Creates a parser error. Returns `nil` and the error.
---@param code DiceParseError.Code The error code.
---@param ...any Arguments for the error.
---@return nil
---@return DiceParseError
---@protected
function Parser:throw(code, ...)
    return nil, ParseError:new(code, ...)
end


---Creates a new dice expression parser.
---@param options Args.DiceParser?
---@return DiceParser
function Parser:new(options)
    options = options or {} --[[@as Args.DiceParser]]

    local this = core.new(self, BaseParser.new, options)
    this._allowIdentifiers = options.allowIdentifiers or false

    return this
end


return Parser


--#region Type Definitions

---@class Args.DiceParser : Args.Parser
---@field allowIdentifiers? boolean Flag for whether identifiers should be read. Defaults to `false`.

--#endregion
