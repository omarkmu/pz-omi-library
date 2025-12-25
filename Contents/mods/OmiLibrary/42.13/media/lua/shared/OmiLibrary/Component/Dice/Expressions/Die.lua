---Expression type representing a single die.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'
local Base = require 'OmiLibrary/Component/Dice/Expressions/ResolvableNumber'
local Literal = require 'OmiLibrary/Component/Dice/Expressions/Literal'
local RollError = require 'OmiLibrary/Component/Dice/DiceRollError'

local format = string.format

---@class dice.Die : dice.ResolvableNumber
---@field type 'Die' The expression type.
---@field values Literal[] The die result values.
---@field size integer | '%' The die value, or '%' for a percentile dice.
---@field protected  _roller DiceRoller The roller to use for rolling new dice.
local Die = Base:derive('Die')


---Creates a new Die and rolls it.
---@param size integer | '%' The die value, or '%' for a percentile dice.
---@param roller DiceRoller The current dice roller.
---@return Die?
---@return DiceRollError?
function Die.roll(size, roller)
    ---@type Die
    local die = Die:new({ size = size, roller = roller })

    local err = die:_addRoll()
    if err then
        return nil, err
    end

    return die
end


---Marks the last die value as exploded.
function Die:explode()
    local last = self.values[#self.values]
    if last then
        last:explode()
    end
end

---Forces an update to the die value.
---@param value integer The new value.
function Die:forceValue(value)
    local last = self.values[#self.values]
    if last then
        last:update(value)
    end
end

---Returns the list of child expressions.
---@return Literal[]
function Die:getChildren()
    return self.values
end

---Returns the numerical value of the expression.
---@return number?
---@return DiceRollError?
function Die:getNumber()
    local value = self.values[#self.values] --[[@as Literal]]
    return value:getTotal()
end

---Returns the list representation of the object.
---@return Literal[]
function Die:getList()
    return { self.values[#self.values] }
end

---Drops the last die value and adds a new roll.
---@return DiceRollError?
function Die:reroll()
    local last = self.values[#self.values]
    if last then
        last:drop()
    end

    return self:_addRoll()
end

---Converts the die into a plain table that can be sent over the network.
---@return table plain
function Die:toNetwork()
    local plain = Base.toNetwork(self)
    plain.size = self.size
    plain.values = core.mapList(Literal.toNetwork, self.values)

    return plain
end


---Rolls the die and adds the result to the list of values.
---@return DiceRollError?
---@protected
function Die:_addRoll()
    local isPercentile = self.size == '%'
    if not isPercentile and self.size < 1 then
        return RollError:new('ZeroSides')
    end

    local err = self._roller:countRoll()
    if err then
        return err
    end

    local n
    if isPercentile then
        n = core.randInt(0, 9) * 10
    else
        n = core.randInt(1, self.size)
    end

    self.values[#self.values + 1] = Literal:new({ value = n })
end


---Returns the expression as a string.
---@protected
function Die:__tostring()
    return format(
        '<Die size=%d values=%s>',
        self.size,
        self._listToString(self.values)
    )
end


---Creates a new die.
---@param args Args.Die Arguments for creation of the die.
---@return Die
---@protected
function Die:new(args)
    local this = core.new(self, Base.new)

    this.type = 'Die'
    this._roller = args.roller
    this.size = args.size
    this.values = args.values or {}

    return this
end

return Die

--#region Type Definitions

---@class Args.Die
---@field size integer | '%' The die value, or '%' for a percentile dice.
---@field values? Literal[] Result values for the die.
---@field roller DiceRoller The current dice roller.

--#endregion
