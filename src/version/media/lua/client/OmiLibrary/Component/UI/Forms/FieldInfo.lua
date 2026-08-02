---Information about a form field.
---@namespace omi

local core = require 'OmiLibrary'

local getTextOrNull = core.l10n.getTextOrNull


---@class forms.FieldInfo : Class
---@field field schema.Field The field that the form field is based on.
---@field key string The key of the field.
---@field name string The translated name of the field.
---@field type string The field's type.
---@field prefix string The translation prefix to use for the field.
---@field rules forms.Rules Rules associated with the field.
---@field isArrayObjectField boolean If `true`, the field is an object field that represents an array item.
---@field isMapField boolean If `true`, the field is an object field that maps arbitary keys and values.
---@field mapPropertyField? schema.Field The field to use for map field properties.
---@field path string[] The path used to access the field.
---@field control? ISUIElement The form control associated with the field.
---@field label? Label The form label associated with the field.
---@field actionButtons Button[] The action buttons associated with the field.
---@field infoButton? Button The info button associated with the field.
local FieldInfo = core.class('FormFieldInfo')


---Returns the prefix to use for field children.
---@return string
function FieldInfo:getChildPrefix()
    return (self.rules.childPrefix or self.prefix) .. '-'
end

---Returns rules for the field's children.
---@return table<string, forms.Rules>
function FieldInfo:getChildRules()
    return self.rules.children or {}
end


---Creates a new set of information about a field.
---@param args Args.FormFieldInfo
---@return forms.FieldInfo
function FieldInfo:new(args)
    local this = core.new(self)

    local parent = args.parent
    local key = args.key or args.field:getKey()
    local rules = args.rules or (parent and parent.rules.children and parent.rules.children[key]) or {}
    local prefix = rules.prefix or args.prefix

    this.rules = rules
    this.actionButtons = {}
    this.type = args.field:getType()
    this.key = key
    this.prefix = prefix
    this.field = args.field
    this.name = args.name or getTextOrNull(prefix) or key
    this.isArrayObjectField = not not args.isArrayObjectField
    this.isMapField = false
    this.path = args.path or (parent and core.appendElements(core.copy(parent.path), key)) or { key }

    if this.type == 'object' then
        ---@type schema.ObjectField
        local field = this.field
        local addl = field:getAdditionalPropertiesField()
        if type(addl) ~= 'boolean' then
            this.isMapField = field:hasNoProperties()
            this.mapPropertyField = addl
        end
    end

    return this
end


return FieldInfo

--#region Type Definitions

---@class Args.FormFieldInfo
---@field field schema.Field The field that the form field is based on.
---@field rules forms.Rules The rules associated with the field.
---@field key? string The key of the field. Defaults to the key of `field`.
---@field name? string The translated name of the field. Defaults to the `prefix` translation or the `key`.
---@field prefix string The translation prefix to use for the field.
---@field parent? forms.FieldInfo The parent of the field.
---@field path? string[] The path to the field. Inferred from the `parent` and `key` if not provided.
---@field isArrayObjectField? boolean If `true`, the field is an object field that represents an array item.

--#endregion
