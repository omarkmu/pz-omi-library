---An error that can occur while parsing Fluent text.
---@namespace omi.l10n
---@using omi

local core = require 'OmiLibrary/Module/Utils'
local BaseError = require 'OmiLibrary/Component/Core/Error'

---@class FluentParseError : Error
local ParseError = BaseError:derive('ParseError')

---Error codes that can occur while parsing Fluent translations.
---@enum(key) FluentParseError.Code
---@type table<FluentParseError.Code, string>
ParseError.Messages = {
    E0001 = 'Generic error',
    E0002 = 'Expected an entry start',
    E0003 = 'Expected token',
    E0004 = 'Expected a character from range',
    E0005 = 'Expected message to have a value or attributes',
    E0006 = 'Expected term to have a value',
    E0007 = 'Keyword cannot end with a whitespace',
    E0008 = 'The callee has to be an upper-case identifier or a term',
    E0009 = 'The argument name has to be a simple identifier',
    E0010 = 'Expected one of the variants to be marked as default (*)',
    E0011 = 'Expected at least one variant after "->"',
    E0012 = 'Expected value',
    E0013 = 'Expected variant key',
    E0014 = 'Expected literal',
    E0015 = 'Only one variant can be marked as default (*)',
    E0016 = 'Message references cannot be used as selectors',
    E0017 = 'Terms cannot be used as selectors',
    E0018 = 'Attributes of messages cannot be used as selectors',
    E0019 = 'Attributes of terms cannot be used as placeables',
    E0020 = 'Unterminated string expression',
    E0021 = 'Positional arguments must not follow named arguments',
    E0022 = 'Named arguments must be unique',
    E0024 = 'Cannot access variants of a message',
    E0025 = 'Unknown escape sequence',
    E0026 = 'Invalid Unicode escape sequence',
    E0027 = 'Unbalanced closing brace in TextElement',
    E0028 = 'Expected an inline expression',
    E0029 = 'Expected simple expression as selector',
    E9999 = 'Unexpected EOF',
}

---Associates error codes to messages that should be formatted with provided arguments.
---@enum(key) FluentParseError.FormattedCode
---@type table<FluentParseError.FormattedCode, string>
ParseError.FormattedMessages = {
    E0003 = 'Expected token: "%s"',
    E0004 = 'Expected a character from range: "%s"',
    E0005 = 'Expected message "%s" to have a value or attributes',
    E0006 = 'Expected term "-%s" to have a value',
    E0025 = 'Unknown escape sequence: \\%s',
    E0026 = 'Invalid Unicode escape sequence: %s',
}


---Creates a new parse error.
---@param code FluentParseError.Code The error code.
---@param ...any Arguments for the error.
---@return FluentParseError
function ParseError:new(code, ...)
    return core.new(self, BaseError.new, code, ...)
end

return ParseError
