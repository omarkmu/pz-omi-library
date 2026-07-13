---Plain text stringifier.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'
local BaseStringifier = require 'OmiLibrary/Component/Dice/Stringifiers/BaseStringifier'

local concat = table.concat
local format = string.format

---@class dice.SimpleStringifier : Stringifier
---@field protected _includeTotal boolean Flag for whether to include the total.
---@field protected _inDropped boolean Flag for whether the stringifier is currently in a dropped value.
---@field protected _doStrikethrough boolean Flag for whether dropped values should be indicated with a strikethrough.
---@field protected _listSeparator string The string to use for separating items in a list.
local SimpleStringifier = BaseStringifier:derive('SimpleStringifier')


---Converts the expression to a string.
---@param expr RollExpression
---@return string
function SimpleStringifier:stringify(expr)
    self._inDropped = false
    return BaseStringifier.stringify(self, expr)
end


---Alters a stringified result to indicate that an expression is dropped.
---@param str string
---@param expr Expression
---@protected
---@diagnostic disable-next-line: unused
function SimpleStringifier:_formatDropped(str, expr)
    if not self._doStrikethrough then
        return str
    end

    return '~~' .. str .. '~~'
end

---Called to format an identifier name.
---@param name string
---@return string
---@protected
function SimpleStringifier:_formatIdentifierName(name)
    return name
end

---Called to format a binary or unary operator.
---@param op BinaryOperator | UnaryOperator
---@return string
---@protected
function SimpleStringifier:_formatOperator(op)
    return op
end

---Called to format a selector type.
---@param sel SelectorType?
---@return string
---@protected
function SimpleStringifier:_formatSelectorType(sel)
    if not sel then
        return ''
    end

    return sel
end

---Converts the expression to a string.
---Called for each expression in the tree.
---@param expr Expression
---@return string
---@protected
function SimpleStringifier:_stringify(expr)
    if not expr.kept and not self._inDropped then
        self._inDropped = true
        local str = BaseStringifier._stringify(self, expr)
        self._inDropped = false

        return self:_formatDropped(str, expr)
    end

    return BaseStringifier._stringify(self, expr)
end

---Converts a dice expression to a string.
---@param expr Dice
---@return string
---@protected
function SimpleStringifier:_stringifyDice(expr)
    local results = {}

    for i = 1, #expr.values do
        results[#results + 1] = self:_stringify(expr.values[i])
    end

    return format(
        '%sd%s%s (%s)',
        expr.count ~= 1 and tostring(expr.count) or '',
        tostring(expr.size),
        self:_stringifyOperations(expr.operations),
        concat(results, self._listSeparator)
    )
end

---Converts a die to a string.
---@param expr Die
---@return string
---@protected
function SimpleStringifier:_stringifyDie(expr)
    local results = {}

    for i = 1, #expr.values do
        results[#results + 1] = self:_stringify(expr.values[i])
    end

    return concat(results, self._listSeparator)
end

---Converts a binary operation expression to a string.
---@param expr BinaryOp
---@return string
---@protected
function SimpleStringifier:_stringifyBinOp(expr)
    local left = self:_stringify(expr.left)
    local right = self:_stringify(expr.right)

    return format('%s %s %s', left, self:_formatOperator(expr.op), right)
end

---Converts the expression to a string.
---Called for the top-level expression in the tree.
---@param expr RollExpression
---@return string
---@protected
function SimpleStringifier:_stringifyExpression(expr)
    local lhs = self:_stringify(expr.roll)
    if not self._includeTotal then
        return lhs
    end

    return lhs .. ' = ' .. expr:getTotal()
end

---Converts an identifier expression to a string.
---@param expr Identifier
---@return string
---@protected
function SimpleStringifier:_stringifyIdentifier(expr)
    local name = self:_formatIdentifierName(expr.name)
    local value = self:_stringify(expr.value)

    return format('%s (%s)', name, value)
end

---Converts a literal to a string.
---@param expr Literal
---@return string
---@protected
function SimpleStringifier:_stringifyLiteral(expr)
    local history = concat(expr.values, ' -> ')
    if expr.exploded then
        return history .. '!'
    end

    return history
end

---Converts set or dice operations to a string.
---@param operations Operation<string>[]
---@return string
---@protected
function SimpleStringifier:_stringifyOperations(operations)
    local result = {} ---@type (string | number)[]

    for i = 1, #operations do
        local op = operations[i]

        for j = 1, #op.selectors do
            local sel = op.selectors[j]

            result[#result + 1] = op.type
            result[#result + 1] = self:_formatSelectorType(sel.type)
            result[#result + 1] = sel.value
        end
    end

    return concat(result)
end

---Converts a parenthetical expression to a string.
---@param expr Parenthetical
---@return string
---@protected
function SimpleStringifier:_stringifyParenthetical(expr)
    local result = self:_stringify(expr.value)
    local ops = self:_stringifyOperations(expr.operations)
    return '(' .. result .. ')' .. ops
end

---Converts a set expression to a string.
---@param expr DiceSet
---@return string
---@protected
function SimpleStringifier:_stringifySet(expr)
    local values = {}

    for i = 1, #expr.values do
        values[#values + 1] = self:_stringify(expr.values[i])
    end

    local out = concat(values, self._listSeparator)
    local ops = self:_stringifyOperations(expr.operations)

    if #expr.values == 1 then
        return '(' .. out .. ',)' .. ops
    end

    return '(' .. out .. ')' .. ops
end

---Converts a unary operation expression to a string.
---@param expr UnaryOp
---@return string
---@protected
function SimpleStringifier:_stringifyUnOp(expr)
    return self:_formatOperator(expr.op) .. self:_stringify(expr.value)
end

---Creates a new stringifier.
---@param args Args.DiceSimpleStringifier? Arguments for creation of the stringifier.
---@return SimpleStringifier
function SimpleStringifier:new(args)
    local this = core.new(self, BaseStringifier.new)

    args = args or {} --[[@as Args.DiceSimpleStringifier]]

    this._inDropped = false
    this._includeTotal = args.includeTotal ~= false
    this._doStrikethrough = args.doStrikethrough ~= false
    this._listSeparator = ', '

    return this
end


return SimpleStringifier

--#region Type Definitions

---@class Args.DiceSimpleStringifier
---@field includeTotal boolean? Flag for whether to include the total. Defaults to `true`.
---@field doStrikethrough boolean? Flag for whether dropped values should be
---indicated with a strikethrough. Defaults to `true`.

--#endregion
