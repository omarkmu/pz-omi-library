---Module for rolling dice from expressions.
---Based on the `d20` Python package.
---@namespace omi
---@using omi.dice

local DiceParser = require 'OmiLibrary/Component/Dice/DiceParser'
local DiceRoller = require 'OmiLibrary/Component/Dice/DiceRoller'
local RollResult = require 'OmiLibrary/Component/Dice/RollResult'
local RollError = require 'OmiLibrary/Component/Dice/DiceRollError'
local ParseError = require 'OmiLibrary/Component/Dice/DiceParseError'
local Die = require 'OmiLibrary/Component/Dice/Expressions/Die'
local Dice = require 'OmiLibrary/Component/Dice/Expressions/Dice'
local DiceSet = require 'OmiLibrary/Component/Dice/Expressions/DiceSet'
local UnaryOp = require 'OmiLibrary/Component/Dice/Expressions/UnaryOp'
local BinaryOp = require 'OmiLibrary/Component/Dice/Expressions/BinaryOp'
local Literal = require 'OmiLibrary/Component/Dice/Expressions/Literal'
local Parenthetical = require 'OmiLibrary/Component/Dice/Expressions/Parenthetical'
local Identifier = require 'OmiLibrary/Component/Dice/Expressions/Identifier'
local ResolvableNumber = require 'OmiLibrary/Component/Dice/Expressions/ResolvableNumber'
local RollExpression = require 'OmiLibrary/Component/Dice/Expressions/RollExpression'
local Stringifier = require 'OmiLibrary/Component/Dice/Stringifiers/BaseStringifier'
local SimpleStringifier = require 'OmiLibrary/Component/Dice/Stringifiers/SimpleStringifier'
local RichTextStringifier = require 'OmiLibrary/Component/Dice/Stringifiers/RichTextStringifier'

---@class dice
local dice = {}

---Shared dice roller instance.
---@private
dice._roller = DiceRoller:new()

dice.Parser = DiceParser
dice.Roller = DiceRoller
dice.RollResult = RollResult
dice.RollError = RollError
dice.ParseError = ParseError

dice.Die = Die
dice.Dice = Dice
dice.Set = DiceSet
dice.UnaryOp = UnaryOp
dice.BinaryOp = BinaryOp
dice.Literal = Literal
dice.Parenthetical = Parenthetical
dice.Identifier = Identifier
dice.ResolvableNumber = ResolvableNumber
dice.RollExpression = RollExpression

dice.Stringifier = Stringifier
dice.SimpleStringifier = SimpleStringifier
dice.RichTextStringifier = RichTextStringifier

---@enum AdvType
dice.AdvType = {
    ---Advantage.
    Advantage = 1,

    ---Disadvantage.
    Disadvantage = 2,
}

---@enum CritType
dice.CritType = {
    ---Critical success.
    Success = 1,

    ---Critical failure.
    Failure = -1,
}


---Parses a dice expression.
---Throws an error for an invalid expression.
---@param expr string The expression string.
---@return AST.Expression result The result of parsing.
function dice.parse(expr)
    return dice._roller:parse(expr)
end

---Evaluates a dice expression.
---@param expr string | AST.Expression The dice expression to roll.
---@param args Args.Roll? Additional options for the roll.
---@return RollResult result The result of the roll.
function dice.roll(expr, args)
    return dice._roller:roll(expr, args)
end

---Parses a dice expression, returning `nil` and an error on failure.
---@param expr string The expression string.
---@return AST.Expression? result The result of parsing, or `nil` if an error occurred.
---@return DiceParseError? error The error that occurred.
function dice.tryParse(expr)
    return dice._roller:tryParse(expr)
end

---Evaluates a dice expression, returning `nil` and an error on failure.
---@param expr string | AST.Expression The dice expression to roll.
---@param args Args.Roll? Additional options for the roll.
---@return RollResult? result The result of the roll, or `nil` if an error occurred.
---@return (DiceRollError | DiceParseError)? error The error that occurred.
function dice.tryRoll(expr, args)
    return dice._roller:tryRoll(expr, args)
end


return dice
