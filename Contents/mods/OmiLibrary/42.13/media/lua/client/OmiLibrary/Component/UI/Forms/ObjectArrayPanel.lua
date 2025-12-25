---Panel control for an array of objects in a form.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/UI/Core'
local Panel = require 'OmiLibrary/Component/UI/Panel'

local getText = core.l10n.getText
local textManager = getTextManager()


---@class forms.ObjectArrayPanel : Panel
---@field listbox ListBox The listbox used to select array items.
---@field addBtn Button The button used to add an array item.
---@field deleteBtn Button The button used to delete an array item.
---@field moveUpBtn Button The button used to move an array item up 1 position.
---@field moveDownBtn Button The button used to move an array item down 1 position.
---@field contentPanel Panel The panel containing the array fields.
---@field emptyPanel Panel The panel used when the array is empty.
---@field font UIFont The font to use for controls.
---@field disabled boolean Whether the control should block interactions.
---@field addTooltip? string The tooltip to display for the add button.
---@field deleteTooltip? string The tooltip to display for the delete button.
---@field moveUpTooltip? string The tooltip to display for the move up button.
---@field moveDownTooltip? string The tooltip to display for the move down button.
---@field maxItems? integer The maximum number of items in the array.
---@field maxTooltip? string The tooltip to use for the add button when the maximum number of items is reached.
---@field protected callbacks forms.ObjectArrayPanel.Callbacks Container for callbacks.
---@field protected init forms.ObjectArrayPanel.Init Information used only during initialization.
---@field protected __base Panel The base class.
local ObjectArrayPanel = Panel:derive('OmiObjectArrayPanel')


---Adds a page to the control.
---@param text string The text to use for the listbox item.
function ObjectArrayPanel:addPage(text)
    self.listbox:addItem(text)

    if self:isEmptyState() then
        self:switchToContentState()
    end
end

---Clears the content from the control and switches to the empty state.
function ObjectArrayPanel:clear()
    self.listbox:clear()
    self:switchToEmptyState()
end

---Creates the child elements of the control.
function ObjectArrayPanel:createChildren()
    local btnH = math.max(25, textManager:getFontHeight(self.font) + 6)
    local controlW = math.max(100, self.width * 0.2)
    local moveBtnW = controlW * 0.5 - 4

    self.listbox = UI.listBox {
        parent = self,
        w = controlW,
        h = self.height - btnH * 3 - 12,
        drawBorder = true,
        repaintStencil = true,
        ignoreClickCurrentSelection = true,
        font = self.font,
        itemPadY = self.init.itemPadY,
        target = self,
        onMouseDown = self.switchPage,
    }

    self.moveUpBtn = UI.button {
        parent = self,
        internal = 'UP',
        image = getTexture('media/ui/ArrowUp.png'),
        tooltip = self.moveUpTooltip,
        y = self.listbox:getBottom() + 4,
        w = moveBtnW,
        h = btnH,
        target = self,
        onClick = self._onClickMoveUp,
    }

    self.moveDownBtn = UI.button {
        parent = self,
        internal = 'UP',
        image = getTexture('media/ui/ArrowDown.png'),
        tooltip = self.moveDownTooltip,
        x = self.moveUpBtn:getRight() + 8,
        y = self.moveUpBtn.y,
        w = moveBtnW,
        h = btnH,
        target = self,
        onClick = self._onClickMoveDown,
    }

    self.addBtn = UI.button {
        parent = self,
        internal = 'ADD',
        text = getText('@ui.btn-add'),
        tooltip = self.addTooltip,
        y = self.moveDownBtn:getBottom() + 4,
        w = controlW,
        h = btnH,
        font = self.font,
        target = self,
        onClick = self._onClickAdd,
    }

    self.deleteBtn = UI.button {
        parent = self,
        internal = 'DELETE',
        text = getText('@ui.btn-delete'),
        tooltip = self.deleteTooltip,
        x = self.addBtn.x,
        y = self.addBtn:getBottom() + 4,
        w = controlW,
        h = btnH,
        font = self.font,
        target = self,
        onClick = self._onClickDelete,
    }

    self.contentPanel = self:_createPanel()
    self.emptyPanel = self:_createPanel()

    self.coverPanel = UI.panel {
        parent = self,
        w = self.width,
        h = self.height,
        visible = false,
        anchorBottom = true,
        anchorRight = true,
    }

    self.coverPanel.javaObject:setConsumeMouseEvents(true)

    local text = self.init.emptyText
    UI.label {
        parent = self.emptyPanel,
        text = text,
        x = (self.emptyPanel.width - textManager:MeasureStringX(self.font, text)) * 0.5,
        y = self.emptyPanel.height * 0.5,
        h = textManager:getFontHeight(self.font),
        font = self.font,
    }

    self:switchToEmptyState()
end

---Returns the index of the currently selected page.
---@return integer
function ObjectArrayPanel:getSelected()
    return self.listbox.selected
end

---Checks whether the control is in the content state.
---@return boolean
function ObjectArrayPanel:isContentState()
    return self.contentPanel:isVisible()
end

---Checks whether the control is in the empty state.
---@return boolean
function ObjectArrayPanel:isEmptyState()
    return self.emptyPanel:isVisible()
end

---Returns whether the control is enabled.
---@return boolean
function ObjectArrayPanel:isEnabled()
    return not self.disabled
end

---Resets the scroll on the content panel.
function ObjectArrayPanel:resetScroll()
    self.contentPanel:setYScroll(0)
end

---Sets whether the control is enabled.
---@param enabled boolean
function ObjectArrayPanel:setEnabled(enabled)
    self.disabled = not enabled
    self.contentPanel._handleScrolling = enabled

    self.coverPanel:bringToTop()
    self.coverPanel:setVisible(self.disabled)

    if not enabled then
        self:resetScroll()
    end
end

---Sets the listbox text for a given index.
---@param index integer
---@param text string
function ObjectArrayPanel:setItemText(index, text)
    local item = self.listbox.items[index]
    if not item then
        return
    end

    text = core.trim(text)

    -- items are drawn with an x pad of 15 (+ 1 for padding)
    local width = textManager:MeasureStringX(self.listbox.font, text) + 16

    item.text = text
    item.tooltip = width >= self.listbox.width and text or nil
end

---Sets the callback to call when the Add button is clicked.
---@param target any?
---@param callback forms.Callback.ObjectArrayPanel.Item?
---@param ...any
function ObjectArrayPanel:setOnAdd(target, callback, ...)
    self.callbacks.add = core.callback(target, callback, ...)
end

---Sets the callback to call when the Delete button is clicked.
---@param target any?
---@param callback forms.Callback.ObjectArrayPanel.Item?
---@param ...any
function ObjectArrayPanel:setOnDelete(target, callback, ...)
    self.callbacks.delete = core.callback(target, callback, ...)
end

---Sets the callback to call when listbox items are reordered.
---@param target any?
---@param callback forms.Callback.ObjectArrayPanel.Move?
---@param ...any
function ObjectArrayPanel:setOnMove(target, callback, ...)
    self.callbacks.move = core.callback(target, callback, ...)
end

---Sets the callback to call when a listbox selection is made.
---@param target any?
---@param callback forms.Callback.ObjectArrayPanel.Item?
---@param ...any
function ObjectArrayPanel:setOnSelect(target, callback, ...)
    self.callbacks.select = core.callback(target, callback, ...)
end

---Sets the page in the listbox that should be selected.
---@param selected integer
function ObjectArrayPanel:setSelected(selected)
    self.listbox.selected = selected
end

---Switches the control state to show the content state.
function ObjectArrayPanel:switchToContentState()
    self.emptyPanel:setVisible(false)
    self.contentPanel:setVisible(true)
end

---Switches the control state to show the empty state.
function ObjectArrayPanel:switchToEmptyState()
    self.emptyPanel:setVisible(true)
    self.contentPanel:setVisible(false)
end

---Switches the current page of the control to the selected index in the listbox.
function ObjectArrayPanel:switchPage()
    local selected = self.listbox.selected
    if selected < 1 or selected > #self.listbox.items then
        self:switchToEmptyState()
        return
    end

    self:switchToContentState()
    self:resetScroll()
    core.callback.invoke(self.callbacks.select, selected)
end

---Called every 100ms when the panel is visible.
function ObjectArrayPanel:update()
    local nItems = #self.listbox.items

    if self.maxItems then
        local canAdd = nItems < self.maxItems
        self.addBtn:setEnable(canAdd)
        self.addBtn.tooltip = not canAdd and self.maxTooltip or self.addTooltip
    end

    self.deleteBtn:setEnable(nItems > 0)
    self.moveUpBtn:setEnable(nItems > 0 and self.listbox.selected > 1)
    self.moveDownBtn:setEnable(nItems > 0 and self.listbox.selected < nItems)
end


---Creates a panel for the content or empty state.
---@return Panel
---@protected
function ObjectArrayPanel:_createPanel()
    return UI.panel {
        parent = self,
        x = self.listbox:getRight() + 10,
        w = self.width - self.listbox.width - 10,
        h = self.height,
        handleScrolling = true,
        visible = false,
        addVerticalScrollbar = true,
    }
end

---Called when the Add button is clicked.
---@protected
function ObjectArrayPanel:_onClickAdd()
    if self.maxItems and #self.listbox.items >= self.maxItems then
        return
    end

    core.callback.invoke(self.callbacks.add)
end

---Called when the Delete button is clicked.
---@protected
function ObjectArrayPanel:_onClickDelete()
    if #self.listbox.items == 0 then
        return
    end

    core.callback.invoke(self.callbacks.delete, self.listbox.selected)
end

---Called when the Move Up button is clicked.
---@protected
function ObjectArrayPanel:_onClickMoveUp()
    local selected = self.listbox.selected
    local items = self.listbox.items
    if #items == 0 or selected <= 1 then
        return
    end

    core.callback.invoke(self.callbacks.move, selected - 1, selected)
end

---Called when the Move Down button is clicked.
---@protected
function ObjectArrayPanel:_onClickMoveDown()
    local selected = self.listbox.selected
    local items = self.listbox.items
    if #items == 0 or selected >= #items then
        return
    end

    core.callback.invoke(self.callbacks.move, selected + 1, selected)
end


---Creates a new object array panel.
---@param args Args.ObjectArrayPanel
---@return forms.ObjectArrayPanel
function ObjectArrayPanel:new(args)
    local this = UI.new(self, Panel.new, args)

    this.init = {
        itemPadY = args.itemPadY,
        emptyText = args.emptyText or getText('OmiLibrary.form-empty'),
    }

    this.disabled = false
    this.background = false
    this.maxItems = args.maxItems
    this.addTooltip = args.addTooltip
    this.deleteTooltip = args.deleteTooltip
    this.moveUpTooltip = args.moveUpTooltip
    this.moveDownTooltip = args.moveDownTooltip
    this.font = args.font or UIFont.Medium
    this.callbacks = {}

    if this.maxItems then
        this.maxTooltip = getText('@error.max-items-reached', { max = this.maxItems })
    end

    this:setOnAdd(args.onAddTarget or args.target, args.onAdd, unpack(args.onAddArgs or {}))
    this:setOnDelete(args.onDeleteTarget or args.target, args.onDelete, unpack(args.onDeleteArgs or {}))
    this:setOnSelect(args.onSelectTarget or args.target, args.onSelect, unpack(args.onSelectArgs or {}))
    this:setOnMove(args.onMoveTarget or args.target, args.onMove, unpack(args.onMoveArgs or {}))

    return this
end


return ObjectArrayPanel

--#region Type Definitions

---@class Args.ObjectArrayPanel : Args.Panel
---@field font? UIFont The font to use for controls. Defaults to `UIFont.Medium`.
---@field itemPadY? number The vertical padding in each item before the text is drawn.
---@field emptyText? string The text to display when the control has no items.
---@field addTooltip? string The tooltip to display for the add button.
---@field deleteTooltip? string The tooltip to display for the delete button.
---@field moveUpTooltip? string The tooltip to display for the move up button.
---@field moveDownTooltip? string The tooltip to display for the move down button.
---@field maxItems? integer The maximum number of items in the array.
---@field onAdd? forms.Callback.ObjectArrayPanel.Add Invoked when the Add button is clicked.
---@field onAddArgs? table Arguments for `onAdd`.
---@field onAddTarget? any The first argument to pass to the `onAdd` callback.
---@field onDelete? forms.Callback.ObjectArrayPanel.Item Invoked when the Delete button is clicked.
---@field onDeleteArgs? table Arguments for `onDelete`.
---@field onDeleteTarget? any The first argument to pass to the `onDelete` callback.
---@field onMove? forms.Callback.ObjectArrayPanel.Move Invoked when an item is moved up or down.
---@field onMoveArgs? table Arguments for `onMove`.
---@field onMoveTarget? any The first argument to pass to the `onMove` callback.
---@field onSelect? forms.Callback.ObjectArrayPanel.Item Invoked when an item is selected.
---@field onSelectArgs? table Arguments for `onSelect`.
---@field onSelectTarget? any The first argument to pass to the `onSelect` callback.
---@field target? any The default first argument to use for callbacks when a target is unspecified.


---@class forms.ObjectArrayPanel.Callbacks
---@field add? CallbackInfo Invoked when the Add button is clicked.
---@field delete? CallbackInfo Invoked when the Delete button is clicked.
---@field move? CallbackInfo Invoked when items are reordered.
---@field select? CallbackInfo Invoked when an item is selected.

---@class forms.ObjectArrayPanel.Init
---@field itemPadY? number The vertical padding in each item before the text is drawn.
---@field emptyText string The text to display when the control has no items.


---@alias forms.Callback.ObjectArrayPanel.Add fun(target: any, ...: any)

---@alias forms.Callback.ObjectArrayPanel.Item fun(target: any, selected: integer, ...: any)

---@alias forms.Callback.ObjectArrayPanel.Move fun(target: any, selected: integer, prevIndex: integer, ...: any)

--#endregion
