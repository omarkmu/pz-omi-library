---Expression type representing a set of expressions.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'
local Base = require 'OmiLibrary/Component/Dice/Expressions/ResolvableNumber'

local format = string.format

---@class dice.DiceSet : dice.ResolvableNumber
---@field type 'DiceSet' The expression type.
---@field values Expression[] The set values.
---@field operations Operation<SetOperator>[] Operations on the set.
local DiceSet = Base:derive('DiceSet')


---Returns the list of child expressions.
---@return Expression[]
function DiceSet:getChildren()
    return self.values
end

---Returns the list representation of the object.
---@return Expression[]
function DiceSet:getList()
    return self.values
end

---Converts the dice set into a plain table that can be sent over the network.
---@return table plain
function DiceSet:toNetwork()
    local plain = Base.toNetwork(self)
    plain.operations = core.copyList(self.operations)

    plain.values = {}
    for i = 1, #self.values do
        plain.values[i] = self.values[i]:toNetwork()
    end

    return plain
end


---Returns the expression as a string.
---@protected
function DiceSet:__tostring()
    return format(
        '<DiceSet values=%s operations=%s>',
        self._listToString(self.values),
        self._operationsToString(self.operations)
    )
end


---Creates a new literal expression.
---@param args Args.DiceSet Arguments for creation of the expression.
---@return DiceSet
function DiceSet:new(args)
    local this = core.new(self, Base.new, args)

    this.type = 'DiceSet'
    this.values = args.values or {}
    this.operations = args.operations or {}

    return this
end

return DiceSet

--#region Type Definitions

---@class Args.DiceSet : Args.DiceBase
---@field values? Expression[] The expression values.
---@field operations? Operation<SetOperator>[] Operations on the parenthetical.

--#endregion
