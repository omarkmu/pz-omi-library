---Base schema field.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'


---@class schema.Field : Class
---@field protected callbacks schema.Field.Callbacks Container for callbacks.
---@field protected type string The type of the field.
---@field protected default? any The default value to use for the field.
---@field protected key string The field's key in its parent, or an auto-generated key.
---@field protected id number The ID of the field.
---@field protected fieldList schema.Field[] The list of child fields in creation order.
local Field = core.class('SchemaField')


local nextID = 0


---Comparator over field IDs.
---@param a schema.Field
---@param b schema.Field
---@return boolean
function Field.compare(a, b)
    return a.id < b.id
end


---Returns an iterator over child fields sorted by creation time.
---@return fun(): schema.Field?
function Field:fields()
    local i = 0
    return function()
        i = i + 1
        return self.fieldList[i]
    end
end

---Gets the default value for the field, if one exists.
---@param schema Schema
---@return any | nil
function Field:getDefault(schema)
    if not self.callbacks.default then
        return self.default
    end

    return core.callback.invoke(self.callbacks.default, schema)
end

---Returns enumeration values.
---@return any[]
function Field:getEnumValues()
    return {}
end

---Returns the number of child fields in this field.
---@return integer
function Field:getFieldCount()
    return #self.fieldList
end

---Returns a list of child fields sorted by creation time.
---@return schema.Field[]
function Field:getFields()
    return core.copyList(self.fieldList)
end

---Returns the field used for items, if applicable.
---@return schema.Field?
function Field:getItemsField() end

---Returns the key of the field.
---@return string
function Field:getKey()
    return self.key
end

---Returns the maximum numeric value of the field, if applicable.
---@return number?
function Field:getMaximum() end

---Returns the minimum numeric value of the field, if applicable.
---@return number?
function Field:getMinimum() end

---Gets the type name of the field.
---@return string
function Field:getType()
    return self.type
end

---Reads a value from a table as a field.
---@param options Args.ReadSchemaField
---@return any
---@diagnostic disable-next-line: unused
function Field:read(options)
    -- implemented by subclasses
    error('not implemented')
end

---Sets the key of the field.
---@param key string
function Field:setKey(key)
    self.key = key
end


---Creates a new schema field.
---@param options Args.SchemaField
---@param type string
---@return schema.Field
function Field:new(options, type)
    local this = core.new(self)

    this.id = nextID
    this.type = type
    this.key = type .. this.id
    this.default = options.default
    this.fieldList = {}

    this.callbacks = {}
    this.callbacks.default = core.callback(self, options.getDefault)

    nextID = nextID + 1
    return this
end


return Field

--#region Type Definitions

---@class Args.SchemaField
---@field default? any The default value for the field.
---@field getDefault? schema.Field.Callback.Default Invoked to get the default value for the field.


---@class schema.Field.Callbacks
---@field default? CallbackInfo Invoked to get the default value for the field.


---@alias schema.Field.Callback.Default fun(self: schema.Field, schema: Schema): any?)

--#endregion
