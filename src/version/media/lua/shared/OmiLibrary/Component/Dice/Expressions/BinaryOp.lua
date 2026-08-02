---Expression type representing a binary operation.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'
local Base = require 'OmiLibrary/Component/Dice/Expressions/ResolvableNumber'
local RollError = require 'OmiLibrary/Component/Dice/DiceRollError'

local floor = math.floor
local format = string.format

---@class dice.BinaryOp : dice.ResolvableNumber
---@field type 'BinaryOp' The expression type.
---@field left Expression The left expression value.
---@field right Expression The right expression value.
---@field op BinaryOperator The operation of the expression.
local BinaryOp = Base:derive('BinaryOp')

---Handler functions for applying operations.
---@type table<BinaryOperator, fun(l: number, r: number): number?, DiceRollError?>
BinaryOp.OPERATIONS = {
    ['+'] = function(l, r) return l + r end,
    ['-'] = function(l, r) return l - r end,
    ['*'] = function(l, r) return l * r end,
    ['/'] = function(l, r)
        if r == 0 then
            return nil, RollError:new('DivideByZero')
        end

        return l / r
    end,
    ['//'] = function(l, r)
        if r == 0 then
            return nil, RollError:new('DivideByZero')
        end

        return floor(l / r)
    end,
    ['%'] = function(l, r)
        if r == 0 then
            return nil, RollError:new('DivideByZero')
        end

        return l % r
    end,
    ['<'] = function(l, r) return l < r and 1 or 0 end,
    ['>'] = function(l, r) return l > r and 1 or 0 end,
    ['=='] = function(l, r) return l == r and 1 or 0 end,
    ['!='] = function(l, r) return l ~= r and 1 or 0 end,
    ['>='] = function(l, r) return l >= r and 1 or 0 end,
    ['<='] = function(l, r) return l <= r and 1 or 0 end,
}

---Returns the list of child expressions.
---@return Expression[]
function BinaryOp:getChildren()
    return { self.left, self.right }
end

---Returns the list representation of the object.
---@return Expression[]
function BinaryOp:getList()
    return { self }
end

---Returns the numerical value of the expression.
---@return number?
---@return DiceRollError?
function BinaryOp:getNumber()
    local handler = BinaryOp.OPERATIONS[self.op]
    local left, right, err

    left, err = self.left:getTotal()
    if not left then
        return nil, err
    end

    right, err = self.right:getTotal()
    if not right then
        return nil, err
    end

    return handler(left, right)
end

---Converts the binary operation into a plain table that can be sent over the network.
---@return table plain
function BinaryOp:toNetwork()
    local plain = Base.toNetwork(self)
    plain.type = self.type
    plain.op = self.op
    plain.left = self.left:toNetwork()
    plain.right = self.right:toNetwork()

    return plain
end


---Returns the expression as a string.
---@protected
function BinaryOp:__tostring()
    return format(
        '<BinaryOp op=%s left=%s right=%s>',
        self.op,
        tostring(self.left),
        tostring(self.right)
    )
end


---Creates a new binary operation expression.
---@param args Args.DiceBinaryOp Arguments for creation of the expression.
---@return BinaryOp
function BinaryOp:new(args)
    local this = core.new(self, Base.new, args)

    this.type = 'BinaryOp'
    this.op = args.op
    this.left = args.left
    this.right = args.right

    return this
end

return BinaryOp

--#region Type Definitions

---@class Args.DiceBinaryOp : Args.DiceBase
---@field op BinaryOperator The operation of the expression.
---@field left Expression The left expression value.
---@field right Expression The right expression value.

--#endregion
