---Information about the result of a dice roll.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'
local Die = require 'OmiLibrary/Component/Dice/Expressions/Die'
local Dice = require 'OmiLibrary/Component/Dice/Expressions/Dice'
local DiceSet = require 'OmiLibrary/Component/Dice/Expressions/DiceSet'
local UnaryOp = require 'OmiLibrary/Component/Dice/Expressions/UnaryOp'
local BinaryOp = require 'OmiLibrary/Component/Dice/Expressions/BinaryOp'
local Literal = require 'OmiLibrary/Component/Dice/Expressions/Literal'
local Parenthetical = require 'OmiLibrary/Component/Dice/Expressions/Parenthetical'
local Identifier = require 'OmiLibrary/Component/Dice/Expressions/Identifier'
local RollExpression = require 'OmiLibrary/Component/Dice/Expressions/RollExpression'
local RichTextStringifier = require 'OmiLibrary/Component/Dice/Stringifiers/RichTextStringifier'

local floor = math.floor
local setmetatable = setmetatable


---@class RollResult : Class
---@field expression RollExpression The roll expression.
---@field stringifier? Stringifier The stringifier to use for the result.
---@field protected total? integer The computed total value.
local RollResult = core.class('RollResult')

---Associates expression type names to their types.
---@type table<ExpressionType, Expression>
---@protected
RollResult._typesByName = {
    Die = Die,
    Dice = Dice,
    DiceSet = DiceSet,
    Literal = Literal,
    UnaryOp = UnaryOp,
    BinaryOp = BinaryOp,
    Parenthetical = Parenthetical,
    Identifier = Identifier,
    RollExpression = RollExpression,
}

---Associates expression type names to fields to copy for restoring network tables.
---@type table<ExpressionType, string[]?>
---@protected
RollResult._copyFields = {
    Dice = { 'values' },
    DiceSet = { 'values' },
    UnaryOp = { 'value' },
    BinaryOp = { 'left', 'right' },
    Parenthetical = { 'value' },
    Identifier = { 'value' },
    RollExpression = { 'roll' },
}


---Converts a plain table sent over the network into a roll result.
---Assumes the contents of the table are a valid network roll result.
---@param plain table The table containing the roll result.
---@param roller DiceRoller The roller to pass for new rolls.
---@param stringifier? Stringifier The stringifier to attach to the result.
---@return RollResult
function RollResult.fromNetwork(plain, roller, stringifier)
    plain.stringifier = stringifier
    plain.expression = RollResult._netToExpression(plain.expression, roller)

    return setmetatable(plain, RollResult)
end

---Converts a plain table sent over the network into a dice expression.
---@param plain table The table containing the expression.
---@param roller DiceRoller The roller to pass for new rolls.
---@return Expression
---@protected
function RollResult._netToExpression(plain, roller)
    ---@type ExpressionType
    local exprType = plain.type
    local clsType = exprType and RollResult._typesByName[exprType]
    if not clsType then
        error('Invalid expression type: ' .. tostring(exprType))
    end

    local fields = RollResult._copyFields[exprType] or {}
    for i = 1, #fields do
        local field = fields[i]
        if field == 'values' then
            plain.values = core.mapList(RollResult._netToExpression, plain.values, roller)
        else
            plain[field] = RollResult._netToExpression(plain[field], roller)
        end
    end

    if exprType == 'Die' or exprType == 'Dice' then
        plain._roller = roller
    end

    return setmetatable(plain, clsType)
end


---Gets the critical roll type of the roll.
---
---If the leftmost node is `d20` or `Xd20kh1`, this returns `1`
---if the roll was 20 and `-1` if the roll was 1.
---Otherwise, returns `nil`.
---@return CritType?
function RollResult:getCrit()
    ---@type Expression
    local left = self.expression

    local children = left:getChildren()
    while #children > 0 do
        left = children[1] --[[@as Expression]]
        children = left:getChildren()
    end

    if not core.isinstance(left, Dice) then
        return -- not a dice expression
    end

    if left.size ~= 20 or #left:getKeptList() ~= 1 then
        return -- not d20 or Nd20kh1
    end

    local total = left:getTotal()
    if total == 1 then
        return -1
    elseif total == 20 then
        return 1
    end
end

---Gets the total of the roll as an integer.
---@return integer
function RollResult:getTotal()
    if self.total then
        return self.total
    end

    local total, err = self:tryGetTotal()
    if not total then
        assert(err ~= nil)
        error(err.message)
    end

    return total
end

---Gets the result as a string.
---@return string
function RollResult:getString()
    self.stringifier = self.stringifier or RichTextStringifier:new()
    return self.stringifier:stringify(self.expression)
end

---Converts the result into a plain table that can be sent over the network.
---@return table plain
function RollResult:toNetwork()
    return {
        total = self.total,
        expression = self.expression:toNetwork(),
    }
end

---Attempts to retrieve the total of the roll as an integer.
---Returns an error on failure.
---@return integer? total
---@return DiceRollError? error
function RollResult:tryGetTotal()
    if self.total then
        return self.total
    end

    local num, err = self.expression:getTotal()
    if not num then
        return nil, err
    end

    self.total = floor(num)
    return self.total
end


---Converts the result to a string.
---@protected
function RollResult:__tostring()
    return self:getString()
end


---Creates a new roll result.
---@param args Args.RollResult Arguments for creation of the roll result.
---@return RollResult
function RollResult:new(args)
    local this = core.new(self)

    this.expression = args.expression
    this.stringifier = args.stringifier

    return this
end


return RollResult

--#region Type Definitions

---@class Args.RollResult
---@field expression RollExpression The roll expression.
---@field stringifier? Stringifier The stringifier to use. Defaults to `RichTextStringifier`.

--#endregion
