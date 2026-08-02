---Top-level expression type for dice evaluation.
---@namespace omi
---@using omi.dice

local Base = require 'OmiLibrary/Component/Dice/Expressions/ResolvableNumber'

local format = string.format

---@class dice.RollExpression : ResolvableNumber
---@field type 'RollExpression' The expression type.
---@field roll Expression The inner roll expression.
local RollExpression = Base:derive('RollExpression')

---Returns the child expression in a list.
---@return Expression[]
function RollExpression:getChildren()
    return { self.roll }
end

---Returns the child expression in a list.
---@return Expression[]
function RollExpression:getList()
    return { self.roll }
end

---Converts the expression into a plain table that can be sent over the network.
---@return table plain
function RollExpression:toNetwork()
    local plain = Base.toNetwork(self)
    plain.roll = self.roll:toNetwork()

    return plain
end


---Returns the expression as a string.
---@protected
function RollExpression:__tostring()
    return format(
        '<RollExpression roll=%s>',
        tostring(self.roll)
    )
end


---Creates an expression.
---@param args Args.RollExpression Arguments for creation of the expression.
---@return RollExpression
function RollExpression:new(args)
    local this = Base.new(self, args) --[[@as RollExpression]]

    this.type = 'RollExpression'
    this.roll = args.roll

    return this
end

return RollExpression

--#region Type Definitions

---@class Args.RollExpression : Args.DiceBase
---@field roll Expression The inner expression.

--#endregion
