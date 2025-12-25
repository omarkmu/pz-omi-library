---Abstract base class for stringifying dice roll results.
---@namespace omi.dice
---@using omi

local core = require 'OmiLibrary/Module/Utils'

---@class Stringifier : Class
---@field protected _handlers table<string, StringifyFunction> Associates expression types to functions for stringifying.
local Stringifier = core.class('Stringifier')


---Converts the expression to a string.
---@param expr RollExpression
---@return string
function Stringifier:stringify(expr)
    return self:_stringify(expr)
end


---Called to add an annotation to the expression, if present.
---@param str string
---@param expr Expression
---@return string
---@protected
function Stringifier:_formatAnnotation(str, expr)
    return str .. ' ' .. expr.annotation
end

---Converts the expression to a string.
---Called for each expression in the tree.
---@param expr Expression
---@return string
---@protected
function Stringifier:_stringify(expr)
    local handler = self._handlers[expr.type]
    assert(handler ~= nil, 'Missing expression type handler')

    local result = handler(self, expr)
    if expr.annotation ~= '' then
        return self:_formatAnnotation(result, expr)
    end

    return result
end

---Converts a dice expression to a string.
---@param expr Dice
---@return string
---@protected
function Stringifier:_stringifyDice(expr)
    error('not implemented')
end

---Converts a die to a string.
---@param expr Die
---@return string
---@protected
function Stringifier:_stringifyDie(expr)
    error('not implemented')
end

---Converts a binary operation expression to a string.
---@param expr BinaryOp
---@return string
---@protected
function Stringifier:_stringifyBinOp(expr)
    error('not implemented')
end

---Converts the expression to a string.
---Called for the top-level expression in the tree.
---@param expr RollExpression
---@return string
---@protected
function Stringifier:_stringifyExpression(expr)
    error('not implemented')
end

---Converts an identifier expression to a string.
---@param expr Identifier
---@return string
---@protected
function Stringifier:_stringifyIdentifier(expr)
    error('not implemented')
end

---Converts a literal to a string.
---@param expr Literal
---@return string
---@protected
function Stringifier:_stringifyLiteral(expr)
    error('not implemented')
end

---Converts a parenthetical expression to a string.
---@param expr Parenthetical
---@return string
---@protected
function Stringifier:_stringifyParenthetical(expr)
    error('not implemented')
end

---Converts a set expression to a string.
---@param expr DiceSet
---@return string
---@protected
function Stringifier:_stringifySet(expr)
    error('not implemented')
end

---Converts a unary operation expression to a string.
---@param expr UnaryOp
---@return string
---@protected
function Stringifier:_stringifyUnOp(expr)
    error('not implemented')
end


---Creates a new stringifier instance.
---@return Stringifier
---@protected
function Stringifier:new()
    local this = core.new(self)

    this._handlers = {
        Die = self._stringifyDie,
        Dice = self._stringifyDice,
        DiceSet = self._stringifySet,
        UnaryOp = self._stringifyUnOp,
        BinaryOp = self._stringifyBinOp,
        Literal = self._stringifyLiteral,
        Parenthetical = self._stringifyParenthetical,
        Identifier = self._stringifyIdentifier,
        RollExpression = self._stringifyExpression,
    }

    return this
end

return Stringifier
