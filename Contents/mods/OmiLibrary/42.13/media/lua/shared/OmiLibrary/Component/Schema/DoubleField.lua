---Schema field for numbers.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local Field = require 'OmiLibrary/Component/Schema/Field'


---@class schema.DoubleField : schema.Field
---@field protected min? number The minimum value of the field.
---@field protected max? number The maximum value of the field.
local DoubleField = Field:derive('DoubleField')


---Returns the maximum numeric value of the field.
---@return number?
function DoubleField:getMaximum()
    return self.max
end

---Returns the minimum numeric value of the field.
---@return number?
function DoubleField:getMinimum()
    return self.min
end

---Reads a value from a table as a number field.
---@param options Args.ReadSchemaField
---@return number
function DoubleField:read(options)
    local value = tonumber(options.value)
    if value == nil then
        value = tonumber(self:getDefault(options.schema)) or 0
    end

    local min = self.min
    local max = self.max
    if min and value < min then
        value = min
    elseif max and value > max then
        value = max
    end

    return value
end


---Initializes a new number field.
---@param options Args.DoubleField
---@param type string?
---@return schema.DoubleField
function DoubleField:new(options, type)
    local this = core.new(self, Field.new, options, type or 'double')

    this.min = options.min
    this.max = options.max

    return this
end


return DoubleField

--#region Type Definitions

---@class Args.DoubleField : Args.SchemaField
---@field default? number The default value for the field.
---@field min? number The minimum value of the option.
---@field max? number The maximum value of the option.

--#endregion
