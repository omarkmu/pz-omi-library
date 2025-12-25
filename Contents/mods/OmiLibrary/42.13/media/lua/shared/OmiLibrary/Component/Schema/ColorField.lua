---Schema field for colors.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local color = require 'OmiLibrary/Module/Color'
local Field = require 'OmiLibrary/Component/Schema/Field'


---@class schema.ColorField : schema.Field
local ColorField = Field:derive('ColorField')


---Reads a value from a table as a color field.
---@param options Args.ReadSchemaField
---@return ColorTable
function ColorField:read(options)
    local value = options.value

    if value == nil then
        value = self:getDefault(options.schema)
    end

    if value and color.isValid(value) then
        return color.copy(value)
    end

    return { r = 255, g = 255, b = 255 }
end


---Initializes a new color field.
---@param options Args.ColorField
---@param type string?
---@return schema.ColorField
function ColorField:new(options, type)
    return core.new(self, Field.new, options, type or 'color')
end


return ColorField

--#region Type Definitions

---@class Args.ColorField : Args.SchemaField
---@field default? ColorTable<integer> The default value for the field.

--#endregion
