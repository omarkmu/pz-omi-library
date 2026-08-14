---Form for collecting information from the user.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/Core/UI'
local Panel = require 'OmiLibrary/Component/UI/Panel'
local Dropdown = require 'OmiLibrary/Component/UI/Dropdown'
local Checkbox = require 'OmiLibrary/Component/UI/Checkbox'
local TextEntry = require 'OmiLibrary/Component/UI/TextEntry'
local ColorEntry = require 'OmiLibrary/Component/UI/ColorEntry'
local ListEntry = require 'OmiLibrary/Component/UI/ListEntry'
local CheckboxGroup = require 'OmiLibrary/Component/UI/CheckboxGroup'
local ObjectArrayPanel = require 'OmiLibrary/Component/UI/Forms/ObjectArrayPanel'

local wipe = table.wipe
local getText = core.l10n.getText
local getAttr = core.l10n.getAttr
local getAttrOrNull = core.l10n.getAttrOrNull
local textManager = getTextManager()

local DEFAULT_PREFIX = 'OmiLibrary.form-default'


---@class forms.Form : Panel, BaseUI
---@field values table Container for form values.
---@field titleText string The text to use for the form title.
---@field textFont UIFont The font to use for labels and controls.
---@field titleFont UIFont The font to use for the title.
---@field headingFont UIFont The font to use for section headings.
---@field listFont UIFont The font to use for the listbox.
---@field buttonFont UIFont The font to use for buttons.
---@field useFullWidthText boolean Whether the full width should be used for text controls.
---@field useFullWidthList boolean Whether the full width should be used for list controls.
---@field marginLeft number The margin between the left of the form and its contents.
---@field marginRight number The margin between the right of the form and its contents.
---@field marginTop number The margin between the top of the form and its contents.
---@field marginBottom number The margin between the bottom of the form and its contents.
---@field padY number The padding to add after each control.
---@field actionPadX number The padding to add between a control and an action button.
---@field infoPadX number The padding to add between a control and an info button.
---@field headingPadY number The padding to add before section headings.
---@field controlWidth number The default width to use for controls.
---@field controlHeight number The default height to use for controls.
---@field titleLabel Label The label used to display the form title.
---@field listbox ListBox The listbox used to select form pages.
---@field closeButton Button The close button.
---@field saveButton Button The save button.
---@field labelColor ColorTableRGBA<number> The color to use for labels of enabled fields.
---@field labelColorDisabled ColorTableRGBA<number> The color to use for labels of disabled fields.
---@field saveText string The text to show on save, if `closeOnSave` is not `true`.
---@field saveFailureText string The text to show on failure to save, if `closeOnSave` is not `true`.
---@field successColor ColorTableRGBA<number> The color to use for success status messages.
---@field failureColor ColorTableRGBA<number> The color to use for failure status messages.
---@field closeOnSave boolean Whether the form should immediately close after saving.
---@field destroyOnClose boolean Whether the form should be destroyed when closing.
---@field protected __base Panel The base class.
---@field protected _statusResetTime number The time after which the status text should be hidden.
---@field protected _fields table<string, forms.FormFieldRecord> Mapping of keys to field records.
---@field protected _activePage? forms.PageInfo The page that is currently showing.
---@field protected _schema Schema The schema the form is based on.
---@field protected _prefix string The prefix to use for translations.
---@field protected _pathCache table<string, string[]> Cache for string paths.
---@field protected _pages table<string, forms.PageInfo> Map of page keys to page info objects.
---@field protected _onClose? FormCallback.Close Invoked when closing the form.
---@field protected _onSave? FormCallback.Save Invoked when saving the form.
---@field protected _onUpdate? FormCallback.Update Invoked when the update method is called.
---@field protected _state table General form state.
local Form = Panel:derive('OmiForm')


---Registers a field as part of the form.
---@param info forms.FieldInfo
function Form:addField(info)
    local path = info.path
    local parent = self._fields
    for i = 1, #path do
        local key = path[i]
        if not parent[key] then
            parent[key] = { children = {} }
        end

        if i == #path then
            parent[key].info = info
        else
            parent = parent[key].children
        end
    end
end

---Adds a page to the form.
---@param page forms.PageInfo
function Form:addPage(page)
    local info = page.info
    self._pages[info.key] = page

    self:addField(info)
    self:addChild(page.panel)

    local listbox = self.listbox
    local item = listbox:addItem(info.name, page)
    item.tooltip = info.rules.tooltip or page.tooltip

    -- once we have 2 pages, show the listbox and shift the pages over
    if listbox:getItemCount() == 2 then
        listbox:setVisible(true)
        for _, pageInfo in pairs(self._pages) do
            local panel = pageInfo.panel
            local label = pageInfo.label

            panel:setX(listbox:getRight() + 24)
            panel:setWidth(self.width - listbox:getRight() - 48)

            if label then
                local remainder = panel.width - textManager:MeasureStringX(self.headingFont, label:getName() or '')
                label:setX(remainder * 0.5)
            end
        end
    end
end

---Closes the form.
function Form:close()
    if self.destroyOnClose then
        self:destroy()
    else
        self:setVisible(false)
    end

    if self._onClose then
        self._onClose {
            form = self,
            values = self.values,
            schema = self._schema,
            state = self._state,
        }
    end
end

---Clears the table used for general form state.
function Form:clearState()
    wipe(self._state)
end

---Creates an action button associated with a field.
---@param args Args.CreateFormActionButton
---@return Button? button
function Form:createActionButton(args)
    return self:_createButton(args, self.actionPadX)
end

---Creates a checkbox field for the form.
---@param args Args.CreateFormControl
---@return Checkbox
function Form:createCheckbox(args)
    return UI.checkbox {
        parent = args.parent,
        text = args.info.name,
        checked = args.value,
        x = self.marginLeft,
        y = args.y,
        h = self.controlHeight,
        tooltip = args.tooltip,
        font = self.textFont,
        textColor = self.labelColor,
        textColorDisabled = self.labelColorDisabled,
        target = self,
        onChange = self._onChangeCheckbox,
        onChangeArgs = { args.info.path },
    }
end

---Creates a checkbox group field for the form.
---@param args Args.CreateFormControl.CheckboxGroup
---@return CheckboxGroup
function Form:createCheckboxGroup(args)
    return UI.checkboxGroup {
        parent = args.parent,
        items = args.items,
        x = self.marginLeft,
        y = args.y,
        h = self.controlHeight,
        font = self.textFont,
        textColor = self.labelColor,
        textColorDisabled = self.labelColorDisabled,
        tooltip = args.tooltip,
        target = self,
        onChange = self._onChangeCheckboxGroup,
        onChangeArgs = { args.info.path },
    }
end

---Creates the children of the form.
function Form:createChildren()
    local btnW = 100
    local btnH = math.max(25, textManager:getFontHeight(self.buttonFont) + 6)
    local btnY = self.height - 10 - btnH
    local titleW = textManager:MeasureStringX(self.titleFont, self.titleText)
    local titleH = textManager:getFontHeight(self.titleFont)
    local textH = textManager:getFontHeight(self.textFont)

    self.titleLabel = UI.label {
        parent = self,
        x = (self.width - titleW) * 0.5,
        y = 10,
        h = titleH,
        text = self.titleText,
        font = self.titleFont,
    }

    self.listbox = UI.listBox {
        parent = self,
        x = 24,
        y = titleH + 20,
        w = math.min(125 + 25 * UI.getScale(), self.width * 0.25),
        h = self.height - btnH - titleH - 40,
        drawBorder = true,
        anchorBottom = true,
        font = self.listFont,
        itemPadY = 4,
        target = self,
        onMouseDown = self.switchPage,
        visible = false,
    }

    self.closeButton = UI.button {
        parent = self,
        internal = 'CLOSE',
        x = self.width - 124,
        y = btnY,
        w = btnW,
        h = btnH,
        text = getText('@ui.btn-close'),
        useCancelStyle = true,
        font = self.buttonFont,
        anchorLeft = false,
        anchorTop = false,
        anchorBottom = true,
        target = self,
        onClick = self.close,
    }

    self.saveButton = UI.button {
        parent = self,
        internal = 'SAVE',
        y = btnY,
        w = btnW,
        h = btnH,
        text = getText('@ui.btn-save'),
        useAcceptStyle = true,
        font = self.buttonFont,
        anchorLeft = false,
        anchorTop = false,
        anchorBottom = true,
        target = self,
        onClick = self.save,
    }

    self.statusLabel = UI.label {
        parent = self,
        x = self.listbox.x + 5,
        y = self.listbox:getBottom() + textH,
        w = self.width - self.saveButton.x - self.listbox.x,
        h = textH,
        text = '',
        font = self.textFont,
        visible = false,
    }

    self.saveButton:setWidthToTitle(btnW)
    self.saveButton:setX(self.closeButton.x - 20 - self.saveButton.width)
end

---Creates a color entry field for the form.
---@param args Args.CreateFormControl.ColorEntry
---@return ColorEntry
function Form:createColorEntry(args)
    return UI.colorEntry {
        parent = args.parent,
        x = self.marginLeft,
        y = args.y,
        w = self.controlWidth,
        h = self.controlHeight,
        font = self.textFont,
        defaultColor = args.value,
        emptyColor = args.emptyColor,
        tooltip = args.tooltip,
        target = self,
        onChange = self._onChangeColor,
        onChangeArgs = { args.info.path },
    }
end

---Creates a dropdown field for the form.
---@param args Args.CreateFormControl.Dropdown
---@return Dropdown
function Form:createDropdown(args)
    return UI.dropdown {
        parent = args.parent,
        x = self.marginLeft,
        y = args.y,
        h = self.controlHeight,
        minWidth = self.controlWidth,
        maxWidth = args.parent.width * 0.5 - self.marginLeft,
        font = self.textFont,
        options = args.options,
        selected = args.selected,
        tooltip = args.tooltip,
        target = self,
        onChange = self._onChangeDropdown,
        onChangeArgs = { args.info.path },
    }
end

---Creates an info button associated with a field.
---@param args Args.CreateFormButton
---@return Button? button
function Form:createInfoButton(args)
    args = core.copy(args)
    args.image = args.image or getTexture('media/ui/Panel_info_button.png')
    return self:_createButton(args, self.infoPadX, true)
end

---Creates a list entry field for the form.
---@param args Args.CreateFormControl.ListEntry
---@return ListEntry
function Form:createListEntry(args)
    return UI.listEntry(self:_getListEntryArgs(args))
end

---Creates a map entry field for the form.
---@param args Args.CreateFormControl.MapEntry
---@return MapEntry
function Form:createMapEntry(args)
    local entryArgs = self:_getListEntryArgs(args) --[[@as InitArgs.MapEntry]]
    entryArgs.keyPlaceholder = args.keyPlaceholder
    entryArgs.valuePlaceholder = args.valuePlaceholder

    return UI.mapEntry(entryArgs)
end

---Creates a number entry field for the form.
---@param args Args.CreateFormControl.NumberEntry
---@return TextEntry
function Form:createNumberEntry(args)
    return UI.textEntry {
        parent = args.parent,
        text = args.value,
        x = self.marginLeft,
        y = args.y,
        w = self.controlWidth,
        h = self.controlHeight,
        font = self.textFont,
        onlyNumbers = true,
        minValue = args.min,
        maxValue = args.max,
        tooltip = args.tooltip,
        requireInteger = args.isInteger,
        target = self,
        onChange = self._onChangeText,
        onChangeArgs = { args.info.path },
    }
end

---Creates an object array control field for the form.
---@param args Args.CreateFormControl.ObjectArray
---@return forms.ObjectArrayPanel
function Form:createObjectArrayPanel(args)
    local parent = args.parent
    local rules = args.info.rules

    local h = self.controlHeight * 20
    if rules.useFullPage then
        -- use the remainder of the page space
        h = math.max(parent.height - args.y - self.marginBottom - self.padY * 2, h)
    end

    local prefix = args.info.prefix
    local addDeleteTooltip = getAttrOrNull(prefix, 'tooltip-add-delete')
    local upDownTooltip = getAttrOrNull(prefix, 'tooltip-up-down')

    local control = ObjectArrayPanel:new {
        x = self.marginLeft,
        y = args.y,
        w = parent.width - self.marginLeft - self.marginRight,
        h = h,
        drawBorder = true,
        font = self.textFont,
        itemPadY = 4,
        emptyText = rules.arrayEmptyText or getAttrOrNull(prefix, 'empty'),
        addTooltip = rules.arrayAddTooltip
            or getAttrOrNull(prefix, 'tooltip-add')
            or addDeleteTooltip,
        deleteTooltip = rules.arrayDeleteTooltip
            or getAttrOrNull(prefix, 'tooltip-delete')
            or addDeleteTooltip,
        moveUpTooltip = rules.arrayMoveUpTooltip
            or getAttrOrNull(prefix, 'tooltip-up')
            or upDownTooltip,
        moveDownTooltip = rules.arrayMoveDownTooltip
            or getAttrOrNull(prefix, 'tooltip-down')
            or upDownTooltip,
        minWidth = self.controlWidth,
        maxItems = args.maxItems,
        anchorRight = true,
        target = self,
        onAdd = self._onObjectArrayAdd,
        onDelete = self._onObjectArrayDelete,
        onMove = self._onObjectArrayShiftItem,
        onSelect = self._onObjectArrayPage,
        onAddArgs = { args.info.path },
        onDeleteArgs = { args.info.path },
        onMoveArgs = { args.info.path },
        onSelectArgs = { args.info.path },
    }

    control:initialise()
    parent:addChild(control)

    control:setScrollChildren(true)

    return control
end

---Creates a page heading for the form.
---@param args Args.CreateFormPageHeading
---@return Label
function Form:createPageHeading(args)
    local info = args.page.info
    local title = getAttrOrNull(info.prefix, 'title') or info.name

    return UI.label {
        parent = args.parent,
        text = title,
        x = (args.parent.width - textManager:MeasureStringX(self.headingFont, title)) * 0.5,
        y = self.marginTop,
        h = textManager:getFontHeight(self.headingFont),
        font = self.headingFont,
    }
end

---Creates a panel for a form page.
---@return Panel
function Form:createPagePanel()
    local listbox = self.listbox
    local showListbox = listbox:getItemCount() > 1
    local listboxRight = showListbox and listbox:getRight() or 0

    return UI.panel {
        x = showListbox and (listboxRight + 24) or listbox.x,
        y = listbox:getY(),
        w = self.width - listboxRight - 48,
        h = listbox:getHeight(),
        handleScrolling = true,
        addVerticalScrollbar = true,
        visible = false,
    }
end

---Creates a text entry field for the form.
---@param args Args.CreateFormControl.TextEntry
---@return TextEntry
function Form:createTextEntry(args)
    local maxLines = args.maxLines
    local displayLines = args.displayLines or 1
    local useFullWidth = self.useFullWidthText and not args.noFullWidth

    return UI.textEntry {
        parent = args.parent,
        text = args.value,
        x = self.marginLeft,
        y = args.y,
        w = self:_getEntryWidth(args.parent, useFullWidth),
        h = self.controlHeight * displayLines,
        font = self.textFont,
        maxLines = maxLines,
        tooltip = args.tooltip,
        minWidth = self.controlWidth,
        anchorRight = useFullWidth,
        addVerticalScrollbar = maxLines and maxLines > displayLines,
        target = self,
        onChange = self._onChangeText,
        onChangeArgs = { args.info.path },
    }
end

---Gets the control for the field associated with the given path.
---@param pathOrArgs forms.Path | Args.GetFormFieldRecord
---@return ISUIElement?
function Form:getFieldControl(pathOrArgs)
    local info = self:getFieldInfo(pathOrArgs)
    return info and info.control
end

---Gets the information for the field associated with the given path.
---@param pathOrArgs forms.Path | Args.GetFormFieldRecord
---@return forms.FieldInfo?
function Form:getFieldInfo(pathOrArgs)
    local rec = self:getFieldRecord(pathOrArgs)
    return rec and rec.info
end

---Gets the field record for the given path.
---@param pathOrArgs forms.Path | Args.GetFormFieldRecord
---@return forms.FormFieldRecord?
function Form:getFieldRecord(pathOrArgs)
    local args = pathOrArgs
    local path = self:_getPath(args)

    local last = #path - (args.ancestorLevel or 0)
    local children = self._fields
    for i = 1, last do
        local key = path[i]
        local rec = children[key]
        if not rec or i == last then
            return rec
        end

        children = rec.children
    end
end

---Gets the selected index for a given object array control.
---@param pathOrArgs forms.Path | Args.GetFormFieldRecord
---@return integer? selectedIdx
---@return forms.FormFieldRecord? record
function Form:getFieldSelectedIndex(pathOrArgs)
    local rec = self:getFieldRecord(pathOrArgs)
    local info = rec and rec.info
    if not info or not info.isArrayObjectField then
        return nil, rec
    end

    local control = info and info.control --[[@as forms.ObjectArrayPanel?]]
    if not control then
        return nil, rec
    end

    return control:getSelected(), rec
end

---Gets the prefix to use for translations.
---@return string
function Form:getPrefix()
    return self._prefix
end

---Returns the schema associated with the form.
---@return Schema
function Form:getSchema()
    return self._schema
end

---Returns the table used for general form state.
---@return table
function Form:getState()
    return self._state
end

---Gets the value for the given path.
---@param pathOrArgs forms.Path | Args.GetFormFieldValue
---@return any | nil
function Form:getValue(pathOrArgs)
    local args = pathOrArgs
    local path = self:_getPath(args)

    local values = self.values
    local last = #path - (args.ancestorLevel or 0)
    for i = 1, last do
        local key = path[i]
        if values[key] ~= nil then
            values = values[key]
        elseif args.createParents and i ~= last then
            values[key] = {}
            values = values[key]
        else
            return
        end
    end

    if args.excludeTopLevel and values == self.values then
        return
    end

    return values
end

---Calls initialize callbacks for form fields.
function Form:init()
    local stack = {} ---@type forms.FormFieldRecord[]
    for _, field in pairs(self._fields) do
        stack[#stack + 1] = field
    end

    while #stack > 0 do
        local field = stack[#stack] --[[@as forms.FormFieldRecord]]
        stack[#stack] = nil

        for _, child in pairs(field.children) do
            stack[#stack + 1] = child
        end

        local info = field.info
        local rules = info and info.rules

        local init = rules and rules.init
        if info and init then
            local parent = self:getValue({
                path = info.path,
                ancestorLevel = 1,
                createParents = true,
                excludeTopLevel = true,
            })

            init {
                key = info.key,
                form = self,
                schema = self._schema,
                state = self._state,
                values = self.values,
                value = self:getValue(info.path),
                parent = parent,
                info = info,
            }
        end
    end
end

---Called when creating the Java object associated with the form.
function Form:instantiate()
    Panel.instantiate(self)
    self:setScrollChildren(true)
end

---Refreshes controls to reflect current values.
function Form:refresh()
    local stack = {} ---@type forms.FormFieldRecord[]
    for _, field in pairs(self._fields) do
        stack[#stack + 1] = field
    end

    while #stack > 0 do
        local field = stack[#stack] --[[@as forms.FormFieldRecord]]
        stack[#stack] = nil

        for _, child in pairs(field.children) do
            stack[#stack + 1] = child
        end

        local info = field.info
        local control = info and info.control
        if control then ---@cast info forms.FieldInfo
            if core.isinstance(control, ObjectArrayPanel) then
                self:updateObjectArrayValues({ path = info.path })
            else
                local parentInfo = self:getFieldInfo({ path = info.path, ancestorLevel = 1 })
                if not parentInfo or not parentInfo.isArrayObjectField then
                    self:setFieldControlValue(info, self:getValue({ path = info.path, createParents = true }))
                    self:triggerOnChange(info)
                end
            end
        end
    end
end

---Saves the values in the form and closes the form.
function Form:save()
    local status, success
    if self._onSave then
        success, status = self._onSave({
            form = self,
            values = self.values,
            schema = self._schema,
            state = self._state,
        })

        if success == nil then
            success = true
        end
    end

    if self.closeOnSave and success then
        self:close()
        return
    end

    self:setStatusMessage({
        message = status or (success and self.saveText or self.saveFailureText),
        color = success and self.successColor or self.failureColor,
    })
end

---Sets whether the control associated with the given path is enabled.
---@param pathOrArgs forms.Path | Args.GetFormFieldRecord
---@param enabled boolean
function Form:setControlEnabled(pathOrArgs, enabled)
    self:setFieldControlEnabled(self:getFieldInfo(pathOrArgs), enabled)
end

---Sets the value of the control associated with the given path.
---This does not set the value in the table.
---@param pathOrArgs forms.Path | Args.GetFormFieldRecord
---@param value any?
function Form:setControlValue(pathOrArgs, value)
    self:setFieldControlValue(self:getFieldInfo(pathOrArgs), value)
end

---Sets whether the control associated with the given field is enabled.
---@param info forms.FieldInfo?
---@param enabled boolean
function Form:setFieldControlEnabled(info, enabled)
    local control = info and info.control
    local label = info and info.label
    if not info or not control then
        return
    end

    control:setEnabled(enabled)

    if label then
        local color = enabled and self.labelColor or self.labelColorDisabled
        label.r = color.r
        label.g = color.g
        label.b = color.b
        label.a = color.a
    end
end

---Sets the value of the control associated with the given field.
---This does not set the value in the table.
---@param info forms.FieldInfo?
---@param value any?
function Form:setFieldControlValue(info, value)
    local control = info and info.control
    if not info or not control then
        return
    end

    if core.isinstance(control, ColorEntry) then
        value = value and control:formatColor(value) or ''
        control:setText(value, false)
    elseif core.isinstance(control, TextEntry) then
        control:setText(tostring(value or ''), false)
    elseif core.isinstance(control, ListEntry) then
        control:setValue(value)
    elseif core.isinstance(control, Dropdown) then
        control:selectData(value)
    elseif core.isinstance(control, Checkbox) then
        control:setChecked(value)
    elseif core.isinstance(control, CheckboxGroup) then
        control:setSelectedSet(value or {})
    else
        error('Unrecognized Form entry type')
    end
end

---Sets a status message for the form.
---@param args Args.SetFormStatusMessage | string
function Form:setStatusMessage(args)
    if type(args) == 'string' then
        args = { message = args }
    end

    self.statusLabel:setName(args.message)
    self.statusLabel:setVisible(true)

    local color = args.color or { r = 1, g = 1, b = 1, a = 1 }
    self.statusLabel:setColor(color.r, color.g, color.b)
    self.statusLabel.a = color.a or 1

    local timer = args.timer or 5
    if timer < 0 then
        self._statusResetTime = -1
    else
        self._statusResetTime = getTimestampMs() + timer * 1000
    end
end

---Sets values on the form and updates controls.
---@param values table?
function Form:setValues(values)
    table.wipe(self.values)
    self._schema:read({ source = values or {}, dest = self.values })
    self:refresh()
end

---Switches the view to the given page.
---@param page forms.PageInfo
function Form:switchPage(page)
    if not page then
        return
    end

    local oldPage = self._activePage
    if oldPage then
        oldPage.panel:setVisible(false)
    end

    page.panel:setYScroll(0)
    page.panel:setVisible(true)
    self._activePage = page
end

---Triggers an `onChange` call for the given field.
---@param info forms.FieldInfo?
function Form:triggerOnChange(info)
    local control = info and info.control
    if not info or not control then
        return
    end

    if core.isinstance(control, TextEntry) then
        control:setText(control:getInternalText(), true)
    elseif core.isinstance(control, Dropdown) then
        self:_onChange(control:getOptionData(control.selected), info.path)
    elseif core.isinstance(control, Checkbox) then
        self:_onChange(control:isSelected(), info.path)
    elseif core.isinstance(control, CheckboxGroup) then
        self:_onChange(control:getSelectedSet(), info.path)
    elseif core.isinstance(control, ListEntry) then
        control:setValue(control:getValue(), true)
    else
        error('Unrecognized Form entry type')
    end
end

---Called every 100ms while the form is visible.
function Form:update()
    if self._onUpdate then
        self._onUpdate({
            form = self,
            values = self.values,
            schema = self._schema,
            state = self._state,
        })
    end

    if self._statusResetTime > 0 and getTimestampMs() >= self._statusResetTime then
        self.statusLabel:setVisible(false)
        self._statusResetTime = -1
    end
end

---Updates the values of an object array to reflect the current selection.
---@param args Args.UpdateObjectArrayValues
function Form:updateObjectArrayValues(args)
    local rec = self:getFieldRecord(args.path)
    local info = rec and rec.info
    local control = info and info.control --[[@as forms.ObjectArrayPanel?]]
    if not rec or not info or not control then
        return
    end

    if not args.noReset then
        control:clear()
    end

    local values = args.values or self:getValue(args.path)
    if not values or type(values) ~= 'table' or #values == 0 then
        return
    end

    local selected = args.selected or 1
    local swapIdx = args.swapIndex
    if swapIdx and values[selected] and values[swapIdx] then
        local swapValue = values[swapIdx]
        values[swapIdx] = values[selected]
        values[selected] = swapValue
    end

    if not args.noReset then
        for i = 1, #values do
            control:addPage(self:_getObjectArrayItemDisplay(info, values, i))
        end

        control:setSelected(selected) -- restore selection after clear
    end

    local selectedItem = values[selected]
    if args.silent or not selectedItem then
        return
    end

    for key, childRec in pairs(rec.children) do
        self:setFieldControlValue(childRec.info, selectedItem[key])
        self:triggerOnChange(childRec.info)
    end
end


---Creates a button for the form.
---@param args Args.CreateFormButton
---@param padX number
---@param isInfo boolean?
---@return Button? button
---@protected
function Form:_createButton(args, padX, isInfo)
    local label = args.label
    local control = args.control
    local info = args.info

    local noLabel = info.rules.noLabel
    local hideControl = info.rules.hideControl

    local forceLabel
    if not noLabel and not hideControl then
        forceLabel = not control
            or core.isinstance(control, ListEntry)
            or (core.isinstance(control, CheckboxGroup) and not core.isinstance(control, Checkbox))
            or (self.useFullWidthText and not info.rules.noFullWidth and core.isinstance(control, TextEntry))
    end

    -- determine which element to position the button next to
    local referenceEl ---@type ISUIElement?
    if not isInfo and #info.actionButtons > 0 then
        referenceEl = info.actionButtons[#info.actionButtons]
    elseif forceLabel then
        referenceEl = label
        if not referenceEl then
            return
        end
    end

    referenceEl = referenceEl or control
    if not referenceEl then
        return
    end

    local w
    local h
    local x = hideControl and referenceEl.x or (referenceEl:getRight() + padX)
    local y = referenceEl.y
    if args.image then
        w = args.image:getWidth()
        h = args.image:getHeight()
    end

    local button = UI.button {
        parent = args.parent,
        x = x,
        y = y,
        w = w,
        h = h,
        text = args.text,
        image = args.image,
        tooltip = args.tooltip,
        font = self.buttonFont,
        background = not isInfo,
        target = self,
        onClick = self._onButton,
        onClickArgs = { info.path, args.callback, args.index },
    }

    if not hideControl and (args.image or referenceEl.height <= button.height) then
        button:setY(y + (referenceEl.height - button.height) * 0.5)
    end

    return button
end

---Generates a new value for an object array.
---@param path string[]
---@param index integer
---@return table?
---@protected
function Form:_createObjectArrayValue(path, index)
    local info = self:getFieldInfo(path)
    if not info then
        return
    end

    if info.rules.createItem then
        return info.rules.createItem {
            info = info,
            index = index,
            parent = self:getValue({ path = path, excludeTopLevel = true, ancestorLevel = 1 }),
            form = self,
            values = self.values,
            schema = self._schema,
            state = self._state,
        }
    end

    local field = info.field
    return field:read {
        schema = self._schema,
        skipMissing = false,
    }
end

---Gets the width to use for an entry, based on whether full width is allowed.
---@param parent ISUIElement
---@param useFullWidth boolean
---@return number
---@protected
function Form:_getEntryWidth(parent, useFullWidth)
    local w = self.controlWidth
    if useFullWidth then
        local panelW = parent.width
        w = panelW - self.marginLeft - self.marginRight
    end

    return w
end

---Gets arguments to use for creation of a list entry.
---@param args Args.CreateFormControl.ListEntry
---@return InitArgs.ListEntry
---@protected
function Form:_getListEntryArgs(args)
    local useFullWidth = self.useFullWidthList and not args.noFullWidth

    ---@type InitArgs.ListEntry
    local initArgs = {
        parent = args.parent,
        items = args.value,
        x = self.marginLeft,
        y = args.y,
        w = self:_getEntryWidth(args.parent, useFullWidth),
        visibleItems = args.displayLines or 4,
        includeReorderButtons = args.includeReorderButtons,
        font = self.textFont,
        tooltip = args.tooltip,
        minWidth = self.controlWidth,
        maxEntryWidth = self.controlWidth,
        target = self,
        onChange = self._onChangeList,
        onChangeArgs = { args.info.path },
        anchorRight = useFullWidth,
    }

    return initArgs
end

---Gets the string that should display for the listbox item of an object array.
---@param info forms.FieldInfo
---@param parent table
---@param index integer
---@return string
---@protected
function Form:_getObjectArrayItemDisplay(info, parent, index)
    local item = parent[index]

    -- shouldn't happen
    if not item or type(item) ~= 'table' then
        return tostring(index)
    end

    local rules = info.rules
    local display
    if rules.getItemDisplay then
        display = rules.getItemDisplay {
            form = self,
            values = self.values,
            schema = self._schema,
            state = self._state,
            key = info.key,
            info = info,
            value = item,
            index = index,
            parent = parent,
        }
    end

    if not display and rules.arrayDisplayField then
        display = item[rules.arrayDisplayField]
    end

    if display ~= nil then
        display = tostring(display)

        if core.trim(display) == '' then
            return tostring(index)
        end
    end

    return display or tostring(index)
end

---Gets a path table given a string path or a table containing a path.
---@param path forms.Path | { path: forms.Path }
---@return string[]
---@protected
function Form:_getPath(path)
    if type(path) == 'string' then
        if not self._pathCache[path] then
            self._pathCache[path] = path:split('\\.')
        end

        return self._pathCache[path]
    end

    if path.path then
        return self:_getPath(path.path)
    end

    ---@cast path string[]
    return path
end

---Handler for clicking a button.
---@param button Button
---@param path string[]
---@param callback FormCallback.ButtonClick
---@param index integer?
---@protected
function Form:_onButton(button, path, callback, index)
    local key = path[#path]
    if not callback or not key then
        return
    end

    local info = self:getFieldInfo(path)
    if not info then
        return
    end

    callback {
        form = self,
        button = button,
        buttonIndex = index or 1,
        schema = self._schema,
        values = self.values,
        state = self._state,
        key = key,
        info = info,
        value = self:getValue({ path = path, createParents = true }),
        parent = self:getValue({ path = path, ancestorLevel = 1, excludeTopLevel = true }),
        index = self:getFieldSelectedIndex({ path = path, ancestorLevel = 1 }),
    }
end

---Change handler.
---@param value any?
---@param path string[]
---@protected
function Form:_onChange(value, path)
    local key = path[#path]
    if not key then
        return
    end

    local rec
    local index
    local arrayInfo

    if #path == 1 then
        rec = self:getFieldRecord(path)
    else
        local parent
        index, parent = self:getFieldSelectedIndex({ path = path, ancestorLevel = 1 })
        if not parent then
            -- if we have a bad path somehow, bail
            return
        end

        rec = parent.children[key]
        if index then
            arrayInfo = parent.info
        end
    end

    if not rec then
        return
    end

    local initialParent = self:getValue({ path = path, createParents = true, ancestorLevel = 1 })
    local parent = initialParent
    if type(parent) == 'table' then
        -- handle array items
        if index then
            parent[index] = parent[index] or {}
            parent = parent[index]
        end

        parent[key] = value
    end

    -- don't pass the values table as the parent for top-level fields
    if parent == self.values then
        parent = nil
    end

    -- call onChange for element & parents
    local level = 0
    local changedInfo = self:getFieldInfo(path)
    if not changedInfo then
        return
    end

    while level < #path do
        local curPath = { path = path, ancestorLevel = level }
        local info = self:getFieldInfo(curPath)
        local rules = info and info.rules or {}

        local onChange = rules.onChange
        if onChange then
            onChange {
                key = key,
                form = self,
                schema = self._schema,
                state = self._state,
                values = self.values,
                value = value,
                parent = parent,
                info = changedInfo,
                index = index,
            }
        end

        local togglePaths
        local invTogglePaths
        local toggleValue = false
        if rules.toggleFields or rules.togglePageFields then
            togglePaths = core.copyList(rules.toggleFields)
            if rules.togglePageFields then
                togglePaths[#togglePaths + 1] = { path[1], '*' }
            end
        elseif rules.inverseToggleFields or rules.inverseTogglePageFields then
            invTogglePaths = core.copyList(rules.inverseToggleFields)
            if rules.inverseTogglePageFields then
                invTogglePaths[#invTogglePaths + 1] = { path[1], '*' }
            end
        end

        if togglePaths or invTogglePaths then
            toggleValue = not not self:getValue(curPath)
        end

        if togglePaths then
            self:_setToggleFields(togglePaths, toggleValue, info)
        elseif invTogglePaths then
            self:_setToggleFields(invTogglePaths, not toggleValue, info)
        end

        level = level + 1
    end

    -- changes to fields can cause the array item text to change
    if arrayInfo and initialParent and index then
        local displayField = arrayInfo.rules.arrayDisplayField
        if displayField and displayField ~= key then
            return
        end

        self:_updateObjectArrayItemText(arrayInfo, initialParent, index)
    end
end

---Change handler for checkboxes.
---@param value boolean
---@param checkbox Checkbox
---@param path string[]
---@protected
---@diagnostic disable-next-line: unused
function Form:_onChangeCheckbox(value, checkbox, path)
    self:_onChange(value, path)
end

---Change handler for checkbox groups.
---@param index integer
---@param value boolean
---@param checkboxGroup CheckboxGroup
---@param path string[]
---@protected
---@diagnostic disable-next-line: unused
function Form:_onChangeCheckboxGroup(index, value, checkboxGroup, path)
    self:_onChange(checkboxGroup:getSelectedSet(), path)
end

---Change handler for color entries.
---@param path string[]
---@protected
function Form:_onChangeColor(path)
    local info = self:getFieldInfo(path)
    local control = info and info.control --[[@as ColorEntry?]]
    if not info or not control then
        return
    end

    self:_onChange(control:getColor(), path)
end

---Change handler for dropdowns.
---@param selected integer
---@param data any?
---@param dropdown Dropdown
---@param path string[]
---@protected
---@diagnostic disable-next-line: unused
function Form:_onChangeDropdown(selected, data, dropdown, path)
    self:_onChange(data, path)
end

---Change handler for lists.
---@param entry ListEntry
---@param path string[]
---@protected
function Form:_onChangeList(entry, path)
    self:_onChange(entry:getValue(), path)
end

---Change handler for text entries.
---@param path string[]
---@protected
function Form:_onChangeText(path)
    local info = self:getFieldInfo(path)
    local control = info and info.control --[[@as TextEntry?]]
    if not info or not control then
        return
    end

    local value = core.trim(control:getInternalText()) ---@type any
    if info.type == 'double' or info.type == 'integer' then
        value = tonumber(value)
    end

    self:_onChange(value, path)
end

---Event handler for adding a page in an object array.
---@param path string[]
---@protected
function Form:_onObjectArrayAdd(path)
    local array = self:getValue({ path = path, excludeTopLevel = true })
    if type(array) ~= 'table' then
        return
    end

    local index = #array + 1
    local value = self:_createObjectArrayValue(path, index)
    if not value then
        return
    end

    array[index] = value
    self:updateObjectArrayValues {
        path = path,
        selected = index,
    }
end

---Event handler for deleting a page in an object array.
---@param selected integer
---@param path string[]
---@protected
function Form:_onObjectArrayDelete(selected, path)
    local array = self:getValue({ path = path, excludeTopLevel = true })
    if type(array) ~= 'table' then
        return
    end

    table.remove(array, selected)

    self:updateObjectArrayValues {
        path = path,
        selected = math.max(1, (selected <= #array) and selected or selected - 1),
    }
end

---Event handler for selecting a page in an object array.
---@param selected integer
---@param path string[]
---@protected
function Form:_onObjectArrayPage(selected, path)
    self:updateObjectArrayValues {
        path = path,
        selected = selected,
        noReset = true,
    }
end

---Event handler for moving a page in an object array.
---@param selected integer
---@param prevIndex integer
---@param path string[]
---@protected
function Form:_onObjectArrayShiftItem(selected, prevIndex, path)
    self:updateObjectArrayValues {
        path = path,
        selected = selected,
        swapIndex = prevIndex,
    }
end

---Sets field enable state based on a boolean value.
---@param pathList forms.Path[]
---@param value boolean
---@param excludeInfo forms.FieldInfo?
---@protected
function Form:_setToggleFields(pathList, value, excludeInfo)
    pathList = core.copyList(pathList)
    for i = 1, #pathList do
        pathList[i] = self:_getPath(pathList[i])
    end

    ---@cast pathList string[][]

    local seen = {}
    if excludeInfo then
        seen[excludeInfo] = true
    end

    local i = 1
    while i <= #pathList do
        local path = pathList[i] ---@cast path -?
        if path[#path] == '*' then
            local parentRec = self:getFieldRecord({ path = path, ancestorLevel = 1 })
            local children = parentRec and parentRec.children or {}

            for _, child in pairs(children) do
                if child.info then
                    pathList[#pathList + 1] = child.info.path
                end
            end
        else
            local info = self:getFieldInfo(path)
            if info and not seen[info] then
                seen[info] = true
                self:setFieldControlEnabled(info, value)
            end
        end

        i = i + 1
    end
end

---Updates the listbox text for an object array control item.
---@param info forms.FieldInfo
---@param parent table
---@param index integer
---@protected
function Form:_updateObjectArrayItemText(info, parent, index)
    local control = info.control --[[@as forms.ObjectArrayPanel?]]
    if not control or type(parent) ~= 'table' then
        return
    end

    local display = self:_getObjectArrayItemDisplay(info, parent, index)
    control:setItemText(index, display)
end


---Creates a new form element.
---@param args Args.Form
---@return forms.Form
function Form:new(args)
    local this = UI.new(self, Panel.new, args)

    this._schema = args.schema
    this._state = args.state or {}
    this._prefix = args.prefix or DEFAULT_PREFIX
    this._onSave = args.onSave
    this._onClose = args.onClose
    this._onUpdate = args.onUpdate

    this._pages = {}
    this._fields = {}
    this._pathCache = {}
    this._statusResetTime = -1

    this.moveWithMouse = args.moveWithMouse ~= false
    this.successColor = core.color.copyRGBA(core.color.good01)
    this.failureColor = core.color.copyRGBA(core.color.bad01)

    this.titleText = args.title or getAttrOrNull(this._prefix, 'title') or getAttr(DEFAULT_PREFIX, 'title')
    this.saveText = getAttrOrNull(this._prefix, 'save-success') or getAttr(DEFAULT_PREFIX, 'save-success')
    this.saveFailureText = getAttrOrNull(this._prefix, 'save-failure') or getAttr(DEFAULT_PREFIX, 'save-failure')
    this.closeOnSave = args.closeOnSave ~= false
    this.destroyOnClose = args.destroyOnClose ~= false
    this.padY = args.padY or 8
    this.actionPadX = args.actionPadX or 10
    this.infoPadX = args.infoPadX or 6
    this.headingPadY = args.headingPadY or 10
    this.marginLeft = args.marginLeft or 20
    this.marginRight = args.marginRight or 30
    this.marginTop = args.marginTop or 12
    this.marginBottom = args.marginBottom or 12
    this.textFont = args.textFont or UIFont.Small
    this.listFont = args.listFont or UIFont.Small
    this.buttonFont = args.buttonFont or UIFont.Small
    this.headingFont = args.headingFont or UIFont.Medium
    this.titleFont = args.titleFont or UIFont.Large
    this.labelColor = core.copy(core.color.defaultRGBA(args.labelColor, 1, 1, 1, 1))
    this.labelColorDisabled = core.copy(core.color.defaultRGBA(args.labelColorDisabled, 0.5, 0.5, 0.5, this.labelColor.a))
    this.controlWidth = args.controlWidth or (this.width * 0.25)
    this.controlHeight = args.controlHeight or (textManager:getFontHeight(this.textFont) + 4)
    this.useFullWidthText = args.useFullWidthText ~= false
    this.useFullWidthList = args.useFullWidthList ~= false

    this.values = args.values or this._schema:getDefaults()

    return this
end

return Form

--#region Type Definitions

---@class Args.Form.Partial : Args.Panel
---@field title? string The text to use for the form title. Defaults to the translation from `prefix` + `'_title'`.
---@field prefix? string The prefix to use for translations. Defaults to `OmiLibrary.form-default`.
---@field titleFont? UIFont The font to use for the title.
---@field headingFont? UIFont The font to use for section headings.
---@field textFont? UIFont The font to use for labels and controls.
---@field listFont? UIFont The font to use for the listbox.
---@field buttonFont? UIFont The font to use for buttons.
---@field useFullWidthText? boolean Whether the full width should be used for text entry controls. Defaults to `true`.
---@field useFullWidthList? boolean Whether the full width should be used for list entry controls. Defaults to `true`.
---@field marginLeft? number The margin between the left of the form and its contents.
---@field marginRight? number The margin between the right of the form and its contents.
---@field marginTop? number The margin between the top of the form and its contents.
---@field marginBottom? number The margin between the bottom of the form and its contents.
---@field padY? number The padding to add after each control.
---@field actionPadX? number The padding to add between a control and an action button.
---@field infoPadX? number The padding to add between a control and an info button.
---@field controlWidth? number The default width to use for controls.
---@field controlHeight? number The default height to use for controls.
---@field headingPadY? number The padding to add before section headings.
---@field labelColor? ColorTableRGBA<number> The color that labels and headings should use.
---@field labelColorDisabled? ColorTableRGBA<number> The color that labels for disabled controls should use.
---@field values? table Initial values for the form.
---@field onClose? FormCallback.Close Invoked when closing the form.
---@field onSave? FormCallback.Save Invoked when saving the form.
---@field onUpdate? FormCallback.Update Invoked when `update` is called on the form.
---@field closeOnSave? boolean If `true`, the form will automatically close after saving. Defaults to `true`.
---@field destroyOnClose? boolean If `true`, the form will immediately be destroyed when closing. Defaults to `true`.
---@field state? table Default general state table for the form.

---@class Args.Form : Args.Form.Partial
---@field schema Schema The schema the form is based on.

---@class Args.CreateFormPageHeading
---@field parent Panel The element to add the heading to.
---@field page forms.PageInfo Information about the page associated with the heading.
---@field y number The Y position of the heading.

---@class Args.CreateFormButton
---@field parent Panel The element to add the button to.
---@field info forms.FieldInfo Information about the field associated with the button.
---@field callback? FormCallback.ButtonClick The callback to call when the button is clicked.
---@field label? Label The label to align the button with if the control isn't present.
---@field control? ISUIElement The control to align the button with.
---@field tooltip? string The tooltip to use for the button.
---@field text? string The text to use for the button.
---@field image? Texture The image to display on the button.
---@field index? integer The index of the button. Defaults to `1`.

---@class Args.CreateFormActionButton : Args.CreateFormButton
---@field text string The text to use for the button.
---@field index integer The index of the action button.

---@class Args.CreateFormControl
---@field parent Panel The element to add the control to.
---@field info forms.FieldInfo Information about the field associated with the control.
---@field value? any The value to initialize the control with.
---@field tooltip? string The tooltip to set on the control.
---@field y number The Y position of the control.

---@class Args.CreateFormControl.CheckboxGroup : Args.CreateFormControl
---@field items Checkbox.ItemOrString[] Items to include in the checkbox group.

---@class Args.CreateFormControl.Dropdown : Args.CreateFormControl
---@field options Dropdown.Option[] Options to include in the dropdown.
---@field selected? integer The index of the dropdown item that should initially be selected.

---@class Args.CreateFormControl.ListEntry : Args.CreateFormControl
---@field displayLines? integer The number of item lines to use for the height of the entry. Defaults to `4`.
---@field noFullWidth? boolean If `true`, the list entry won't use the full page width if the option is set.
---@field includeReorderButtons? boolean If `true`, buttons to reorder list elements will be included. Defaults to `true`.

---@class Args.CreateFormControl.MapEntry : Args.CreateFormControl.ListEntry
---@field keyPlaceholder? string The string to use for the key entry placeholder.
---@field valuePlaceholder? string The string to use for the value entry placeholder.

---@class Args.CreateFormControl.NumberEntry : Args.CreateFormControl
---@field isInteger boolean Whether the control should require an integer.
---@field min? number The minimum numeric value of the control.
---@field max? number The maximum numeric value of the control.

---@class Args.CreateFormControl.TextEntry : Args.CreateFormControl
---@field maxLines? integer The maximum number of lines that can be input in the entry. Defaults to `1`.
---@field displayLines? integer The number of lines to use for the height of the entry. Defaults to `1`.
---@field noFullWidth? boolean If `true`, the text entry won't use the full page width if the option is set.

---@class Args.CreateFormControl.ColorEntry : Args.CreateFormControl
---@field emptyColor? ColorTable<integer> The color to use if the entry is blank.

---@class Args.CreateFormControl.ObjectArray : Args.CreateFormControl
---@field maxItems? integer The maximum number of items in the array.

---@class Args.GetFormFieldRecord
---@field path string[] The path of the field to retrieve.
---@field ancestorLevel? integer The level of ancestors up from the given path that should be retrieved. Defaults to `0`.

---@class Args.GetFormFieldValue
---@field path string[] The path of the field to retrieve.
---@field createParents? boolean If `true`, parent tables that don't exist will be created.
---@field excludeTopLevel? boolean If `true`, the top-level value table will not be returned if it's the result of the retrieval.
---@field ancestorLevel? integer The level of ancestors up from the given path that should be retrieved. Defaults to `0`.

---@class Args.SetFormStatusMessage
---@field message string The message to show.
---@field color? (ColorTable<number> | ColorTableRGBA<number>) The color to use for the status message. Defaults to white.
---@field timer? number The approximate duration in seconds for the status message to remain. If `-1`, the status will show until hidden. Defaults to `4`.

---@class Args.UpdateObjectArrayValues
---@field path string[] The path of the field to update.
---@field selected? integer The index to set as the selected array index. Defaults to `1`.
---@field swapIndex? integer The index to swap with the selected index.
---@field noReset? boolean If `true`, the control's pages will not be cleared and recreated.
---@field values? any[] The array values.
---@field silent? boolean If `true`, the `onChange` callbacks won't be triggered for child fields.

---@class Args.FormCallback
---@field values table The table containing form values.
---@field form forms.Form The form that invoked the callback.
---@field schema Schema The schema the form is based on.
---@field state table General form state.

---@class Args.FormCallback.Item : Args.FormCallback
---@field key string The key of the relevant field.
---@field info forms.FieldInfo Information about the relevant field.
---@field value? any The current value of the form field.
---@field parent? table The parent table of the form value. For top-level fields, this is `nil`.
---@field index? integer The index of the item in the array.

---@class Args.FormCallback.ButtonClick : Args.FormCallback.Item
---@field button Button The button that was clicked.
---@field buttonIndex integer The index of the button.

---@class Args.FormCallback.CreateItem : Args.FormCallback
---@field info forms.FieldInfo Information about the array item field.
---@field index? integer The index of the new array item.
---@field parent? any[] The parent array.

---@class Args.FormCallback.Close : Args.FormCallback

---@class Args.FormCallback.Save : Args.FormCallback

---@class Args.FormCallback.Update : Args.FormCallback


---@class forms.Rules : forms.Rules.FromFile
---@field children? table<string, forms.Rules> Associates child field keys to rules.
---@field getItemDisplay? (fun(args: Args.FormCallback.Item): string?) Invoked to retrieve the display text for an object array item.
---@field onActionClick? FormCallback.ButtonClick Invoked when a secondary action button is clicked.
---@field onInfoClick? FormCallback.ButtonClick Invoked when an info button is clicked.
---@field getCheckboxOptions? (fun(args: Args.FormCallback): Checkbox.ItemOrString[]) Invoked to retrieve checkbox options for a set field.
---@field getEnumOptions? (fun(args: Args.FormCallback): Dropdown.OptionOrString[]) Invoked to retrieve options for a enum field.
---@field onChange? (fun(args: Args.FormCallback.Item)) Invoked when a field or its children change.
---@field init? (fun(args: Args.FormCallback.Item)) Invoked to initialize a field.
---@field createItem? (fun(args: Args.FormCallback.CreateItem): table) Invoked to create a new object array item.

---@class forms.Rules.FromFile
---@field hidden? boolean If `true`, the field will not be included in the form.
---@field noLabel? boolean If `true`, a label will not be created for the field.
---@field hideControl? boolean If `true`, the created control will not be visible in the form.
---@field noReorderButtons? boolean If `true`, reorder buttons will not be included for a basic list control.
---@field prefix? string The translation prefix to use for the field.
---@field childPrefix? string The translation prefix to use for all child fields.
---@field padTop? number The padding to add above the field's label.
---@field padBottom? number The padding to add below the field's control.
---@field tooltip? string The tooltip to use for the control and label.
---@field action? string The text to use for a secondary action button that displays alongside the field.
---@field actionTooltip? string The tooltip to use for a secondary action button.
---@field actionTooltipId? string The string ID of the tooltip to use for a secondary action button.
---@field actionCount? integer The number of secondary actions to include. Defaults to `1`.
---@field infoTooltip? string The tooltip to use for an info button.
---@field infoTooltipId? string The string ID of the tooltip to use for an info button.
---@field displayLines? integer The number of lines to use for the height of the entry. Defaults to `1` for strings and `4` for string lists.
---@field maxLines? integer The maximum number of lines that can be input in the entry. Defaults to `1`.
---@field arrayEmptyText? string The text to display when the object array field's value has no items. Defaults to the field prefix + `_empty`.
---@field arrayAddTooltip? string The tooltip to display for an object array's add button. Defaults to the field prefix + `_tooltip_add` (or `_tooltip_add_delete`).
---@field arrayDeleteTooltip? string The tooltip to display for an object array's delete button. Defaults to the field prefix + `_tooltip_delete` (or `_tooltip_add_delete`).
---@field arrayMoveUpTooltip? string The tooltip to display for an object array's move up button. Defaults to the field prefix + `_tooltip_up` (or `_tooltip_up_down`).
---@field arrayMoveDownTooltip? string The tooltip to display for an object array's move up button. Defaults to the field prefix + `_tooltip_down` (or `_tooltip_up_down`).
---@field arrayDisplayField? string The field to use for the object array item's display text.
---@field useFullPage? boolean If `true`, an object array will use the full remaining page for its height.
---@field noFullWidth? boolean If `true`, the entry won't use the full page width even if the option is set.
---@field toggleFields? forms.Path[] Array of paths to set to enabled/disabled based on the value of the checkbox. If the checkbox is unchecked, the fields will be unavailable.
---@field inverseToggleFields? forms.Path[] Array of paths to set to enabled/disabled based on the value of the checkbox. If the checkbox is checked, the fields will be unavailable.
---@field togglePageFields? boolean If `true`, this will act as though all elements on the page were included in `toggleFields`.
---@field inverseTogglePageFields? boolean If `true`, this will act as though all elements on the page were included in `inverseToggleFields`.
---@field keyPlaceholder? string The string to use for the key entry placeholder of a map entry.
---@field valuePlaceholder? string The string to use for the value entry placeholder of a map entry.

---@class forms.FormFieldRecord
---@field info? forms.FieldInfo Information about the field.
---@field children table<string, forms.FormFieldRecord> Mapping of field keys to child field records.


---@alias FormCallback.Close fun(args: Args.FormCallback.Close)

---@alias FormCallback.Save fun(args: Args.FormCallback.Save): boolean?, string?

---@alias FormCallback.Update fun(args: Args.FormCallback.Update)

---@alias FormCallback.ButtonClick fun(args: Args.FormCallback.ButtonClick)

---@alias forms.Path string | string[]

--#endregion
