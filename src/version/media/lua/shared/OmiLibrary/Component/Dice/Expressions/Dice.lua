---Expression type representing a set of die.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'
local Die = require 'OmiLibrary/Component/Dice/Expressions/Die'
local DiceSet = require 'OmiLibrary/Component/Dice/Expressions/DiceSet'

local format = string.format

---@class dice.Dice : dice.DiceSet
---@field type 'Dice' The expression type.
---@field count integer The number of dice to roll.
---@field size integer | '%' The die value, or '%' for a percentile dice.
---@field operations Operation<DiceOperator>[] Operations on the dice.
---@field values Die[] The set values.
---@field protected  _roller DiceRoller The roller to use for rolling new dice.
local Dice = DiceSet:derive('Dice')


---Returns the list of child expressions.
---@return Expression[]
function Dice:getChildren()
    return {}
end

---Rolls the number of dice indicated by the dice roll count.
---@return DiceRollError?
function Dice:roll()
    for _ = 1, self.count do
        local die, err = Die.roll(self.size, self._roller)
        if not die then
            return err
        end

        self.values[#self.values + 1] = die
    end
end

---Adds a die to the dice values.
---@return DiceRollError?
function Dice:rollAnother()
    local die, err = Die.roll(self.size, self._roller)
    if not die then
        return err
    end

    self.values[#self.values + 1] = die
end

---Converts the dice into a plain table that can be sent over the network.
---@return table plain
function Dice:toNetwork()
    local plain = DiceSet.toNetwork(self)
    plain.count = self.count
    plain.size = self.size

    return plain
end


---Returns the expression as a string.
---@protected
function Dice:__tostring()
    return format(
        '<Dice count=%d size=%d values=%s operations=%s>',
        self.count,
        self.size,
        self._listToString(self.values),
        self._operationsToString(self.operations)
    )
end

---Creates a new dice expression.
---@param args Args.Dice Arguments for creation of the expression.
---@return Dice
function Dice:new(args)
    local this = core.new(self, DiceSet.new, {
        kept = args.kept,
        annotations = args.annotations,
        operations = args.operations --[[@as any]],
    })

    this.type = 'Dice'
    this._roller = args.roller
    this.size = args.size
    this.count = args.count or 1

    return this
end

return Dice

--#region Type Definitions

---@class Args.Dice : Args.DiceSet
---@field count? integer The number of dice to roll. Defaults to `1`.
---@field operations? Operation<DiceOperator>[] Operations on the dice.
---@field size integer | '%' The die value, or '%' for a percentile dice.
---@field roller DiceRoller The current dice roller.

--#endregion
