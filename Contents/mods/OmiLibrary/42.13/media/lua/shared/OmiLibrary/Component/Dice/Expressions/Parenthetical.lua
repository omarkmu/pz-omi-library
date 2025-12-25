---Expression type representing an expression enclosed in parentheses.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'
local Base = require 'OmiLibrary/Component/Dice/Expressions/ResolvableNumber'

local format = string.format

---@class dice.Parenthetical : dice.ResolvableNumber
---@field type 'Parenthetical' The expression type.
---@field value Expression The expression value.
---@field operations Operation<SetOperator>[] Operations on the parenthetical.
local Parenthetical = Base:derive('Parenthetical')


---Returns the list of child expressions.
---@return Expression[]
function Parenthetical:getChildren()
    return { self.value }
end

---Returns the list representation of the object.
---@return Expression[]
function Parenthetical:getList()
    return self.value:getList()
end

---Returns the numerical value of the parenthetical if it's kept.
---@return number?
---@return DiceRollError?
function Parenthetical:getTotal()
    if not self.kept then
        return 0
    end

    return self.value:getTotal()
end

---Converts the parenthetical into a plain table that can be sent over the network.
---@return table plain
function Parenthetical:toNetwork()
    local plain = Base.toNetwork(self)
    plain.value = self.value:toNetwork()
    plain.operations = core.copyList(self.operations)

    return plain
end


---Returns the expression as a string.
---@protected
function Parenthetical:__tostring()
    return format(
        '<Parenthetical value=%s operations=%s>',
        tostring(self.value),
        self._operationsToString(self.operations)
    )
end


---Creates a new literal expression.
---@param args Args.DiceParenthetical Arguments for creation of the expression.
---@return Parenthetical
function Parenthetical:new(args)
    local this = core.new(self, Base.new, args)

    this.type = 'Parenthetical'
    this.value = args.value
    this.operations = args.operations

    return this
end

return Parenthetical

--#region Type Definitions

---@class Args.DiceParenthetical : Args.DiceBase
---@field value Expression The expression value.
---@field operations Operation<SetOperator>[] Operations on the parenthetical.

--#endregion
