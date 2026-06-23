---Entry for list input.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/UI/Core'
local Panel = require 'OmiLibrary/Component/UI/Panel'

local min = math.min
local textManager = getTextManager()


---@class ListEntry : Panel
---@field entry TextEntry The text entry for entering new elements.
---@field listbox ListBox The listbox containing current elements.
---@field addBtn Button The button used to add entries to the list.
---@field addBtnTexture Texture The texture to use for the entry add button.
---@field deleteBtnTexture Texture The texture to use for the delete button.
---@field upBtnTexture Texture The texture to use for the up button.
---@field downBtnTexture Texture The texture to use for the down button.
---@field protected disabled boolean Whether the entry is currently disabled.
---@field protected init ListEntry.Init Information used only during initialization.
---@field protected callbacks ListEntry.Callbacks Callbacks for the entry.
---@field protected includeReorderButtons boolean If `true`, buttons to reorder list elements will be included.
---@field protected deleteBtnTransition UITransition Transition used for the delete button.
---@field protected upBtnTransition UITransition Transition used for the move up button.
---@field protected downBtnTransition UITransition Transition used for the move down button.
---@field protected __base Panel The base class.
local ListEntry = Panel:derive('OmiListEntry')


---Determines the height to set based on the number of items that should be visible.
---@param visibleItems number
---@param font UIFont?
---@param itemPadY number?
---@param entryHeight number?
---@return number
function ListEntry.calculateHeight(visibleItems, font, itemPadY, entryHeight)
    local fontHgt = textManager:getFontHeight(font or UIFont.Medium)
    local itemHeight = fontHgt + (itemPadY or 4) * 2

    entryHeight = entryHeight or (fontHgt + 4)

    return itemHeight * visibleItems + entryHeight + 4
end

---Creates the children of the entry element.
function ListEntry:createChildren()
    local entryArgs = self.init.textEntry
    local fontHgt = textManager:getFontHeight(entryArgs.font or UIFont.Medium)

    -- use same button size/position as `ColorEntry` for add button
    local btnSize = entryArgs.h or (fontHgt + 4)
    local btnPadding = 5 * (fontHgt / textManager:getFontHeight(UIFont.Medium))

    entryArgs = self:_getEntryArgs(btnSize, btnPadding)
    self:_createTextEntries(entryArgs)

    self.addBtn = UI.button {
        parent = self,
        x = self.entry:getRight() + 4,
        w = btnSize,
        h = self.entry:getHeight(),
        font = entryArgs.font,
        image = self.addBtnTexture,
        internal = 'ADD',
        anchorRight = false,
        borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 },
        target = self,
        onClick = self._onClickAdd,
    }

    local listboxY = self.entry:getBottom() + 4
    self.listbox = UI.listBox {
        parent = self,
        y = listboxY,
        w = self.width,
        h = self.height - listboxY,
        itemPadY = self.init.itemPadY,
        drawBorder = true,
        addVerticalScrollbar = true,
        font = entryArgs.font,
        items = self.init.items,
        anchorRight = true,
        anchorBottom = true,
        hoverSelection = true,
        repaintStencil = true,
        ignoreClicks = false,
        target = self,
        draw = self._drawListboxItem,
        onMouseDown = self._onClickItem,
    }
end

---Gets the list value of the entry.
---@return any[]
function ListEntry:getValue()
    local values = {}

    for i = 1, #self.listbox.items do
        local item = self.listbox.items[i]
        values[#values + 1] = item.item
    end

    return values
end

---Returns whether the element has buttons for reordering items.
---@return boolean
function ListEntry:hasReorderButtons()
    return self.includeReorderButtons
end

---Sets whether the list entry is currently enabled.
---@param enabled boolean
function ListEntry:setEnabled(enabled)
    self.disabled = not enabled

    self.addBtn.enable = enabled
    self.entry:setEnabled(enabled)
    self.listbox:setEnabled(enabled)
end

---Sets whether the element has buttons for reordering items.
---@param hasButtons boolean
function ListEntry:setHasReorderButtons(hasButtons)
    self.includeReorderButtons = hasButtons
end

---Sets a callback function to be called for creating a new item.
---@param target any?
---@param callback Callback.ListEntry.Add?
---@param ...any?
function ListEntry:setOnAdd(target, callback, ...)
    self.callbacks.add = core.callback(target, callback, ...)
end

---Sets a callback function to be called when the list changes.
---@param target any?
---@param callback Callback.ListEntry.Change?
---@param ...any?
function ListEntry:setOnChange(target, callback, ...)
    self.callbacks.change = core.callback(target, callback, ...)
end

---Sets the value of the entry.
---The values will be used as both the text and the item for the listbox items.
---@param value any[]? The new value for the list entry.
---@param notify boolean? If `true`, this will trigger the change callback.
function ListEntry:setValue(value, notify)
    value = value or {}
    local listbox = self.listbox
    listbox:clear()

    for i = 1, #value do
        local item = value[i]
        listbox:addItem(tostring(item), item)
    end

    if notify then
        core.callback.invoke(self.callbacks.change, self)
    end
end

---Called every 100ms while the list entry is visible.
---Updates the enable state of the add button.
function ListEntry:update()
    self.addBtn:setEnable(self.entry:isValid())
end


---Adds the current value to the entry.
---@protected
function ListEntry:_add()
    local info = self:_getItemArgs()
    if info then
        self:_addToListbox(info)
    end
end

---Adds an item to the listbox.
---@param itemInfo InitArgs.ListBoxItem
---@return ListBoxItem
---@protected
function ListEntry:_addToListbox(itemInfo)
    local item = self.listbox:addItem(itemInfo.text, itemInfo.text)
    item.tooltip = itemInfo.tooltip
    item.textColor = itemInfo.textColor
    item.textColorDisabled = itemInfo.textColorDisabled
    item.texture = itemInfo.texture
    item.textureColor = itemInfo.textureColor
    item.textureColorDisabled = itemInfo.textureColorDisabled

    return item
end

---Checks whether the state is valid for adding to the list.
---@return boolean
---@protected
function ListEntry:_canAdd()
    return self:_isEntryValid(self.entry)
end

---Clears text entries.
---@protected
function ListEntry:_clearTextEntries()
    self.entry:clear()
end

---Called to create text entries.
---@param entryArgs InitArgs.TextEntry
---@protected
function ListEntry:_createTextEntries(entryArgs)
    self.entry = UI.textEntry(entryArgs)
end

---Draws a button on a listbox item.
---@param texture Texture
---@param x number
---@param y number
---@param h number
---@param isHovered boolean
---@param transition UITransition
---@return number
---@protected
function ListEntry:_drawListboxButton(texture, x, y, h, isHovered, transition)
    local btnX = x - 8 - texture:getWidth()
    local btnY = y + (h - texture:getHeight()) * 0.5
    local alpha = isHovered and 1 or 0.5

    transition:setFadeIn(isHovered)
    transition:update()

    local frac = transition:fraction()
    self.listbox:drawTexture(texture, btnX, btnY, alpha * frac + 0.35 * (1 - frac))

    return btnX
end

---Handles drawing listbox items and hover buttons.
---@param y number
---@param item ListBoxItem
---@param alt boolean
---@return number?
---@protected
function ListEntry:_drawListboxItem(y, item, alt)
    local listbox = self.listbox
    local newY = listbox:defaultDrawItem(y, item, alt)

    if self.disabled or item.index ~= listbox.mouseoverselected or not listbox:isMouseOver() then
        return newY
    end

    local hoverBtn = self:_getHoveringButton()

    ---@cast listbox.vscroll -?
    local h = item.height
    local x = self:_drawListboxButton(
        self.deleteBtnTexture,
        listbox.width - (listbox:isVScrollBarVisible() and listbox.vscroll.width or 0),
        y,
        h,
        hoverBtn == 'DELETE',
        self.deleteBtnTransition
    )

    if not self.includeReorderButtons then
        return newY
    end

    x = x - 4
    if item.index < #listbox.items then
        x = self:_drawListboxButton(
            self.downBtnTexture,
            x,
            y,
            h,
            hoverBtn == 'DOWN',
            self.downBtnTransition
        )
    end

    if item.index > 1 then
        x = self:_drawListboxButton(
            self.upBtnTexture,
            x,
            y,
            h,
            hoverBtn == 'UP',
            self.upBtnTransition
        )
    end

    return newY
end

---Gets the arguments to use for creating the entry.
---@param btnSize number
---@param btnPadding number
---@return InitArgs.TextEntry
function ListEntry:_getEntryArgs(btnSize, btnPadding)
    local entryArgs = self.init.textEntry

    local entryW = entryArgs.w or self.width
    if self.init.maxEntryWidth then
        entryW = min(entryW, self.init.maxEntryWidth)
    end

    entryArgs.parent = self
    entryArgs.w = entryW - btnSize - btnPadding
    entryArgs.h = btnSize
    entryArgs.anchorRight = false
    entryArgs.onCommandTarget = self
    entryArgs.onCommand = self._onClickAdd

    return entryArgs
end

---Gets the ID of the button being hovered.
---@return string?
---@protected
function ListEntry:_getHoveringButton()
    local listbox = self.listbox
    local hoverIdx = listbox.mouseoverselected
    if not hoverIdx or hoverIdx < 1 then
        return
    end

    ---@cast listbox.vscroll -?
    local x = listbox:getMouseX()
    local listboxW = listbox.width - (listbox:isVScrollBarVisible() and listbox.vscroll.width or 0)
    if x >= listboxW - 4 then
        return
    end

    local nextX = listboxW - self.deleteBtnTexture:getWidth() - 8
    if x >= nextX then
        return 'DELETE'
    end

    if not self.includeReorderButtons then
        return
    end

    nextX = nextX - 4
    if hoverIdx < #listbox.items then
        nextX = nextX - self.downBtnTexture:getWidth() - 8
        if x >= nextX then
            return 'DOWN'
        end
    end

    if hoverIdx > 1 then
        nextX = nextX - self.upBtnTexture:getWidth() - 8
        if x >= nextX then
            return 'UP'
        end
    end
end

---Creates listbox item args based on the current input.
---This assumes the input is valid.
---@return InitArgs.ListBoxItem?
---@protected
function ListEntry:_getItemArgs()
    local text = self.entry:getInternalText():trim()
    local info ---@type (string | InitArgs.ListBoxItem)?
    if self.callbacks.add then
        info = core.callback.invoke(self.callbacks.add, text, self)
        if not info then
            self:_clearTextEntries()
            return
        elseif type(info) == 'string' then
            info = { text = info }
        end
    else
        info = { text = text }
    end

    return info
end

---Checks whether the state is valid for adding to the list.
---@param entry TextEntry? The entry to check. Defaults to the entry field.
---@return boolean
---@protected
function ListEntry:_isEntryValid(entry)
    entry = entry or self.entry
    if not entry:isValid() then
        return false
    end

    if #entry:getInternalText():trim() == 0 then
        entry:clear()
        return false
    end

    return true
end

---Called when the add button is clicked.
---@protected
function ListEntry:_onClickAdd()
    if not self:_canAdd() then
        return
    end

    self:_add()
    core.callback.invoke(self.callbacks.change, self)

    self:_clearTextEntries()
end

---Called when the mouse is pressed on a listbox item.
---@protected
function ListEntry:_onClickItem()
    local listbox = self.listbox
    local hoverIdx = listbox.mouseoverselected
    if not hoverIdx or hoverIdx < 1 or not listbox.items[hoverIdx] then
        return
    end

    local hoverBtn = self:_getHoveringButton()
    if not hoverBtn then
        return
    end

    if hoverBtn == 'DELETE' then
        listbox:removeItemByIndex(hoverIdx)
    else
        local swapIdx = hoverIdx + (hoverBtn == 'UP' and -1 or 1)

        local swapItem = listbox.items[swapIdx]
        if not swapItem then
            return
        end

        listbox.items[swapIdx] = listbox.items[hoverIdx]
        listbox.items[hoverIdx] = swapItem
    end

    core.callback.invoke(self.callbacks.change, self)
end

---Converts a value into a listbox item.
---@param item string | InitArgs.ListBoxItem
---@return InitArgs.ListBoxItem
function ListEntry:_valueToItem(item)
    if type(item) ~= 'table' then
        item = {
            item = item,
            text = tostring(item),
        }
    end

    item.item = item.item or item.text
    return item
end


---Creates a new list entry.
---@param args Args.ListEntry
---@return ListEntry
function ListEntry:new(args)
    local this = UI.new(self, Panel.new, args)
    this:_setScrollArgs(args, { handleScrolling = true })

    local items = core.copyList(args.items)
    for i = 1, #items do
        items[i] = this:_valueToItem(items[i])
    end

    local entryArgs = core.copy(args.textEntry)
    entryArgs.font = entryArgs.font or args.font or UIFont.Medium
    entryArgs.tooltip = entryArgs.tooltip or args.tooltip

    ---@cast items InitArgs.ListBoxItem[]
    this.init = {
        items = items,
        textEntry = entryArgs,
        itemPadY = args.itemPadY or 4,
        maxEntryWidth = args.maxEntryWidth,
    }

    this.disabled = false
    this.background = args.background or false
    this.includeReorderButtons = args.includeReorderButtons ~= false

    this.addBtnTexture = args.addBtnTexture or getTexture('media/ui/Entity/BTN_Plus_Icon_48x48.png')
    this.deleteBtnTexture = args.deleteBtnTexture or getTexture('media/ui/Panel_Icon_Close.png')
    this.upBtnTexture = args.upBtnTexture or getTexture('media/ui/ArrowUp.png')
    this.downBtnTexture = args.downBtnTexture or getTexture('media/ui/ArrowDown.png')

    this.upBtnTransition = UITransition.new()
    this.downBtnTransition = UITransition.new()
    this.deleteBtnTransition = UITransition.new()

    this.callbacks = {}
    local defaultTarget = args.target or (args.targetSelf and this or nil)
    this:setOnAdd(args.addTarget or defaultTarget, args.add, unpack(args.addArgs or {}))
    this:setOnChange(args.onChangeTarget or defaultTarget, args.onChange, unpack(args.onChangeArgs or {}))

    return this
end


return ListEntry

--#region Type Definitions

---@class Args.ListEntry : Args.Panel
---@field font? UIFont The font to use for text. Defaults to Medium.
---@field background? boolean If `true`, a background will be rendered. Defaults to `false`.
---@field tooltip? string The tooltip to set on the text entry.
---@field items? (string | InitArgs.ListBoxItem)[] Initial items to include in the listbox.
---@field includeReorderButtons? boolean If `true`, buttons to reorder list elements will be included. Defaults to `true`.
---@field maxEntryWidth? number The maximum width of the text entry.
---@field addBtnTexture? Texture The texture to use for the entry add button.
---@field deleteBtnTexture? Texture The texture to use for the delete button.
---@field upBtnTexture? Texture The texture to use for the delete button.
---@field downBtnTexture? Texture The texture to use for the delete button.
---@field handleScrolling? boolean If `true`, the panel will scroll its contents when the mouse is scrolled. Defaults to `true`.
---@field itemPadY? number The vertical padding in each item before the text is drawn. Defaults to `4`.
---@field textEntry? Args.TextEntry Arguments for creation of the text entry.
---@field add? Callback.ListEntry.Add Called when adding a new item. Creates an item with the return value.
---@field addArgs? table Arguments for `add`.
---@field addTarget? any The first argument to pass to the `add` callback.
---@field onChange? Callback.ListEntry.Change Invoked when the entry list changes.
---@field onChangeArgs? table Arguments for `change`.
---@field onChangeTarget? any The first argument to pass to the `change` callback.

---@class InitArgs.ListEntry : Args.ListEntry, InitArgs.Shared
---@field visibleItems? integer The maximum number of items that should be visible without scrolling. Defaults to `5`.


---@class ListEntry.Callbacks
---@field add? CallbackInfo Called with the entry text to create a new listbox item.
---@field change? CallbackInfo Invoked when the entry list changes.

---@class ListEntry.Init
---@field textEntry InitArgs.TextEntry Arguments for creation of the text entry.
---@field maxEntryWidth? number The maximum width of the text entry.
---@field items? InitArgs.ListBoxItem[] Items to include in the listbox.
---@field itemPadY? number The vertical padding in each item before the text is drawn.


---@alias Callback.ListEntry.Add fun(target: any?, text: string, entry: ListEntry): (string | InitArgs.ListBoxItem)?

---@alias Callback.ListEntry.Change fun(target: any?, entry: ListEntry)

--#endregion
