---An error with a code and a message.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'

local select = select
local unpack = unpack


---@class Error : Class
---@field code string The error code.
---@field message string The error message.
---@field args any[] Arguments provided for the error.
local Error = core.class('Error')

---Associates error codes to messages.
---@type table<string, string>
Error.Messages = {}

---Associates error codes to messages that should be formatted with provided arguments.
---@type table<string, string?>
Error.FormattedMessages = {}


---Gets the error message to use for an error.
---@param code string The error code.
---@param args any[] Arguments for the error.
---@param nArgs integer? The number of arguments provided. Defaults to the length of `args`.
---@return string message
function Error:getErrorMessage(code, args, nArgs)
    local formatString = self.FormattedMessages[code]
    if formatString then
        return core.format(formatString, unpack(args, 1, nArgs or #args))
    end

    return self.Messages[code] or code
end

---Returns the error message.
---@protected
function Error:__tostring()
    return self.message
end


---Creates a new error object.
---@param code string The error code.
---@param ...any Arguments for the error.
---@return Error
function Error:new(code, ...)
    local this = core.new(self)

    this.code = code
    this.args = { ... }
    this.message = this:getErrorMessage(code, this.args, select('#', ...))

    return this
end

return Error
