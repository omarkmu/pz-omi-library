---Schema field for booleans.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local Field = require 'OmiLibrary/Component/Schema/Field'


---@class schema.BooleanField : schema.Field
local BooleanField = Field:derive('BooleanField')


---Reads a value from a table as a boolean field.
---@param options Args.ReadSchemaField
---@return boolean
function BooleanField:read(options)
    local value = options.value
    if value == nil then
        value = self:getDefault(options.schema)
    end

    return not not value
end


---Initializes a new boolean field.
---@param options Args.BooleanField
---@param type string?
---@return schema.BooleanField
function BooleanField:new(options, type)
    return core.new(self, Field.new, options, type or 'boolean')
end


return BooleanField

--#region Type Definitions

---@class Args.BooleanField : Args.SchemaField
---@field default? boolean The default value for the field.

--#endregion
