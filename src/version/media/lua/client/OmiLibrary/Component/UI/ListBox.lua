---UI element for a scrolling listbox.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/Core/UI'

local ISScrollingListBox = ISScrollingListBox
local textManager = getTextManager()
local soundManager = getSoundManager()

local FONT_SMALL = UIFont.Small
local FONT_HGT_SMALL = textManager:getFontHeight(FONT_SMALL)
local ScrollBar_onMouseDown = ISScrollBar.onMouseDown


---@class ListBox : ISScrollingListBox, BaseUI
---@field font UIFont The font to use for the text.
---@field itemPadY number The vertical padding in each item before the text is drawn.
---@field drawBorder boolean Whether a border should be rendered.
---@field doRepaintStencil boolean If `true`, the stencil rect will be repainted after rendering.
---@field selected integer The selected item.
---@field hoverSelection boolean If `true`, selection will be based on hovering instead of clicking.
---@field ignoreClicks boolean If `true`, click events will be ignored.
---@field ignoreClickCurrentSelection boolean If `true`, clicks on the currently selected item will be ignored.
---@field backgroundColor ColorTableRGBA<number> The color to use for the background.
---@field borderColor ColorTableRGBA<number> The color to use for the border.
---@field borderColorDisabled ColorTableRGBA<number> The color to use for the border when the listbox is disabled.
---@field textColor ColorTableRGBA<number> The color to use for the listbox.
---@field textColorDisabled ColorTableRGBA<number> The color to use when the listbox is disabled.
---@field selectionColor? ColorTableRGBA<number> The color to use for the selected listbox row.
---@field mouseOverHighlightColor? ColorTableRGBA<number> The color to use for the hovered listbox row.
---@field altBgColor? ColorTableRGBA<number> The color to use for the background of items with even indices.
---@field joypadParent? ISUIElement An element to set focus to when the `B` joypad button is pressed.
---@field items ListBoxItem[] The list of items in the listbox.
---@field protected callbacks ListBox.Callbacks Container for callbacks.
---@field protected disabled boolean Whether the listbox is currently disabled.
---@field protected __base ISScrollingListBox The base class.
local ListBox = UI.class('OmiListBox', ISScrollingListBox)


---Adds an item to the listbox.
---@param name string
---@param item any?
---@return ListBoxItem
function ListBox:addItem(name, item)
    return ISScrollingListBox.addItem(self, name, item) --[[@as ListBoxItem]]
end

---Override to fix scrollbars consuming clicks inappropriately.
function ListBox:addScrollBars(addHorizontal)
    ISScrollingListBox.addScrollBars(self, addHorizontal)

    if self.vscroll then
        self.vscroll.onMouseDown = self._onScrollBarMouseDown --[[@as function]]
    end
end

---Default handler for drawing listbox items.
---@param y number
---@param item ListBoxItem
---@param alt boolean
---@return number
---@diagnostic disable-next-line: unused
function ListBox:defaultDrawItem(y, item, alt)
    if not item.height then
        item.height = self.itemheight
    end

    local w = self:getWidth()
    if self.selected == item.index then
        self:drawSelection(0, y, w, item.height - 1)
    elseif not self.hoverSelection and (self.mouseoverselected == item.index) and self:isMouseOver() and not self:isMouseOverScrollBar() then
        self:drawMouseOverHighlight(0, y, w, item.height - 1)
    end

    local borderColor = self.disabled and self.borderColorDisabled or self.borderColor
    self:drawRectBorder(0, y, w, item.height, 0.5, borderColor.r, borderColor.g, borderColor.b)

    local textColor
    if self.disabled then
        textColor = item.textColorDisabled or self.textColorDisabled
    else
        textColor = item.textColor or self.textColor
    end

    local x = 15.0
    local itemPadY = self.itemPadY or (item.height - self.fontHgt) * 0.5
    if item.texture then
        x = 12
        local size = item.height * 0.6
        local pad = (item.height - size) * 0.5
        local itemColor = self.disabled and item.textureColorDisabled or item.textureColor
        local color = itemColor or { r = 1, g = 1, b = 1, a = 1 }

        self:drawTextureScaled(item.texture, x, y + pad, size, size, color.a, color.r, color.g, color.b)

        x = x + size + pad + 3
    end

    self:drawText(item.text, x, y + itemPadY, textColor.r, textColor.g, textColor.b, textColor.a, self.font)

    y = y + item.height
    return y
end

---Default handler for drawing the highlight for the selected row.
---@param x number
---@param y number
---@param w number
---@param h number
function ListBox:drawSelection(x, y, w, h)
    local c = self.selectionColor
    if c then
        self:drawRect(x, y, w, h, c.a, c.r, c.g, c.b)
    end
end

---Default handler for drawing the highlight for the hovered row.
---@param x number
---@param y number
---@param w number
---@param h number
function ListBox:drawMouseOverHighlight(x, y, w, h)
    local c = self.mouseOverHighlightColor
    if c then
        self:drawRect(x, y, w, h, c.a, c.r, c.g, c.b)
    end
end

---Draws a single listbox item.
---@param y number
---@param item ListBoxItem
---@param alt boolean
---@return number
function ListBox:doDrawItem(y, item, alt)
    if self.callbacks.draw then
        return core.callback.invoke(self.callbacks.draw, y, item, alt, self)
    end

    return self:defaultDrawItem(y, item, alt)
end

---Returns the number of items in the listbox.
---@return integer
function ListBox:getItemCount()
    return #self.items
end

---Gets the currently selected item.
---@return any | nil
function ListBox:getSelectedItem()
    local selected = self.selected and self.items[self.selected]
    if not selected then
        return
    end

    return selected.item
end

---Called when the mouse button is double-clicked over the element.
---@param x number
---@param y number
function ListBox:onMouseDoubleClick(x, y)
    if self.disabled or self.ignoreClicks then
        return
    end

    ISScrollingListBox.onMouseDoubleClick(self, x, y)
end

---Called when the mouse button is pressed down over the element.
---@param x number
---@param y number
function ListBox:onMouseDown(x, y)
    if self.disabled or self.ignoreClicks or #self.items == 0 then
        return
    end

    local row = self:rowAt(x, y)
    if row == -1 then
        return
    end

    row = core.clamp(row, 1, #self.items)
    if self.ignoreClickCurrentSelection and row == self.selected then
        return
    end

    if not self.hoverSelection then
        soundManager:playUISound('UISelectListItem')
        self.selected = row
    end

    local item = self.items[row]
    if self.onmousedown and item then
        self.onmousedown(self.target, item.item)
    end
end

---Called when the mouse moves over the listbox.
---@param dx number
---@param dy number
function ListBox:onMouseMove(dx, dy)
    if self.disabled then
        return
    end

    ISScrollingListBox.onMouseMove(self, dx, dy)

    local hovering = self.mouseoverselected
    if self.hoverSelection and hovering and hovering ~= -1 then
        self.selected = hovering
    end
end

---Called when the mouse is scrolled over the listbox.
---@param del number
function ListBox:onMouseWheel(del)
    if self.disabled or not self:isVScrollBarVisible() then
        return false
    end

    return ISScrollingListBox.onMouseWheel(self, del)
end

---Handles prerendering for the listbox.
---Modified code from `ISScrollingListBox`.
function ListBox:prerender()
    if not self.items then
        return
    end

    local stencilX = 0.0
    local stencilY = 0.0
    local stencilX2 = self.width
    local stencilY2 = self.height

    local bgColor = self.backgroundColor
    self:drawRect(0, -self:getYScroll(), self.width, self.height, bgColor.a, bgColor.r, bgColor.g, bgColor.b)
    if self.drawBorder then
        local bColor = self.disabled and self.borderColorDisabled or self.borderColor
        self:drawRectBorder(0, -self:getYScroll(), self.width, self.height, bColor.a, bColor.r, bColor.g, bColor.b)
        stencilX = 1
        stencilY = 1
        stencilX2 = self.width - 1
        stencilY2 = self.height - 1
    end

    if self:isVScrollBarVisible() and self.vscroll then
        stencilX2 = self.vscroll.x + 3
    end

    stencilX, stencilY, stencilX2, stencilY2 = self:clampStencilRectToParent(stencilX, stencilY, stencilX2, stencilY2)

    if self.selected ~= -1 and self.selected > #self.items then
        self.selected = #self.items
    end

    local y = 0.0
    local alt = false
    local altBg = self.altBgColor
    self.listHeight = 0.0
    for i = 1, #self.items do
        local v = self.items[i]
        if not v.height then
            v.height = self.itemheight
        end

        if alt and altBg then
            self:drawRect(0, y, self:getWidth(), v.height - 1, altBg.r, altBg.g, altBg.b, altBg.a)
        end

        v.index = i
        local y2 = self:doDrawItem(y, v, alt)
        self.listHeight = y2
        v.height = y2 - y
        y = y2

        alt = not alt
    end

    self:setScrollHeight(y)
    self:clearStencilRect()
    if self.doRepaintStencil then
        self:repaintStencilRect(stencilX, stencilY, stencilX2, stencilY2)
    end

    local mouseY = self:getMouseY()
    self:updateSmoothScrolling()

    local newMouseY = self:getMouseY()
    if mouseY ~= newMouseY and self:isMouseOver() then
        self:onMouseMove(0, newMouseY - mouseY)
    end

    self:updateTooltip()

    if #self.columns > 0 then
        self:drawRectBorderStatic(0, 0 - self.itemheight, self.width, self.itemheight - 1, 1, self.borderColor.r,
            self.borderColor.g, self.borderColor.b)
        self:drawRectStatic(0, 0 - self.itemheight - 1, self.width, self.itemheight - 2, self.listHeaderColor.a,
            self.listHeaderColor.r, self.listHeaderColor.g, self.listHeaderColor.b)

        local dyText = (self.itemheight - FONT_HGT_SMALL) / 2
        for i = 1, #self.columns do
            local v = self.columns[i]
            self:drawRectStatic(v.size, 0 - self.itemheight, 1,
                self.itemheight + math.min(self.height, self.itemheight * #self.items - 1), 1, self.borderColor.r,
                self.borderColor.g, self.borderColor.b)
            if v.name then
                self:drawText(v.name, v.size + 10, 0 - self.itemheight - 1 + dyText - self:getYScroll(), 1, 1, 1, 1,
                    FONT_SMALL)
            end
        end
    end
end

---Selects the next item in the list.
function ListBox:selectNext()
    local selected = self.selected + 1
    if selected < 1 or selected > #self.items then
        selected = 1
    end

    self.selected = selected
    self:ensureVisible(selected)
end

---Selects the previous item in the list.
function ListBox:selectPrevious()
    local selected = self.selected - 1
    if selected < 1 or selected > #self.items then
        selected = #self.items
    end

    self.selected = selected
    self:ensureVisible(selected)
end

---Sets the enable state of the listbox.
---@param enabled boolean
function ListBox:setEnabled(enabled)
    self.disabled = not enabled
end

---Sets the font of the listbox.
---@param font UIFont
---@param padY number?
function ListBox:setFont(font, padY)
    ISScrollingListBox.setFont(self, font, padY or self.itemPadY)
end

---Sets a callback to be invoked when a list item is double clicked.
---@param target any?
---@param callback Callback.ListBox.Click?
---@param ...any
function ListBox:setOnDoubleClick(target, callback, ...)
    self.callbacks.doubleClick = core.callback(target, callback, ...)
end

---Sets the function used to draw listbox items.
---@param target any?
---@param callback Callback.ListBox.Draw?
---@param ...any
function ListBox:setOnDraw(target, callback, ...)
    self.callbacks.draw = core.callback(target, callback, ...)
end

---@deprecated Use `setOnDoubleClick`.
function ListBox:setOnMouseDoubleClick(target, callback, ...)
    self:setOnDoubleClick(target, callback, ...)
end

---Sets a callback to be invoked when the mouse button is pressed on a list item.
---@param target any?
---@param callback Callback.ListBox.Click?
---@param ...any
function ListBox:setOnMouseDown(target, callback, ...)
    self.callbacks.mouseDown = core.callback(target, callback, ...)
end

---@deprecated Use `setOnMouseDown`.
function ListBox:setOnMouseDownFunction(target, callback, ...)
    self:setOnMouseDown(target, callback, ...)
end


---Triggered when a list item is double clicked.
---@param item any?
---@protected
function ListBox:_onDoubleClick(item)
    core.callback.invoke(self.callbacks.doubleClick, item, self.selected, self)
end

---Triggered when the mouse is pressed on a scroll bar.
---@param scrollbar ISScrollBar
---@param x number
---@param y number
---@protected
function ListBox._onScrollBarMouseDown(scrollbar, x, y)
    local parent = scrollbar:getParent()
    if not parent or not parent:isVScrollBarVisible() then
        return false
    end

    return ScrollBar_onMouseDown(scrollbar, x, y)
end

---Triggered when the mouse button is pressed on a list item.
---@param item any?
---@protected
function ListBox:_onMouseDown(item)
    core.callback.invoke(self.callbacks.mouseDown, item, self.selected, self)
end


---Creates a new listbox.
---@param args Args.ListBox
---@return ListBox
function ListBox:new(args)
    local x = args.x or 0
    local y = args.y or 0
    local h = args.h or 0
    local w = args.w or 0

    local this = UI.new(self, ListBox.__base.new, x, y, w, h)
    this:_setBaseArgs(args)

    this.disabled = false
    this.keepOnScreen = false
    this.doRepaintStencil = args.repaintStencil or false
    this.altBgColor = args.altBackgroundColor or this.altBgColor
    this.backgroundColor = args.backgroundColor or this.backgroundColor
    this.borderColor = args.borderColor or this.borderColor
    this.borderColorDisabled = core.color.defaultRGBA(args.borderColorDisabled, 0.4, 0.4, 0.4, 0.5)
    this.textColor = core.color.defaultRGBA(args.textColor, 0.9, 0.9, 0.9, 0.9)
    this.textColorDisabled = core.color.defaultRGBA(args.textColorDisabled, 0.5, 0.5, 0.5, this.textColor.a)
    this.selectionColor = core.color.defaultRGBA(args.selectionColor or this.selectionColor, 0.7, 0.35, 0.15, 0.3)
    this.mouseOverHighlightColor = core.color.defaultRGBA(args.hoverColor, 1, 1, 1, 0.1)

    this.drawBorder = args.drawBorder or false
    this.selected = args.selected or 1
    this.hoverSelection = args.hoverSelection or false
    this.ignoreClickCurrentSelection = args.ignoreClickCurrentSelection or false
    this.ignoreClicks = core.default(args.ignoreClicks, this.hoverSelection)
    this.joypadParent = args.joypadParent
    this:setFont(args.font or UIFont.Large, args.itemPadY)

    this.callbacks = {}

    local defaultTarget = args.target or (args.targetSelf and this or nil)
    local drawTarget = args.drawTarget or defaultTarget
    local dbClickTarget = args.onDoubleClickTarget or defaultTarget
    local mouseDownTarget = args.onMouseDownTarget or defaultTarget
    this.target = this
    this.onmousedown = this._onMouseDown
    this.onmousedblclick = this._onDoubleClick
    this:setOnDraw(drawTarget, args.draw, unpack(args.drawArgs or {}))
    this:setOnMouseDown(mouseDownTarget, args.onMouseDown, unpack(args.onMouseDownArgs or {}))
    this:setOnDoubleClick(dbClickTarget, args.onDoubleClick, unpack(args.onDoubleClickArgs or {}))

    return this
end


return ListBox

--#region Type Definitions

---@class Args.ListBox : Args.BaseUI
---@field font? UIFont The font to use for the text.
---@field itemPadY? number The vertical padding in each item before the text is drawn.
---@field drawBorder? boolean Whether a border should be rendered.
---@field repaintStencil? boolean If `true`, the stencil rect will be repainted after rendering.
---@field selected? integer The listbox item that should initially be selected.
---@field hoverSelection? boolean If `true`, selection will be based on hovering instead of clicking.
---@field ignoreClickCurrentSelection? boolean If `true`, clicks on the currently selected item will be ignored.
---@field ignoreClicks? boolean If `true`, click events will be ignored. Defaults to `false`, or `true` if `hoverSelection` is `true`.
---@field altBackgroundColor? ColorTableRGBA<number> The color to use for the background of items with even indices.
---@field borderColor? ColorTableRGBA<number> The color to use for the border.
---@field borderColorDisabled? ColorTableRGBA<number> The color to use for the border when the listbox is disabled.
---@field textColor? ColorTableRGBA<number> The color to use for the listbox.
---@field textColorDisabled? ColorTableRGBA<number> The color to use when the listbox is disabled.
---@field selectionColor? ColorTableRGBA<number> The color to use for the selected listbox row.
---@field hoverColor? ColorTableRGBA<number> The color to use for the hovered listbox row.
---@field backgroundColor? ColorTableRGBA<number> The color to use for the background.
---@field joypadParent? ISUIElement An element to set focus to when the `B` joypad button is pressed.
---@field draw? Callback.ListBox.Draw Invoked to draw a listbox item.
---@field drawArgs? table Arguments for `draw`.
---@field drawTarget? any The first argument to pass to the `draw` callback.
---@field onDoubleClick? Callback.ListBox.Click Invoked when a listbox item is double-clicked.
---@field onDoubleClickArgs? table Arguments for `onDoubleClick`.
---@field onDoubleClickTarget? any The first argument to pass to the `onDoubleClick` callback.
---@field onMouseDown? Callback.ListBox.Click Invoked when the mouse is pressed on a listbox item.
---@field onMouseDownArgs? table Arguments for `onMouseDown`.
---@field onMouseDownTarget? any The first argument to pass to the `onMouseDown` callback.
---@field target? any The default first argument to use for callbacks when a target is unspecified.
---@field targetSelf? boolean Flag for whether the default first argument for callbacks should be the created instance.

---@class InitArgs.ListBox : Args.ListBox, InitArgs.Shared
---@field items? (string | InitArgs.ListBoxItem)[] Items to include in the listbox.

---@class InitArgs.ListBoxItem
---@field text string The text to display in the listbox item.
---@field texture? Texture The texture to display in the listbox item.
---@field textureColor? ColorTableRGBA<number> The color to use for the listbox item's texture.
---@field textureColorDisabled? ColorTableRGBA<number> The color to use for the listbox item's texture when the listbox is disabled.
---@field item? any Data associated with the listbox item.
---@field tooltip? string The tooltip to display when the listbox item is hovered.
---@field textColor? ColorTableRGBA<number> The text color to use for the listbox item.
---@field textColorDisabled? ColorTableRGBA<number> The text color to use for the listbox item when the listbox is disabled.


---@class ListBox.Callbacks
---@field draw? CallbackInfo Invoked to draw a listbox item.
---@field doubleClick? CallbackInfo Invoked when a listbox item is double-clicked.
---@field mouseDown? CallbackInfo Invoked when the mouse is pressed on a listbox item.

---@class ListBoxItem : InitArgs.ListBoxItem, umbrella.ISScrollingListBox.Item
---@field index? integer The index of the item in the listbox.
---@field itemindex integer The index of the item in the listbox.
---@field height number The height of the item.


---@alias Callback.ListBox.Click fun(target: any?, item: any?, selected: number, listbox: ListBox, ...: any)

---@alias Callback.ListBox.Draw fun(target: any?, y: number, item: any, alt: boolean, listbox: ListBox, ...: any): number

--#endregion
