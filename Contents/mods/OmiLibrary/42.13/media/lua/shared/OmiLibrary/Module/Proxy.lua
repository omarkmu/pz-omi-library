---Handles creation of proxy utility tables.
---@namespace omi

local core = require 'OmiLibrary/Module/Core'
local Logger = require 'OmiLibrary/Component/Logging/Logger'


---Creates a proxy table for library utilities.
---@param options string | Args.Proxy
---@return proxy
return function(options)
    if type(options) == 'string' then
        options = { id = options } --[[@as Args.Proxy]]
    end

    -- this is called 'proxy' because originally it used setmetatable
    ---@type proxy
    local proxy = ({} --[[@as proxy]])
    for k, v in pairs(core) do
        proxy[k] = v
    end

    ---@diagnostic disable-next-line: undefined-field
    if options._core then
        return proxy
    end

    proxy.lib = require 'OmiLibrary'

    if options.logger then
        proxy.log = options.logger
    else
        local logger = Logger.getOrCreate(options.id)
        if options.name then
            logger.name = options.name
        end

        proxy.log = logger
    end

    return proxy
end

--#region Type Definitions

---@class proxy : core
---@field log Logger Logger instance.
---@field lib omi.shared Reference to the library.

---@class Args.Proxy
---@field id string The mod ID.
---@field name? string The name of the mod, as it should appear in logs. Defaults to `id` if not given.
---@field logger? Logger A logger to use instead of the default logger.

--#endregion
