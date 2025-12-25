---Schema field for string enumerations.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local Field = require 'OmiLibrary/Component/Schema/Field'


---@class schema.StringEnumField : schema.Field
---@field protected valueList string[] A list of allowed string values for the field.
---@field protected values SetTable<string> A set that contains the allowed string values for the field.
local StringEnumField = Field:derive('StringEnumField')


---Returns enumeration values.
---@return string[]
function StringEnumField:getEnumValues()
    return core.copyList(self.valueList)
end

---Reads a value from a table as an enumeration field.
---@param options Args.ReadSchemaField
---@return string
function StringEnumField:read(options)
    local value = options.value
    if value == nil or not self.values[value] then
        value = self:getDefault(options.schema) or ''
    end

    return tostring(value)
end


---Initializes a new enumeration field.
---@param options Args.StringEnumField
---@param type string?
---@return schema.StringEnumField
function StringEnumField:new(options, type)
    local this = core.new(self, Field.new, options, type or 'stringEnum')

    local values = options.values or {}

    local valueList = {}
    local valueSet = {}
    for _, v in pairs(values) do
        if not valueSet[v] then
            valueList[#valueList + 1] = v
        end

        valueSet[v] = true
    end

    this.values = valueSet
    this.valueList = valueList

    return this
end


return StringEnumField

--#region Type Definitions

---@class Args.StringEnumField : Args.SchemaField
---@field default? string The default value for the field.
---@field values? string[] The allowed string values for the field.

--#endregion
