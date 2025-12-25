---Function for an individual log level on a logger.
---@namespace omi
---@diagnostic disable: access-invisible


local core = require 'OmiLibrary/Module/Utils'

local format = string.format

---@class LogFunction : Class
---@overload fun(message: string, ...: any)
---@field once fun(message: string, ...: any) Logs a message to the log level once, ignoring subsequent calls with the same message.
---@field private _logger Logger The logger owner.
---@field private _level LogLevel The log level of the function.
---@field private _seenOnceMessages SetTable<string> Cache of already logged `once` messages.
local LogFunction = core.class('LogFunction')

---Associates log levels to severity values.
---@type table<LogLevel, integer>
---@private
LogFunction._levelToSeverity = {
    silent = -1,
    fatal = 0,
    error = 1,
    warn = 2,
    info = 3,
    http = 4,
    verbose = 5,
    debug = 6,
}


---Logs a message to the log level one time.
---Ignores subsequent calls with the same message.
---@param message string The message to log.
---@param ...any Format arguments.
---@private
function LogFunction:_logOnce(message, ...)
    message = core.format(message, ...)
    if self._seenOnceMessages[message] then
        return
    end

    self._seenOnceMessages[message] = true
    self(message)
end

---Handler for calling the log function.
---@param message string
---@param ...any
---@private
function LogFunction:__call(message, ...)
    local logger = self._logger
    local level = self._level

    local severity = self._levelToSeverity[level]
    local logSeverity = self._levelToSeverity[logger.level]
    if not severity or severity > logSeverity then
        return
    end

    local name = logger.name or logger._id
    local displayLevel = severity == 4 and level:upper() or (level:sub(1, 1):upper() .. level:sub(2))

    message = format('[%s] [%s] %s', name, displayLevel, core.format(message, ...))
    if severity == 0 then
        error(message)
    elseif severity == 1 then
        pcall(function() error(message) end)
    else
        print(message)
    end
end


---Creates a new logger function.
---@param level LogLevel The function log level.
---@param owner Logger The logger owner.
---@return LogFunction
---@private
function LogFunction:new(level, owner)
    local this = core.new(self)

    this._level = level
    this._logger = owner

    this.once = core.bind(this._logOnce, this)
    this._seenOnceMessages = {}

    return this
end


return LogFunction
