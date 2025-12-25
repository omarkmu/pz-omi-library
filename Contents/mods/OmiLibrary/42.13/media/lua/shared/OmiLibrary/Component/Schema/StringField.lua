---Schema field for strings.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local Field = require 'OmiLibrary/Component/Schema/Field'


---@class schema.StringField : schema.Field
local StringField = Field:derive('StringField')


---Reads a value from a table as a string field.
---@param options Args.ReadSchemaField
---@return string
function StringField:read(options)
    local value = options.value
    if value == nil then
        value = self:getDefault(options.schema) or ''
    end

    return tostring(value)
end


---Initializes a new string field.
---@param options Args.StringField
---@param type string?
---@return schema.StringField
function StringField:new(options, type)
    return core.new(self, Field.new, options, type or 'string')
end


return StringField

--#region Type Definitions

---@class Args.StringField : Args.SchemaField
---@field default? string The default value for the field.

--#endregion
