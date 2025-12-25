---Handles logging messages.
---@namespace omi
---@diagnostic disable: access-invisible

local core = require 'OmiLibrary/Module/Utils'
local LogFunction = require 'OmiLibrary/Component/Logging/LogFunction'

---@class Logger : Class
---@field level LogLevel The minimum log level to log.
---@field fatal LogFunction Throws an error.
---@field error LogFunction Logs an error message. This causes an error popup, but continues execution.
---@field warn LogFunction Logs a warning message.
---@field info LogFunction Logs an info message.
---@field http LogFunction Logs a message related to HTTP.
---@field verbose LogFunction Logs a verbose message.
---@field debug LogFunction Logs a debug message.
---@field name string? A name to use in logs instead of the ID.
---@field protected _id string The logger ID. Used in log messages unless `name` is present.
local Logger = core.class('Logger')


---Associates logger names to instances.
---@type table<string, Logger>
---@private
Logger._instances = {}


---Creates a logger with the given name.
---If the logger already exists, an error will occur.
---@param idOrOptions string | Args.Logger
---@return Logger logger
function Logger.create(idOrOptions)
    local options ---@type Args.Logger
    if type(idOrOptions) == 'string' then
        options = { id = idOrOptions }
    else
        options = idOrOptions
    end

    local id = options.id
    if Logger._instances[id] then
        error('Tried to overwrite logger with id ' .. id)
    end

    local logger = Logger:new(options)
    Logger._instances[id] = logger

    return logger
end

---Checks whether a logger with the given ID exists.
---@return boolean exists
function Logger.exists(id)
    return Logger._instances[id] ~= nil
end

---Gets the logger with the given ID, or nil if it doesn't exist.
---@param id string
---@return Logger? logger
function Logger.get(id)
    return Logger._instances[id]
end

---Gets the logger with the given ID, creating it if it doesn't exist.
---@param id string
---@return Logger logger
function Logger.getOrCreate(id)
    local logger = Logger._instances[id]
    if not logger then
        logger = Logger:new({ id = id })
        Logger._instances[id] = logger
    end

    return logger
end


---Creates a new logger.
---@param options Args.Logger
---@return Logger logger
---@protected
function Logger:new(options)
    local this = core.new(self)

    this._id = options.id
    this.name = options.name
    this.level = options.level or (getDebug() and 'debug' or 'info')

    this.fatal = LogFunction:new('fatal', this)
    this.error = LogFunction:new('error', this)
    this.warn = LogFunction:new('warn', this)
    this.info = LogFunction:new('info', this)
    this.http = LogFunction:new('http', this)
    this.verbose = LogFunction:new('verbose', this)
    this.debug = LogFunction:new('debug', this)

    return this
end

return Logger

--#region Type Definition

---@class Args.Logger
---@field id string The ID to use for the logger.
---@field name? string A name to use in log messages instead of the ID.
---@field level? LogLevel The minimum log level for the logger. Defaults to `debug` in debug mode and `info` otherwise.


---@alias LogLevel
---| 'silent'
---| 'fatal'
---| 'error'
---| 'warn'
---| 'info'
---| 'http'
---| 'verbose'
---| 'debug'

--#endregion
