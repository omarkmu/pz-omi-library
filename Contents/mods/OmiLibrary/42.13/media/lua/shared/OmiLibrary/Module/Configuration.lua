---Module for creation of configuration based on a schema.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local ConfigurationHelper = require 'OmiLibrary/Component/Core/ConfigurationHelper'


---@class configuration
---@overload fun(options: Args.ConfigurationHelper): ConfigurationHelper
local configuration = {}

---Helper for managing configuration based on a schema.
configuration.ConfigurationHelper = ConfigurationHelper


---Creates a new configuration helper.
---@param options Args.ConfigurationHelper
---@return ConfigurationHelper
function configuration.new(options)
    return setmetatable({
        _values = {},
        _descriptor = options.descriptor,
        _filename = options.filename,
        _modDataKey = options.modDataKey,
        _schema = options.schema,
        _pretty = core.default(options.pretty, getDebug()),
        _log = options.logger,
        _callbacks = {
            init = options.init,
            onLoad = options.onLoad,
            onSaveFile = options.onSaveFile,
            onSaveModData = options.onSaveModData,
        },
    }, ConfigurationHelper)
end


setmetatable(configuration, { __call = function(self, ...) return self.new(...) end })
return configuration
