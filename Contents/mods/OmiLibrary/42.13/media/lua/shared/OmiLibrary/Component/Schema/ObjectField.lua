---Schema field for objects.
---@namespace omi

local set = require 'OmiLibrary/Module/Set'
local core = require 'OmiLibrary/Module/Utils'
local Field = require 'OmiLibrary/Component/Schema/Field'

local isempty = table.isempty

---@class schema.ObjectField : schema.Field
---@field protected properties table<string, schema.Field> Mapping of keys to object properties.
---@field protected forceSkipMissing boolean If `true`, the object will always skip missing fields.
---@field protected required SetTable<string> Keys that will be required regardless of the value of `skipMissing`.
---@field protected additionalProperties? (boolean | schema.Field) If `true`, arbitrary additional properties will be read. If a field is specified, it will be used to read additional properties.
---@field protected fieldList schema.Field[] The list of object properties in creation order.
local ObjectField = Field:derive('ObjectField')

---Gets the field to use for additional properties,
---`true` if any additional properties are allowed,
---or `false` if additional properties are not allowed.
---@return schema.Field | boolean
function ObjectField:getAdditionalPropertiesField()
    return self.additionalProperties or false
end

---Checks whether the object field has no defined properties.
---@return boolean
function ObjectField:hasNoProperties()
    return isempty(self.properties)
end

---Reads a value from a table as an object field.
---@param options Args.ReadSchemaField
---@return table
function ObjectField:read(options)
    local value = options.value
    if type(value) ~= 'table' then
        value = core.deepcopy(self:getDefault(options.schema) or {})
    end

    local skipMissing = options.skipMissing or self.forceSkipMissing

    local dest = {}
    local knownProps = {}
    for key, field in pairs(self.properties) do
        knownProps[key] = true
        local fieldValue = value[key]
        if self.required[key] or not skipMissing or fieldValue ~= nil then
            dest[key] = field:read {
                schema = options.schema,
                value = fieldValue,
                skipMissing = options.skipMissing,
            }
        end
    end

    local extra = self.additionalProperties
    local addlField
    if type(extra) ~= 'boolean' and core.isinstance(extra, Field) then
        addlField = extra
    end

    if not extra then
        return dest
    end

    for key, fieldValue in pairs(value) do
        if not knownProps[key] then
            if not addlField then
                dest[key] = fieldValue
            elseif not skipMissing or fieldValue ~= nil then
                dest[key] = addlField:read {
                    schema = options.schema,
                    value = fieldValue,
                    skipMissing = options.skipMissing,
                }
            end
        end
    end

    return dest
end


---Initializes a new object field.
---@param options Args.ObjectField
---@param type string?
---@return schema.ObjectField
function ObjectField:new(options, type)
    local this = core.new(self, Field.new, options, type or 'object')

    this.properties = options.properties or {}
    this.forceSkipMissing = options.skipMissing or false
    this.additionalProperties = options.additionalProperties
    this.required = set.table(options.required)

    for k, v in pairs(this.properties) do
        v:setKey(k)
        this.fieldList[#this.fieldList + 1] = v
    end

    table.sort(this.fieldList, Field.compare)

    return this
end


return ObjectField

--#region Type Definitions

---@class Args.ObjectField : Args.SchemaField
---@field default? table The default value for the field.
---@field properties? table<string, schema.Field> Mapping of keys to object properties.
---@field skipMissing? boolean If `true`, the object will always skip missing fields. This applies only to the object and not child objects.
---@field required? string[] Keys that will be required regardless of the value of `skipMissing`.
---@field additionalProperties? (boolean | schema.Field) If `true`, arbitrary additional properties will be read. If a field is specified, it will be used to read additional properties.

--#endregion
