---An error that can occur while rolling dice.
---@namespace omi.dice
---@using omi

local core = require 'OmiLibrary/Module/Utils'
local BaseError = require 'OmiLibrary/Component/Core/Error'

---@class DiceRollError : Error
local RollError = BaseError:derive('DiceRollError')

---Associates error codes to messages.
---@enum(key) DiceRollError.Code
RollError.Messages = {
    TooManyRolls = 'Too many dice rolled',
    DivideByZero = 'Cannot divide by zero',
    ZeroSides = 'Cannot roll a 0-sided die',
    InvalidSelectorMaximum = 'Invalid selector for maximum',
    InvalidSelectorMinimum = 'Invalid selector for minimum',
}

---Associates error codes to messages that should be formatted with provided arguments.
RollError.FormattedMessages = {
    InvalidSelectorMaximum = '%s is not a valid selector for maximums',
    InvalidSelectorMinimum = '%s is not a valid selector for minimums',
}


---Creates a new parse error.
---@param code DiceRollError.Code The error code.
---@param ...any Arguments for the error.
---@return DiceRollError
function RollError:new(code, ...)
    return core.new(self, BaseError.new, code, ...)
end

return RollError
