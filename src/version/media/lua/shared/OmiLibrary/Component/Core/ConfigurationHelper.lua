---Helper for managing configuration based on a schema.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local rawget = rawget
local rawset = rawset
local wipe = table.wipe

local ModData = ModData


---@class ConfigurationHelper<TValues : table>
---@field protected _callbacks ConfigurationHelper.Callbacks Container for callbacks.
---@field protected _schema Schema The schema that the configuration is based on.
---@field protected _filename? string The filename of a JSON file to save and load configuration values from.
---@field protected _descriptor? string The string used in error messages to refer to the configuration.
---@field protected _initialized? boolean Whether the configuration has been initialized.
---@field protected _values TValues The values of the configuration.
---@field protected _pretty boolean Whether the configuration should pretty-print when saving to files.
---@field protected _modDataKey? string The key to save and load the configuration as global mod data to.
---@field protected _log? Logger Logger used to log read/write errors.
local Configuration = {}


---Returns a table of default configuration values.
---@return table
function Configuration:getDefaults()
    return self:getSchema():getDefaults()
end

---Gets the filename of the `.json` file that stores the configuration.
---@return string?
function Configuration:getFilename()
    return rawget(self, '_filename')
end

---Gets the key for the global mod data table that stores the configuration.
---@return string?
function Configuration:getModDataKey()
    return rawget(self, '_modDataKey')
end

---Returns the schema of the configuration.
---@return Schema
function Configuration:getSchema()
    return rawget(self, '_schema')
end

---Returns the current configuration as a simple table.
---@return TValues
function Configuration:getValues()
    return core.deepcopy(self:_getValues())
end

---Gets sanitized configuration values that are prepared for saving.
---@return TValues
function Configuration:getValuesForSave()
    return self:getSchema():sanitize(self:getValues())
end

---Initializes the configuration if it hasn't already been initialized.
function Configuration:init()
    if self:isInitialized() then
        return
    end

    rawset(self, '_initialized', true)
    self:_init()
end

---Returns whether the configuration has been initialized.
---@return boolean
function Configuration:isInitialized()
    return rawget(self, '_initialized') or false
end

---Reads configuration values from a table.
---@param source table
function Configuration:load(source)
    self:getSchema():read({
        source = source,
        dest = self:_getValues(),
    })

    self:_afterLoad()
end

---Clears the configuration and loads defaults into it.
function Configuration:loadDefaults()
    wipe(self:_getValues())
    self:load({})
end

---Attempts to read configuration values from a `.json` file.
---@param optionsOrFilename (Args.ReadJSON | string)? The filename to read from, or options for reading.
---Defaults to the configured filename.
---@return boolean success
function Configuration:loadFile(optionsOrFilename)
    local options
    if type(optionsOrFilename) == 'string' then
        options = { filename = optionsOrFilename } --[[@as Args.ReadJSON]]
    elseif optionsOrFilename then
        options = optionsOrFilename
    else
        local filename = self:getFilename()
        if not filename then
            self:_logReadError('no filename specified')
            return false
        end

        options = { filename = filename } --[[@as Args.ReadJSON]]
    end

    local result, err = self:getSchema():readFile(options, { dest = self:_getValues() })
    if err then
        self:_logReadError(err)
    end

    if not result then
        return false
    end

    self:_afterLoad()
    return true
end

---Attempts to read configuration values from global mod data.
---@return boolean success
function Configuration:loadModData()
    local key = self:getModDataKey()
    if not key then
        self:_logReadError('no mod data key specified')
        return false
    end

    local table = ModData.getOrCreate(key)
    local encoded = table.data or '{}'

    local success, decoded = core.json.tryDecode(encoded)
    if type(decoded) ~= 'table' then
        if success then
            self:_logReadError('invalid JSON in mod data key ' .. key)
            return false
        end

        ---@cast decoded string
        self:_logReadError(decoded)
        return false
    end

    self:load(decoded)
    return true
end

---Saves configuration values to a `.json` file.
---@param filename string? The filename to save to. Defaults to the configured filename.
---@return boolean success
function Configuration:saveFile(filename)
    filename = filename or self:getFilename()
    if not filename then
        self:_logWriteError('no filename specified')
        return false
    end

    local encoded, err = core.json.tryEncode(self:getValuesForSave(), { pretty = rawget(self, '_pretty') })
    if err then
        self:_logWriteError(err)
    end

    if not encoded then
        return false
    end

    if not core.writeFile(filename, encoded) then
        self:_logWriteError('failed to write file')
        return false
    end

    self:_afterSaveFile()
    return true
end

---Saves configuration values to global mod data.
---@return boolean success
function Configuration:saveModData()
    local key = self:getModDataKey()
    if not key then
        self:_logWriteError('no mod data key specified')
        return false
    end

    local encoded, err = core.json.tryEncode(self:getValuesForSave(), { pretty = rawget(self, '_pretty') })
    if err then
        self:_logWriteError(err)
    end

    if not encoded then
        return false
    end

    local data = ModData.getOrCreate(key)
    wipe(data)
    data.data = encoded

    self:_afterSaveModData()
    return true
end


---Called after successfully loading configuration values.
---@protected
function Configuration:_afterLoad()
    local cb = self:_getCallbacks()
    if cb.onLoad then
        cb.onLoad(self)
    end
end

---Called after successfully saving configuration values to a file.
---@protected
function Configuration:_afterSaveFile()
    local cb = self:_getCallbacks()
    if cb.onSaveFile then
        cb.onSaveFile(self)
    end
end

---Called after successfully saving configuration values to mod data.
---@protected
function Configuration:_afterSaveModData()
    local cb = self:_getCallbacks()
    if cb.onSaveModData then
        cb.onSaveModData(self)
    end
end

---Returns the callbacks table.
---@return ConfigurationHelper.Callbacks
---@protected
function Configuration:_getCallbacks()
    return rawget(self, '_callbacks')
end

---Returns the logger to use.
---@return Logger?
---@protected
function Configuration:_getLogger()
    return rawget(self, '_log')
end

---Returns the raw values table.
---@return table
---@protected
function Configuration:_getValues()
    return rawget(self, '_values')
end

---Loads initial values into the configuration table.
---@protected
function Configuration:_init()
    local cb = self:_getCallbacks()
    if cb.init then
        cb.init(self)
        return
    end

    if self:getFilename() and self:loadFile() then
        self:saveFile()
        return
    end

    self:loadDefaults()
end

---Logs an error.
---@param err string
---@param ...any
---@protected
function Configuration:_logError(err, ...)
    local log = self:_getLogger()
    if log then
        log.error(err, ...)
    end
end

---Logs an error that occurred while reading configuration.
---@param err string
---@protected
function Configuration:_logReadError(err)
    local descriptor = rawget(self, '_descriptor') or 'configuration'
    self:_logError('Failed to read %s: %s', descriptor, err)
end

---Logs an error that occurred while writing configuration.
---@param err string
---@protected
function Configuration:_logWriteError(err)
    local descriptor = rawget(self, '_descriptor') or 'configuration'
    self:_logError('Failed to write %s: %s', descriptor, err)
end

---Called when an unknown index is retrieved.
---@param self ConfigurationHelper
---@param k any
---@return any
---@protected
function Configuration.__index(self, k)
    local value = rawget(self, '_values')[k]
    if value ~= nil then
        return value
    end

    return Configuration[k]
end

---Called when an empty index is set.
---@param self ConfigurationHelper
---@param k any
---@param v any
---@protected
function Configuration.__newindex(self, k, v)
    -- set in values if it's already present
    local values = rawget(self, '_values')
    if values[k] ~= nil then
        values[k] = v
    end

    -- otherwise, set on the object directly
    rawset(self, k, v)
end


return Configuration

--#region Type Definitions

---@class Args.ConfigurationHelper
---@field schema Schema The schema that the configuration is based on.
---@field filename? string The filename of a JSON file to save and load configuration values from.
---@field logger? Logger Logger used to log read/write errors.
---@field init? ConfigurationHelper.Callback Invoked to initialize the configuration.
---@field onLoad? ConfigurationHelper.Callback Invoked when data is loaded into the configuration.
---@field onSaveFile? ConfigurationHelper.Callback Invoked when data is saved to a file.
---@field onSaveModData? ConfigurationHelper.Callback Invoked when data is saved to mod data.
---@field descriptor? string The string used in error messages to refer to the configuration. Defaults to `'configuration'`.
---@field pretty? boolean If `true`, configuration file output will use JSON pretty printing. Defaults to `true`.
---@field modDataKey? string The key to save and load the configuration as global mod data to.


---@class ConfigurationHelper.Callbacks
---@field init? ConfigurationHelper.Callback Invoked to initialize the configuration.
---@field logError? Callback.LogError Invoked to log a read/write error.
---@field onLoad? ConfigurationHelper.Callback Invoked when data is loaded into the configuration.
---@field onSaveFile? ConfigurationHelper.Callback Invoked when data is saved to a file.
---@field onSaveModData? ConfigurationHelper.Callback Invoked when data is saved to mod data.


---@alias ConfigurationHelper.Callback fun(self: ConfigurationHelper)

--#endregion
