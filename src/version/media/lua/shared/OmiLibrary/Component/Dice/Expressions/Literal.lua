---Expression type representing a literal number.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'
local Base = require 'OmiLibrary/Component/Dice/Expressions/ResolvableNumber'

local format = string.format

---@class dice.Literal : dice.ResolvableNumber
---@field type 'Literal' The expression type.
---@field values number[] The value history for the literal.
---@field exploded boolean Flag for whether the value was exploded.
local Literal = Base:derive('Literal')


---Marks the literal as exploded.
function Literal:explode()
    self.exploded = true
end

---Returns the list representation of the object.
---@return Literal[]
function Literal:getList()
    return { self }
end

---Returns the numerical value of the literal.
---@return number
function Literal:getNumber()
    return self.values[#self.values] --[[@as number]]
end

---Converts the literal into a plain table that can be sent over the network.
---@return table plain
function Literal:toNetwork()
    local plain = Base.toNetwork(self)
    plain.exploded = self.exploded
    plain.values = core.copyList(self.values)

    return plain
end

---Updates the value of the literal.
---@param value number
function Literal:update(value)
    self.values[#self.values + 1] = value
end


---Returns the expression as a string.
---@protected
function Literal:__tostring()
    local str = format('<Literal %f>', self.values[#self.values]):gsub('%.?0+>$', '>')
    return str
end


---Creates a new literal expression.
---@param args Args.DiceLiteral Arguments for creation of the expression.
function Literal:new(args)
    local this = core.new(self, Base.new, args)

    this.type = 'Literal'
    this.exploded = false
    this.values = { args.value }

    return this
end

return Literal

--#region Type Definitions

---@class Args.DiceLiteral : Args.DiceBase
---@field value number The value of the literal.

--#endregion
