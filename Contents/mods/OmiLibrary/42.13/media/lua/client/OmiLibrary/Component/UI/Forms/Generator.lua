---Component that generates a form based on a schema.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/UI/Core'
local Form = require 'OmiLibrary/Component/UI/Forms/Form'
local Page = require 'OmiLibrary/Component/UI/Forms/PageInfo'
local FieldInfo = require 'OmiLibrary/Component/UI/Forms/FieldInfo'

local getAttr = core.l10n.getAttr
local getAttrOrNull = core.l10n.getAttrOrNull
local getTextOrNull = core.l10n.getTextOrNull

---@class forms.Generator : Class
---@field protected prefix string The prefix to use for translation string IDs.
---@field protected versionKey? string A top-level field key that stores the version field, to ignore in the form.
---@field protected title? string The text to use for the form title.
---@field protected schema Schema The schema to use for the generated form.
---@field protected rules table<string, forms.Rules> A mapping of schema property keys to associated rules.
---@field protected nextY number The next Y position to use for a form element.
---@field protected nextYStack number[] A stack containing Y positions to use for form elements.
---@field protected form? forms.Form The form that is currently being generated.
---@field protected closeOnSave? boolean Whether the generated form should immediately close after saving.
---@field protected destroyOnClose? boolean Whether the generated form should be destroyed when closing.
local Generator = core.class('FormGenerator')


---Generates a form based on the schema.
---@param args Args.FormGeneration
---@return forms.Form
function Generator:generate(args)
    local cls = args.formClass or Form
    args = core.copy(args)
    args.title = args.title or self.title
    args.prefix = args.prefix or self.prefix
    args.closeOnSave = core.default(args.closeOnSave, self.closeOnSave)
    args.destroyOnClose = core.default(args.destroyOnClose, self.destroyOnClose)

    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast args Args.Form
    args.schema = self.schema

    local form = cls:new(args)
    form:initialise()
    form:addToUIManager()

    self:_generateContent(form)
    return form
end

---Returns the rules for a given field.
---@param key string The key of the field.
---@return forms.Rules?
function Generator:getRules(key)
    return self.rules[key]
end

---Gets the schema used to generate the form.
---@return Schema
function Generator:getSchema()
    return self.schema
end


---Generates content for a form.
---@param form forms.Form
---@protected
function Generator:_generateContent(form)
    self.form = form
    self.nextY = 0
    self.nextYStack = {}

    local prefix = form:getPrefix() .. '-'
    for field in form:getSchema():fields() do
        local key = field:getKey()
        local rules = self.rules[key] or {}

        if not rules.hidden and key ~= self.versionKey then
            local info = FieldInfo:new {
                field = field,
                rules = rules,
                prefix = prefix .. key,
            }

            self:_generateContentPage(info)
        end
    end

    form:init()
    form:refresh() -- trigger onChange for all fields
    self.form = nil

    local first = form.listbox.items[1] or {}
    if first.item then
        form:switchPage(first.item)
    end
end

---Generates a page for a form.
---@param info forms.FieldInfo
---@return forms.PageInfo?
---@protected
function Generator:_generateContentPage(info)
    local form = self.form
    if info.type ~= 'object' or not form then
        return
    end

    self.nextY = form.marginTop
    self.nextYStack = {}

    local page = Page:new {
        form = form,
        info = info,
    }

    if not info.rules.noLabel and not info.rules.hideControl then
        page.label = form:createPageHeading {
            page = page,
            parent = page.panel,
            y = self.nextY,
        }

        self:_increaseNextY(page.label.height)
    end

    if self:_generateSubfields(info, page.panel) then
        form:addPage(page)
        page.panel:setScrollHeight(self.nextY + form.marginBottom)
    end

    local rec = form:getFieldRecord(info.path)
    if not rec then
        return
    end
end

---Generates content for a field.
---@param info forms.FieldInfo
---@param panel Panel
---@return boolean success
---@protected
function Generator:_generateField(info, panel)
    local form = self.form
    if not form or info.rules.hidden then
        return false
    end

    local oldNextY = self.nextY
    local label = self:_generateFieldLabel(info, panel)

    local control
    local skipAddField
    local doRevert = false
    if info.type == 'object' and not info.isMapField then
        self:_increaseNextY()
        doRevert = not self:_generateSubfields(info, panel)
    else
        control, skipAddField = self:_generateFieldControl(info, panel)
        doRevert = not control -- non-objects should produce a control
    end

    if doRevert then
        self.nextY = oldNextY
        if label then
            panel:removeChild(label)
        end

        return false
    end

    if control then
        if info.rules.hideControl then
            control:setVisible(false)
        else
            self.nextY = control.y + control:getHeight()
        end

        if not skipAddField then
            form:addField(info)
        end
    end

    if info.rules.onActionClick then
        for i = 1, info.rules.actionCount or 1 do
            local tooltip = info.rules.actionTooltip or
                (info.rules.actionTooltipId and getTextOrNull(info.rules.actionTooltipId)) or
                getAttrOrNull(info.prefix, 'action-tooltip' .. i) or
                getAttrOrNull(info.prefix, 'action-tooltip')

            local text = info.rules.action or
                getAttrOrNull(info.prefix, 'action' .. i) or
                getAttrOrNull(info.prefix, 'action') or
                getAttrOrNull(form:getPrefix(), 'action-default') or
                getAttr('OmiLibrary.form-default', 'action-default')

            info.actionButtons[i] = form:createActionButton {
                index = i,
                parent = panel,
                info = info,
                control = control,
                label = label,
                text = text,
                tooltip = tooltip,
                callback = info.rules.onActionClick,
            }
        end
    end

    local infoTooltip = info.rules.infoTooltip or
        (info.rules.infoTooltipId and getTextOrNull(info.rules.infoTooltipId)) or
        getAttrOrNull(info.prefix, 'info-tooltip')

    if info.rules.onInfoClick or infoTooltip then
        info.infoButton = form:createInfoButton {
            parent = panel,
            info = info,
            control = control,
            label = label,
            tooltip = infoTooltip,
            callback = info.rules.onInfoClick,
        }
    end

    info.control = control
    info.label = label

    self:_increaseNextY(info.rules.padBottom)

    return true
end

---Generates a control for a field.
---@param info forms.FieldInfo
---@param panel Panel
---@return BaseUI?
---@return boolean? skipAddField
---@protected
function Generator:_generateFieldControl(info, panel)
    local form = self.form
    if not form then
        return
    end

    local value
    if not info.isArrayObjectField then -- array fields are populated later
        value = form:getValue(info.path)
    end

    local rules = info.rules
    local field = info.field
    local tooltip = rules.tooltip or getAttrOrNull(info.prefix, 'tooltip')

    local treatAsEnum = info.type == 'string' and rules.getEnumOptions ~= nil
    if info.type == 'boolean' then
        return form:createCheckbox {
            parent = panel,
            info = info,
            value = value,
            tooltip = tooltip,
            y = self.nextY + (rules.padTop or 0),
        }
    elseif info.type == 'color' then
        return form:createColorEntry {
            parent = panel,
            info = info,
            value = value,
            tooltip = tooltip,
            y = self.nextY,
            emptyColor = field:getDefault(form:getSchema()),
        }
    elseif not treatAsEnum and info.type == 'string' then
        local displayLines = rules.displayLines or 1

        local entry = form:createTextEntry {
            parent = panel,
            info = info,
            value = value,
            tooltip = tooltip,
            y = self.nextY,
            maxLines = rules.maxLines,
            displayLines = displayLines,
            noFullWidth = rules.noFullWidth or rules.onActionClick ~= nil,
        }

        if displayLines > 1 then
            panel:registerScrollingChild(entry)
        end

        return entry
    elseif info.isMapField and info.type == 'object' then
        ---@cast field schema.ObjectField
        local addlField = info.mapPropertyField
        local addlType = addlField and addlField:getType()

        if addlType == 'string' then
            local entry = form:createMapEntry {
                parent = panel,
                info = info,
                value = value,
                tooltip = tooltip,
                y = self.nextY,
                displayLines = rules.displayLines,
                noFullWidth = rules.noFullWidth or rules.onActionClick ~= nil,
                includeReorderButtons = not rules.noReorderButtons,
                keyPlaceholder = rules.keyPlaceholder or getAttrOrNull(info.prefix, 'placeholder-key'),
                valuePlaceholder = rules.valuePlaceholder or getAttrOrNull(info.prefix, 'placeholder-value'),
            }

            panel:registerScrollingChild(entry.listbox)
            return entry
        else
            -- only support string maps (for now)
            return
        end
    elseif info.type == 'array' then
        ---@cast field schema.ArrayField
        local itemsField = field:getItemsField()
        local itemsType = itemsField:getType()

        if itemsType == 'string' or itemsType == 'stringEnum' then
            local entry = form:createListEntry {
                parent = panel,
                info = info,
                value = value,
                tooltip = tooltip,
                y = self.nextY,
                displayLines = rules.displayLines,
                noFullWidth = rules.noFullWidth or rules.onActionClick ~= nil,
                includeReorderButtons = not rules.noReorderButtons,
            }

            panel:registerScrollingChild(entry.listbox)
            return entry
        elseif itemsType ~= 'object' then
            -- only support string arrays & object arrays
            return
        end

        local control = form:createObjectArrayPanel {
            parent = panel,
            info = info,
            value = value,
            tooltip = tooltip,
            y = self.nextY,
            maxItems = field:getMaximumItems(),
        }

        local objectInfo = self:_generateObjectArray(control, info, itemsField)
        if not objectInfo then
            control:destroy()
            return
        end

        panel:registerScrollingChild(control.listbox)
        panel:registerScrollingChild(control.contentPanel, true)

        objectInfo.control = control
        form:updateObjectArrayValues({ path = objectInfo.path, values = value })
        return control, true
    elseif info.type == 'double' or info.type == 'integer' then
        return form:createNumberEntry {
            parent = panel,
            info = info,
            value = value,
            tooltip = tooltip,
            y = self.nextY,
            isInteger = info.type == 'integer',
            min = field:getMinimum(),
            max = field:getMaximum(),
        }
    elseif treatAsEnum or info.type == 'stringEnum' or info.type == 'compatibility' then
        local options, selected = self:_getEnumOptions(info, value)
        if #options == 0 then
            return
        end

        return form:createDropdown {
            parent = panel,
            info = info,
            value = value,
            tooltip = tooltip,
            y = self.nextY,
            options = options,
            selected = selected,
        }
    elseif info.type == 'set' then
        local items = self:_getCheckboxOptions(info, value)
        if #items == 0 then
            return
        end

        return form:createCheckboxGroup {
            parent = panel,
            info = info,
            value = value,
            tooltip = tooltip,
            y = self.nextY,
            items = items,
        }
    end
end

---Generates a label for a field.
---@param info forms.FieldInfo
---@param panel Panel
---@return Label?
---@protected
function Generator:_generateFieldLabel(info, panel)
    local form = self.form
    if not form then
        return
    end

    -- booleans are just a single checkbox; they don't need a label
    if info.type == 'boolean' or info.rules.noLabel then
        return
    end

    local isHeading = info.type == 'object' and not info.isMapField

    local padTop = info.rules.padTop or (isHeading and form.headingPadY or 0)
    local label = UI.label {
        parent = panel,
        text = info.name,
        x = form.marginLeft,
        y = self.nextY + padTop,
        h = form.controlHeight,
        textColor = form.labelColor,
        font = isHeading and form.headingFont or form.textFont,
        tooltip = info.rules.tooltip or getAttrOrNull(info.prefix, 'tooltip'),
    }

    self.nextY = label.y + label:getHeight()

    return label
end

---Generates fields for an object array control.
---@param control forms.ObjectArrayPanel
---@param info forms.FieldInfo
---@param itemsField schema.Field
---@return forms.FieldInfo? objectField
---@protected
function Generator:_generateObjectArray(control, info, itemsField)
    local form = self.form
    if not form then
        return
    end

    local objectInfo = FieldInfo:new {
        name = info.name,
        field = itemsField,
        key = info.key,
        type = 'object',
        rules = info.rules,
        prefix = info.rules.childPrefix or info.prefix,
        path = info.path,
        isArrayObjectField = true,
    }

    self:_pushNextY()

    local success = self:_generateSubfields(objectInfo, control.contentPanel)
    control.contentPanel:setScrollHeight(self.nextY + form.marginBottom)

    self:_popNextY()

    if not success then
        return
    end

    form:addField(objectInfo)
    return objectInfo
end

---Generates content for child fields of a page or object array.
---@param parent forms.FieldInfo
---@param panel Panel
---@return boolean success Returns `true` if any chld field was successfully generated.
---@protected
function Generator:_generateSubfields(parent, panel)
    local form = self.form
    if not form then
        return false
    end

    local childRules = parent:getChildRules()
    local prefix = parent:getChildPrefix()

    local anySuccess = false
    for field in parent.field:fields() do
        local key = field:getKey()
        local fieldInfo = FieldInfo:new {
            field = field,
            prefix = prefix .. key,
            rules = childRules[key] or {},
            parent = parent,
        }

        -- no array-ception — array objects can only contain basic field types
        local canAdd =
            not parent.isArrayObjectField
            or (fieldInfo.isMapField or not self:_isObjectOrObjectArray(fieldInfo))

        if canAdd then
            anySuccess = self:_generateField(fieldInfo, panel) or anySuccess
        end
    end

    return anySuccess
end

---Returns checkbox group items as a list of options.
---@param info forms.FieldInfo
---@param value SetTable<any>?
---@return Checkbox.ItemOrString[]
---@protected
function Generator:_getCheckboxOptions(info, value)
    local form = self.form
    if not form then
        return {}
    end

    local field = info.field
    local rules = info.rules
    local itemsField = field:getItemsField()
    local itemsType = itemsField and itemsField:getType()
    if itemsType ~= 'string' and itemsType ~= 'stringEnum' then
        return {}
    end

    local items ---@type Checkbox.ItemOrString[] | Dropdown.Option[]
    if rules.getCheckboxOptions then
        items = rules.getCheckboxOptions {
            form = form,
            values = form.values,
            schema = form:getSchema(),
            state = form:getState(),
        }
    elseif itemsType == 'stringEnum' then
        items = self:_getEnumOptions(info)
    end

    if not items or #items == 0 then
        return {}
    end

    local options = {}
    local prefix = info.prefix
    for i = 1, #items do
        local item = items[i]
        local option ---@type Checkbox.ItemOrString
        if type(item) == 'string' then
            option = {
                data = item,
                text = getAttrOrNull(prefix, 'option-' .. item) or item,
                tooltip = getAttrOrNull(prefix, 'option-tooltip-' .. item),
            }
        else
            option = {
                data = item.data,
                text = item.text,
                tooltip = item.tooltip,
            }
        end

        option.checked = value and value[option.data]
        options[i] = option
    end

    return options
end

---Returns enumeration values as a list of dropdown options.
---@param info forms.FieldInfo
---@param selectedValue any?
---@return Dropdown.Option[]
---@return integer? selected
---@protected
function Generator:_getEnumOptions(info, selectedValue)
    local form = self.form
    if not form then
        return {}
    end

    local values ---@type Dropdown.OptionOrString[]
    if info.rules.getEnumOptions then
        values = info.rules.getEnumOptions {
            form = form,
            values = form.values,
            schema = form:getSchema(),
            state = form:getState(),
        }
    end

    values = values or info.field:getEnumValues()
    local prefix = (info.type == 'compatibility') and 'OmiLibrary.form-compatibility' or info.prefix

    local selectedIdx
    local options = {} ---@type Dropdown.Option[]
    for i = 1, #values do
        local value = values[i]
        if type(value) == 'table' then
            local data = value.data or value.text
            options[#options + 1] = {
                text = value.text,
                data = data,
                tooltip = value.tooltip,
            }

            value = data
        else
            local name = tostring(value)
            options[#options + 1] = {
                data = value,
                text = getAttrOrNull(prefix, 'option-' .. name) or name,
                tooltip = getAttrOrNull(prefix, 'option-tooltip-' .. name),
            }
        end

        if value == selectedValue then
            selectedIdx = i
        end
    end

    return options, selectedIdx
end

---Adds the given amount to the next Y position.
---@param amount number? The amount to add. Defaults to `0`.
---@param noPadding boolean? If `true`, padding will not be added alongside the amount.
---@protected
function Generator:_increaseNextY(amount, noPadding)
    local padY = self.form and self.form.padY or 0
    self.nextY = self.nextY + (amount or 0) + (noPadding and 0 or padY)
end

---Checks whether a field is an object or array of objects.
---@param info forms.FieldInfo
---@return boolean
---@protected
function Generator:_isObjectOrObjectArray(info)
    if info.type == 'object' then
        return true
    elseif info.type ~= 'array' then
        return false
    end

    local itemsField = info.field:getItemsField()
    local itemsType = itemsField and itemsField:getType()
    return itemsType == 'object'
end

---Pops the previous `nextY` value from the stack, sets it, and returns the previous value.
---@return number
---@protected
function Generator:_popNextY()
    if #self.nextYStack == 0 then
        return self.nextY
    end

    local prev = self.nextY
    self.nextY = self.nextYStack[#self.nextYStack]
    self.nextYStack[#self.nextYStack] = nil

    return prev
end

---Pushes the current next Y onto a stack and sets it to a new value.
---@param nextY number?
---@protected
function Generator:_pushNextY(nextY)
    self.nextYStack[#self.nextYStack + 1] = self.nextY
    self.nextY = nextY or (self.form and self.form.marginTop or 0)
end


---Creates a new form generator.
---@param options Args.FormGenerator
---@return forms.Generator
function Generator:new(options)
    local this = core.new(self)

    this.schema = options.schema
    this.rules = options.rules or {}
    this.prefix = options.prefix or 'OmiLibrary.form-default'
    this.title = options.title
    this.versionKey = options.versionKey or 'VERSION'
    this.closeOnSave = options.closeOnSave ~= false
    this.destroyOnClose = options.destroyOnClose ~= false

    this.nextY = 0
    this.nextYStack = {}

    return this
end


return Generator

--#region Type Definitions

---@class Args.FormGenerator.FromFile
---@field prefix? string The prefix to use for translation string IDs. Defaults to `<modId>.config`.
---@field title? string The text to use for the form title. Defaults to the translation from `prefix` + `'_title'`.
---@field closeOnSave? boolean If `true`, the form will immediately close after saving. Defaults to `true`.
---@field destroyOnClose? boolean If `true`, the form will immediately be destroyed when closing. Defaults to `true`.

---@class Args.FormGenerator.Partial : Args.FormGenerator.FromFile
---@field prefix? string The prefix to use for translation string IDs. Defaults to `OmiLibrary.form-default`.
---@field versionKey? string A top-level field key that stores the version field, to ignore in the form. Defaults to `'VERSION'`.
---@field rules? table<string, forms.Rules> A mapping of schema property keys to associated rules.

---@class Args.FormGenerator : Args.FormGenerator.Partial
---@field schema Schema The schema to use for the generated form.

---@class Args.FormGeneration : Args.Form.Partial
---@field formClass? forms.Form The class to use to create the form. Must be a subclass of `Form` with a constructor that accepts the same argument table.

--#endregion
