---Expression type representing an identifier.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'
local Base = require 'OmiLibrary/Component/Dice/Expressions/ResolvableNumber'

local format = string.format

---@class dice.Identifier : dice.ResolvableNumber
---@field type 'Identifier' The expression type.
---@field name string The identifier name.
---@field value Literal The identifier value.
local Identifier = Base:derive('Identifier')

---Returns the list of child expressions.
---@return Literal[]
function Identifier:getChildren()
    return { self.value }
end

---Returns the numerical value of the expression.
---@return number?
---@return DiceRollError?
function Identifier:getNumber()
    return self.value:getTotal()
end

---Returns the list representation of the object.
---@return Literal[]
function Identifier:getList()
    return { self.value }
end

---Converts the identifier into a plain table that can be sent over the network.
---@return table plain
function Identifier:toNetwork()
    local plain = Base.toNetwork(self)
    plain.name = self.name
    plain.value = self.value:toNetwork()

    return plain
end

---Returns the expression as a string.
---@protected
function Identifier:__tostring()
    return format(
        '<Identifier name=%s value=%s>',
        self.name,
        tostring(self.value)
    )
end


---Creates a new identifier.
---@param args Args.Identifier Arguments for creation of the identifier.
---@return Identifier
function Identifier:new(args)
    local this = core.new(self, Base.new)

    this.type = 'Identifier'
    this.name = args.name
    this.value = args.value

    return this
end

return Identifier

--#region Type Definitions

---@class Args.Identifier
---@field name string The identifier name.
---@field value Literal The value of the identifier.

--#endregion
