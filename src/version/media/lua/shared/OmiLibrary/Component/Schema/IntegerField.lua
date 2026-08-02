---Schema field for integers.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local DoubleField = require 'OmiLibrary/Component/Schema/DoubleField'

local floor = math.floor


---@class schema.IntegerField : schema.DoubleField
local IntegerField = DoubleField:derive('IntegerField')


---Reads a value from a table as a integer field.
---@param options Args.ReadSchemaField
---@return integer
function IntegerField:read(options)
    return floor(DoubleField.read(self, options))
end


---Initializes a new integer field.
---@param options Args.IntegerField
---@param type string?
---@return schema.IntegerField
function IntegerField:new(options, type)
    return core.new(self, DoubleField.new, options, type or 'integer')
end


return IntegerField

--#region Type Definitions

---@class Args.IntegerField : Args.DoubleField
---@field default? integer The default value for the field.
---@field min? integer The minimum value of the option.
---@field max? integer The maximum value of the option.

--#endregion
