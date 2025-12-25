---Configuration schema.
---Contains information about the fields in an object.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local Field = require 'OmiLibrary/Component/Schema/Field'


---@class(partial) Schema : Class
---@field protected callbacks Schema.Callbacks Container for callbacks.
---@field protected properties table<string, schema.Field> Mapping of keys to schema fields.
---@field protected transforms Schema.Callback.Transform[] List of transforms to apply to source data.
---@field protected fieldList schema.Field[] The list of schema fields in creation order.
---@field protected generator? forms.Generator The form generator for the schema.
---@field protected generatorArgs Args.FormGenerator Arguments to pass when creating a form generator.
local Schema = core.class('Schema')


---Returns an iterator over child fields sorted by creation time.
---@return fun(): schema.Field?
function Schema:fields()
    local i = 0
    return function()
        i = i + 1
        return self.fieldList[i]
    end
end

---Returns the default table of values.
---@return table
function Schema:getDefaults()
    return self:read({ source = {} })
end

---Returns the number of fields in the schema.
---@return integer
function Schema:getFieldCount()
    return #self.fieldList
end

---Returns a list of child fields sorted by creation time.
---@return schema.Field[]
function Schema:getFields()
    return core.copyList(self.fieldList)
end

---Gets or creates a form generator for the schema.
---This should only be called client-side.
---@return forms.Generator
function Schema:getFormGenerator()
    if isServer() then
        error('Forms can only be generated client-side.')
    end

    if not self.generator then
        local lib = (require 'OmiLibrary') --[[@as client]]
        self.generator = lib.ui.forms.generator(self.generatorArgs)
    end

    return self.generator
end

---Generates a form based on the schema.
---This should only be called client-side.
---@param args Args.FormGeneration?
---@return forms.Form
function Schema:generateForm(args)
    local generator = self:getFormGenerator()
    return generator:generate(args or {})
end

---Reads a table against the schema.
---@param options Args.ReadSchema
---@return table
function Schema:read(options)
    local source = options.source
    local dest = options.dest or {}
    local skipMissing = options.skipMissing

    if #self.transforms > 0 then
        source = core.copy(source)
    end

    for i = 1, #self.transforms do
        source = self.transforms[i](source, self)
    end

    for key, field in pairs(self.properties) do
        local value = source[key]
        if not skipMissing or value ~= nil then
            ---@type Args.ReadSchemaField
            local info = {
                schema = self,
                value = value,
                skipMissing = skipMissing or false,
            }

            dest[key] = field:read(info)
        end
    end

    self:_onRead(dest)
    return dest
end

---Reads a table against the schema from a .json file.
---The schema will be read with the default options.
---@param fileReadOptions Args.ReadSchemaFile | string
---@param schemaReadOptions Args.ReadSchema.Partial?
---@return table? result
---@return string? error
function Schema:readFile(fileReadOptions, schemaReadOptions)
    local decoded, err = Schema.__module.read(fileReadOptions)
    if not decoded then
        return nil, err
    end

    local options = core.copy(schemaReadOptions) --[[@as Args.ReadSchema]]
    options.source = decoded

    return self:read(options)
end

---Sanitizes values to prepare for writing.
---@param values table
---@return table
function Schema:sanitize(values)
    if self.callbacks.sanitize then
        self.callbacks.sanitize(values, self)
    end

    return values
end


---Called after reading the schema into a table.
---@param values table Table containing the raw values that were read.
---@protected
function Schema:_onRead(values)
    if self.callbacks.onRead then
        self.callbacks.onRead(values, self)
    end
end


---@param options Args.Schema
---@return Schema
function Schema:new(options)
    local this = core.new(self)

    this.properties = options.properties or {}
    this.transforms = options.transforms or {}
    this.callbacks = {
        onRead = options.onRead,
        sanitize = options.sanitize,
    }

    local list = {}
    for k, v in pairs(this.properties) do
        v:setKey(k)
        list[#list + 1] = v
    end

    table.sort(list, Field.compare)
    this.fieldList = list

    local args = core.copy(options.form or {}) --[[@as Args.FormGenerator]]
    args.schema = this
    this.generatorArgs = args

    return this
end


return Schema

--#region Type Definitions

---@class Args.Schema
---@field properties table<string, schema.Field> The schema properties.
---@field transforms? Schema.Callback.Transform[] List of transforms to apply to source data.
---@field form? Args.FormGenerator.Partial The form generator definition.
---@field onRead? Schema.Callback Invoked after reading a table against the schema.
---@field sanitize? Schema.Callback Invoked to sanitize values to prepare for writing.


---@class Schema.Callbacks
---@field onRead? Schema.Callback Invoked after reading a table against the schema.
---@field sanitize? Schema.Callback Invoked to sanitize values to prepare for writing.


---@alias Schema.Callback fun(values: table, schema: Schema)

---@alias Schema.Callback.Transform fun(values: table, schema: Schema): table

--#endregion
