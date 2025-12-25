---An error that can occur while parsing a dice expression.
---@namespace omi.dice
---@using omi

local core = require 'OmiLibrary/Module/Utils'
local BaseError = require 'OmiLibrary/Component/Core/Error'

---@class DiceParseError : Error
local ParseError = BaseError:derive('DiceParseError')

---Error codes that can occur while parsing dice expressions.
---@enum(key) DiceParseError.Code
---@type table<DiceParseError.Code, string>
ParseError.Messages = {
    Empty = 'Missing input',
    UnexpectedCharacter = 'Unexpected character',
    MissingExpression = 'Expected expression',
    MissingDiceValue = 'Expected dice value',
    MissingSelectorValue = 'Expected selector value',
    MissingEndParenthesis = 'Expected end parenthesis',
}

---Error codes that should be formatted with provided arguments.
---@enum(key) DiceParseError.FormattedCode
---@type table<DiceParseError.FormattedCode, string>
ParseError.FormattedMessages = {
    UnexpectedCharacter = 'Unexpected character "%s"',
    MissingExpression = 'Expected expression after %s',
}


---Creates a new parse error.
---@param code DiceParseError.Code The error code.
---@param ...any Arguments for the error.
---@return DiceParseError
function ParseError:new(code, ...)
    return core.new(self, BaseError.new, code, ...)
end

return ParseError
