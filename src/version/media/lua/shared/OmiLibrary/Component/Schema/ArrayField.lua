---Schema field for arrays.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local Field = require 'OmiLibrary/Component/Schema/Field'


---@class schema.ArrayField : schema.Field
---@field protected items schema.Field The field type for array items.
---@field protected maxItems? integer The maximum number of elements in the array.
local ArrayField = Field:derive('ArrayField')


---Returns enumeration values for the array item type.
---@return any[]
function ArrayField:getEnumValues()
    return self.items:getEnumValues()
end

---Returns the field used for items.
---@return schema.Field
function ArrayField:getItemsField()
    return self.items
end

---Returns the maximum number of items in the array, or `nil` if there's no maximum.
---@return integer?
function ArrayField:getMaximumItems()
    return self.maxItems
end

---Reads a value from a table as an array field.
---@param options Args.ReadSchemaField
---@return any[]
function ArrayField:read(options)
    local value = options.value

    if type(value) ~= 'table' then
        return core.deepcopy(self:getDefault(options.schema) or {})
    end

    local dest = {}
    local field = self.items
    for i = 1, #value do
        local item = value[i]
        dest[#dest + 1] = field:read {
            schema = options.schema,
            value = item,
            skipMissing = options.skipMissing,
        }

        if #dest == self.maxItems then
            break
        end
    end

    return dest
end


---Initializes a new array field.
---@param options Args.ArrayField
---@param type string?
---@return schema.ArrayField
function ArrayField:new(options, type)
    local this = core.new(self, Field.new, options, type or 'array')

    this.items = options.items
    this.maxItems = options.maxItems

    return this
end


return ArrayField

--#region Type Definitions

---@class Args.ArrayField : Args.SchemaField
---@field items schema.Field The field type for array items.
---@field default? any[] The default value for the field.
---@field maxItems? integer The maximum number of elements in the array.

--#endregion
