---Schema field for sets.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local Field = require 'OmiLibrary/Component/Schema/Field'


---@class schema.SetField : schema.Field
---@field protected items schema.Field The field type for set items.
local SetField = Field:derive('SetField')


---Returns enumeration values for the set item type.
---@return any[]
function SetField:getEnumValues()
    return self.items:getEnumValues()
end

---Returns the field used for items.
---@return schema.Field?
function SetField:getItemsField()
    return self.items
end

---Reads a value from a table as a set field.
---@param options Args.ReadSchemaField
---@return SetTable
function SetField:read(options)
    local value = options.value

    if type(value) ~= 'table' then
        return core.deepcopy(self:getDefault(options.schema) or {})
    end

    local dest = {}
    local field = self.items
    for item in pairs(value) do
        if not options.skipMissing or item ~= nil then
            local element = field:read {
                value = item,
                schema = options.schema,
                skipMissing = options.skipMissing,
            }

            if element ~= nil then
                dest[element] = true
            end
        end
    end

    return dest
end


---Initializes a new set field.
---@param options Args.SetField
---@param type string?
---@return schema.SetField
function SetField:new(options, type)
    local this = core.new(self, Field.new, options, type or 'set')

    this.items = options.items

    return this
end


return SetField

--#region Type Definitions

---@class Args.SetField : Args.SchemaField
---@field default? SetTable<any> The default value for the field.
---@field items schema.Field The field type for array items.

--#endregion
