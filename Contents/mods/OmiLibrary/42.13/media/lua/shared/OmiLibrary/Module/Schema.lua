---Utilities for creating configuration schemas.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local json = require 'OmiLibrary/Module/JSON'
local libLog = require 'OmiLibrary/Component/Logging/LibraryLogger'
local isempty = table.isempty

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

    return schema.BooleanField:new(defaultOrOptions --[[@as Args.BooleanField)]])
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

---Helper to create a schema from a JSON file.
---@param options Args.Schema.FromFile
---@return Schema
function schema.fromJsonFile(options)
    local raw, err = json.tryReadObject({
        modId = options.modId,
        filename = options.filename or 'configuration.json',
        reader = options.reader,
    })

    local log = options.log or libLog
    local suffix = log == libLog and (', mod: ' .. options.modId) or ''
    if not raw then
        log.fatal('Failed to create schema: %s%s', err or 'an error occurred', suffix)
        ---@cast raw -?
    end

    if options.preprocess then
        raw = options.preprocess(raw)
    end

    local version = raw.SCHEMA_VERSION ---@type integer
    if type(version) ~= 'number' then
        version = 1
    end

    ---@type table<string, schema.Field>
    local properties = { VERSION = schema.int(version) }

    local fields = raw.properties or {}
    local rules = {} ---@type table<string, forms.Rules>
    for i = 1, #fields do
        local prop = fields[i]
        if type(prop) ~= 'table' then
            prop = { type = 'missing' }
        end

        if prop.type ~= 'object' then
            -- only objects allowed for now, until forms support an automatic page for top-level fields
            log.error('Invalid top-level property type for %s (%s)%s', prop.name, prop.type, suffix)
        else
            properties[prop.name], rules[prop.name] = schema._generateField(prop, options, raw)
        end
    end

    local form = core.copy(options.form) --[[@as Args.FormGenerator.Partial]]
    form.rules = rules

    if not form.prefix then
        form.prefix = options.modId .. '.config'
    end

    return schema.new({
        properties = properties,
        form = form,
        onRead = options.onRead,
        sanitize = options.sanitize,
        transforms = options.transforms,
    })
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

    return schema.StringField:new(defaultOrOptions --[[@as Args.StringField)]])
end

---Helper which creates a string enumeration configuration field.
---@param options Args.StringEnumField
---@return schema.StringEnumField
function schema.stringEnum(options)
    return schema.StringEnumField:new(options)
end


---Generates a schema field from a definition table defined in a JSON file.
---@param def JSONSchemaProperty
---@param options Args.Schema.FromFile
---@param raw table
---@param parentKey string?
---@return schema.Field?, forms.Rules?
---@private
function schema._generateField(def, options, raw, parentKey)
    local log = options.log or libLog
    local suffix = log == libLog and (', mod: ' .. options.modId) or ''
    local properties = {} ---@type table<string, schema.Field>
    local childRules = {} ---@type table<string, forms.Rules>

    local rules = core.copy(def) --[[@as forms.Rules]]
    local rulesAsAny = rules --[[@as any]]
    rulesAsAny.name = nil
    rulesAsAny.type = nil
    rulesAsAny.default = nil
    rulesAsAny.defaultAll = nil
    rulesAsAny.maxItems = nil
    rulesAsAny.options = nil
    rulesAsAny.properties = nil

    local props = def.properties
    local key = (parentKey and (parentKey .. '.') or '') .. def.name
    if props then
        for i = 1, #props do
            local child = props[i]
            properties[child.name], childRules[child.name] = schema._generateField(child, options, raw, key)
        end
    end

    if not isempty(childRules) then
        rules.children = childRules
    end

    local field = options.convert and options.convert(def, rules, key, raw)

    local _type = field and '' or def.type
    if _type == 'object' then
        field = schema.container(properties)
    elseif _type == 'object-list' then
        field = schema.array({
            maxItems = def.maxItems,
            items = schema.object({
                skipMissing = true,
                properties = properties,
            }),
        })
    elseif _type == 'string' or _type == 'textbox' then
        field = schema.string(def.default)

        if _type == 'textbox' then
            rules.displayLines = 10
        end
    elseif _type == 'compatibility' then
        field = schema.compatibility(def.default)
    elseif _type == 'color' then
        local default
        local color = def.default
        if color then
            default = { r = color[1], g = color[2], b = color[3] }
        end

        field = schema.color({ default = default })
    elseif _type == 'checkbox' then
        field = schema.bool(def.default)
    elseif _type == 'page-checkbox' then
        field = schema.bool(def.default)
        rules.togglePageFields = true
    elseif _type == 'checkbox-group' then
        local default
        if def.default then
            default = def.default
        elseif def.defaultAll then
            default = def.options
        end

        field = schema.set({
            default = core.set.table(default),
            items = schema.stringEnum({ values = def.options }),
        })
    elseif _type == 'string-dropdown' then
        field = schema.stringEnum({
            default = def.default,
            values = def.options,
        })
    elseif _type == 'string-map' then
        field = schema.object({
            skipMissing = true,
            default = def.default,
            additionalProperties = schema.string(),
        })
    elseif _type == 'string-list' then
        field = schema.array({
            items = schema.string(),
            default = def.default,
            maxItems = def.maxItems,
        })
    elseif _type == 'integer' or _type == 'number' then
        local createField = _type == 'integer' and schema.int or schema.double

        local max = def.max
        local min = def.min
        local default = def.default

        if not max then
            max = 2147483647
            log.error('Missing max value for property %s%s', key, suffix)
        end

        if not min then
            min = 0
            log.error('Missing min value for property %s%s', key, suffix)
        end

        if not default then
            default = 0
            log.error('Missing default value for property %s%s', key, suffix)
        end

        field = createField(default, min, max)
    elseif not field then
        log.error('Unknown type %s for property %s%s', _type, key, suffix)
    end

    if isempty(rules) then
        return field
    end

    return field, rules
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

---@class Args.Schema.FromFile : Args.Schema.Partial
---@field modId string The ID of the mod to read from.
---@field filename? string The filename of the file to read. Defaults to `configuration.json`.
---@field reader? BufferedReader The reader to use. If present, `filename` will be ignored.
---@field log? Logger A logger to use for errors. Failures to open or decode the file will be treated as fatal.
---@field form? Args.FormGenerator.FromFile The form generator definition.
---@field onRead? Schema.Callback Invoked after reading a table against the schema.
---@field sanitize? Schema.Callback Invoked to sanitize values to prepare for writing.
---@field preprocess? fun(raw: table): table Preprocessor for the table loaded from the file.
---@field convert? fun(prop: JSONSchemaProperty, rules: forms.Rules, key: string, raw: table): schema.Field Conversion function for properties defined in JSON.
---`raw` is the entire table from JSON.

---@class JSONSchemaProperty : forms.Rules.FromFile
---@field name string The name of the property.
---@field type string The type of the property.
---@field default? any The default value of the field.
---@field max? any The maximum value of the field.
---@field min? any The minimum value of the field.
---@field options? any Options for a field that accepts options.
---@field maxItems? integer The maximum number of items for a field with items.
---@field defaultAll? boolean Whether to use all options as the default value, for a checkbox group.
---@field properties? JSONSchemaProperty[] Child properties.

--#endregion
