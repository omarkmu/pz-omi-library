---Utilities for creating configuration schemas.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local json = require 'OmiLibrary/Module/JSON'

---@class(partial) Schema
local Schema = require 'OmiLibrary/Component/Schema/Schema'


---@class schema
---@overload fun(options: Args.Schema): Schema
local schema = {}


---Component for declaring expected type information about objects.
schema.Schema = Schema

---Base schema field.
schema.Field = require 'OmiLibrary/Component/Schema/Field'

---Schema field for arrays.
schema.ArrayField = require 'OmiLibrary/Component/Schema/ArrayField'

---Schema field for booleans.
schema.BooleanField = require 'OmiLibrary/Component/Schema/BooleanField'

---Schema field for colors.
schema.ColorField = require 'OmiLibrary/Component/Schema/ColorField'

---Schema field for compatibility options.
schema.CompatibilityField = require 'OmiLibrary/Component/Schema/CompatibilityField'

---Schema field for numbers.
schema.DoubleField = require 'OmiLibrary/Component/Schema/DoubleField'

---Schema field for integers.
schema.IntegerField = require 'OmiLibrary/Component/Schema/IntegerField'

---Schema field for objects.
schema.ObjectField = require 'OmiLibrary/Component/Schema/ObjectField'

---Schema field for sets.
schema.SetField = require 'OmiLibrary/Component/Schema/SetField'

---Schema field for string enumerations.
schema.StringEnumField = require 'OmiLibrary/Component/Schema/StringEnumField'

---Schema field for strings.
schema.StringField = require 'OmiLibrary/Component/Schema/StringField'


---Helper which creates an array configuration field.
---@param options Args.ArrayField
---@return schema.ArrayField
function schema.array(options)
    return schema.ArrayField:new(options)
end

---Helper which creates a boolean configuration field.
---@param defaultOrOptions (boolean | Args.BooleanField)? The default value for the field; defaults to `false`. Alternatively, a table of options.
---@return schema.BooleanField
function schema.bool(defaultOrOptions)
    if type(defaultOrOptions) ~= 'table' then
        defaultOrOptions = { default = not not defaultOrOptions }
    end

    return schema.BooleanField:new(defaultOrOptions)
end

---Helper which creates a color configuration field.
---@param options Args.ColorField? A table of creation options.
---@return schema.ColorField
function schema.color(options)
    return schema.ColorField:new(options or {})
end

---Helper which creates a compatibility configuration field.
---@param defaultOrOptions (schema.CompatibilityValue | Args.CompatibilityField)? The default value for the field; defaults to `'Auto'`. Alternatively, a table of options.
---@return schema.CompatibilityField
function schema.compatibility(defaultOrOptions)
    if type(defaultOrOptions) ~= 'table' then
        defaultOrOptions = { default = defaultOrOptions }
    end

    return schema.CompatibilityField:new(defaultOrOptions --[[@as Args.CompatibilityField]])
end

---Helper which creates an object configuration field.
---This is a shortcut for creating an object field that only has the `properties` key.
---@param fields table<string, schema.Field>
---@return schema.ObjectField
function schema.container(fields)
    return schema.ObjectField:new({ properties = fields })
end

---Helper which creates a number configuration field.
---@param defaultOrOptions number | Args.DoubleField The default value for the field. Alternatively, a table of options.
---@param min number? The minimum value for the field.
---@param max number? The maximum value for the field.
---@return schema.DoubleField
function schema.double(defaultOrOptions, min, max)
    if type(defaultOrOptions) == 'number' then
        defaultOrOptions = { default = defaultOrOptions }
    else
        defaultOrOptions = core.copy(defaultOrOptions)
    end

    defaultOrOptions.min = min or defaultOrOptions.min
    defaultOrOptions.max = max or defaultOrOptions.max
    return schema.DoubleField:new(defaultOrOptions)
end

---Helper which creates an integer configuration field.
---@param defaultOrOptions integer | Args.IntegerField The default value for the field. Alternatively, a table of options.
---@param min integer? The minimum value for the field.
---@param max integer? The maximum value for the field.
---@return schema.IntegerField
function schema.int(defaultOrOptions, min, max)
    if type(defaultOrOptions) ~= 'table' then
        ---@cast defaultOrOptions integer
        defaultOrOptions = { default = defaultOrOptions }
    else
        defaultOrOptions = core.copy(defaultOrOptions)
    end

    defaultOrOptions.min = min or defaultOrOptions.min
    defaultOrOptions.max = max or defaultOrOptions.max
    return schema.IntegerField:new(defaultOrOptions)
end

---Creates a new schema.
---@param args Args.Schema
---@return Schema
function schema.new(args)
    return Schema:new(args)
end

---Helper which creates an object configuration field.
---@param options Args.ObjectField
---@return schema.ObjectField
function schema.object(options)
    return schema.ObjectField:new(options)
end

---Helper which creates a set configuration field.
---@param options Args.SetField
---@return schema.SetField
function schema.set(options)
    return schema.SetField:new(options)
end

---Helper which creates a string configuration field.
---@param defaultOrOptions (string | Args.StringField)? The default value for the field. Alternatively, a table of options.
---@return schema.StringField
function schema.string(defaultOrOptions)
    if type(defaultOrOptions) ~= 'table' then
        ---@cast defaultOrOptions string?
        defaultOrOptions = { default = defaultOrOptions }
    end

    return schema.StringField:new(defaultOrOptions)
end

---Helper which creates a string enumeration configuration field.
---@param options Args.StringEnumField
---@return schema.StringEnumField
function schema.stringEnum(options)
    return schema.StringEnumField:new(options)
end

setmetatable(schema, { __call = function(self, ...) return self.new(...) end })
return schema

--#region Type Definitions

---@class Args.ReadSchema : Args.ReadSchema.Partial
---@field source table The source table to read.

---@class Args.ReadSchema.Partial
---@field dest? table The destination table for options.
---@field skipMissing? boolean If `true`, missing fields will not be included as defaults.

---@class Args.ReadSchemaField
---@field schema Schema The parent schema of the field.
---@field value? any The value of the field in the source table.
---@field skipMissing boolean If `true`, missing fields will not be included as defaults.

--#endregion
