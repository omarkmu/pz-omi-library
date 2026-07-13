---Expression type representing a unary operation.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'
local Base = require 'OmiLibrary/Component/Dice/Expressions/ResolvableNumber'

local format = string.format

---@class dice.UnaryOp : dice.ResolvableNumber
---@field type 'UnaryOp' The expression type.
---@field value Expression The expression value.
---@field op UnaryOperator The operation of the expression.
local UnaryOp = Base:derive('UnaryOp')


---Returns the list of child expressions.
---@return Expression[]
function UnaryOp:getChildren()
    return { self.value }
end

---Returns the list representation of the object.
---@return Expression[]
function UnaryOp:getList()
    return { self }
end

---Returns the numerical value of the expression.
---@return number?
---@return DiceRollError?
function UnaryOp:getNumber()
    local num, err = self.value:getTotal()
    if not num then
        return nil, err
    end

    if self.op == '+' then
        return num
    end

    return -num
end

---Converts the unary operation into a plain table that can be sent over the network.
---@return table plain
function UnaryOp:toNetwork()
    local plain = Base.toNetwork(self)
    plain.type = self.type
    plain.op = self.op
    plain.value = self.value:toNetwork()

    return plain
end


---Returns the expression as a string.
---@protected
function UnaryOp:__tostring()
    return format(
        '<UnaryOp op=%s value=%s>',
        self.op,
        tostring(self.value)
    )
end


---Creates a new unary operation expression.
---@param args Args.DiceUnaryOp Arguments for creation of the expression.
---@return UnaryOp
function UnaryOp:new(args)
    local this = core.new(self, Base.new, args)

    this.type = 'UnaryOp'
    this.op = args.op
    this.value = args.value

    return this
end

return UnaryOp

--#region Type Definitions

---@class Args.DiceUnaryOp : Args.DiceBase
---@field op UnaryOperator The operation of the expression.
---@field value Expression The expression value.

--#endregion
