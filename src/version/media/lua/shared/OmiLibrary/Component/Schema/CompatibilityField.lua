---Schema field for compatibility options.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local StringEnumField = require 'OmiLibrary/Component/Schema/StringEnumField'


---@class schema.CompatibilityField : schema.StringEnumField
local CompatibilityField = StringEnumField:derive('CompatibilityField')


---Initializes a new compatibility field.
---@param options Args.CompatibilityField
---@param type string?
---@return schema.CompatibilityField
function CompatibilityField:new(options, type)
    options = core.copy(options)
    options.default = options.default or 'Auto'

    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast options Args.StringEnumField
    options.values = {
        'Enable',
        'Disable',
        'Auto',
    }

    return core.new(self, StringEnumField.new, options, type or 'compatibility')
end


return CompatibilityField

--#region Type Definitions

---@class Args.CompatibilityField : Args.SchemaField
---@field default? schema.CompatibilityValue The default value for the field.


---@alias schema.CompatibilityValue
---| 'Enable'
---| 'Disable'
---| 'Auto'

--#endregion
