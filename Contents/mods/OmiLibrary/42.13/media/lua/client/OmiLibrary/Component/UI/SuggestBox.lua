---UI element for an auto-suggest box.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/UI/Core'
local ListBox = require 'OmiLibrary/Component/UI/ListBox'


local min = math.min
local getTimestampMs = getTimestampMs
local gameCore = getCore()


---@class SuggestBox : ListBox
---@field visibleItems integer The maximum number of items that should be visible without scrolling.
---@field openUpwards boolean If `true`, the suggest box will appear on top of the entry.
---@field suggestOnTab boolean If `true`, the suggest box will treat a `Tab` press on an associated entry as a click.
---@field suggestOnEnter boolean If `true`, the suggest box will treat an `Enter` press on an associated entry as a click.
---@field keyNavigation boolean If `false`, the suggest box won't change the selection when `Up` or `Down` is pressed.
---@field refocusOverScrollbar boolean If `true`, the suggest box will refocus its entry when focus is lost while the mouse is over its scrollbar.
---@field populateAfterInsert boolean If `true`, the suggest box will attempt to populate suggestions immediately after inserting a suggestion.
---@field delay integer The delay in milliseconds to wait between calls to the populate callback.
---@field protected callbacks SuggestBox.Callbacks Container for callbacks.
---@field protected entry? TextEntry The entry associated with the suggest box.
---@field protected nextPopulateTime? number The time at which populating should be allowed again.
---@field protected awaitingPopulate boolean If `true`, the suggest box should call the populate callback when the delay timer is passed.
---@field protected __base ListBox The base class.
local SuggestBox = ListBox:derive('OmiSuggestBox')


---Default handler for clicking a suggestion item.
---@param item SuggestBox.Suggestion
function SuggestBox:defaultOnMouseDown(item)
    if not self:insertSuggestion(item) then
        return
    end

    -- refocus the entry
    if self.entry and not self.entry:isFocused() then
        self.entry:focus()
    end
end

---Returns the entry associated with the suggest box.
---@return TextEntry?
function SuggestBox:getEntry()
    return self.entry
end

---Gets the currently selected item.
---@return SuggestBox.Suggestion?
function SuggestBox:getSelectedItem()
    return ListBox.getSelectedItem(self)
end

---Inserts the currently selected suggestion into the entry.
---@param entry TextEntry?
---@return boolean success
function SuggestBox:insertSelected(entry)
    local item = self.selected and self.items[self.selected]
    if not item or not item.item then
        return false
    end

    return self:insertSuggestion(item.item, entry)
end

---Inserts the given suggestion into the entry.
---@param suggestion SuggestBox.Suggestion
---@param entry TextEntry?
---@return boolean success
function SuggestBox:insertSuggestion(suggestion, entry)
    entry = entry or self.entry
    if not entry then
        return false
    end

    local text = suggestion.content
    if suggestion.append then
        text = entry:getInternalText() .. text
    elseif suggestion.prepend then
        text = text .. entry:getInternalText()
    end

    entry:setText(text)
    self:setVisible(false)

    core.callback.invoke(self.callbacks.insert, self, entry, suggestion)

    if self.populateAfterInsert then
        self:onTextChange(text, true)
    end

    return true
end

---Called when the associated entry loses focus.
function SuggestBox:onBlurEntry()
    local entry = self.entry
    if not entry then
        return
    end

    if self.refocusOverScrollbar and self:isMouseOverScrollBar() then
        entry:focus(true)
        return
    end

    self:setVisible(false)
end

---Called when the associated entry gains focus.
function SuggestBox:onFocusEntry()
    local entry = self.entry
    if not entry then
        return
    end

    self:onTextChange(entry:getInternalText(), true)
end

---Called when the `Down` key is pressed on the associated entry.
---@return boolean handled
function SuggestBox:onPressDown()
    if not self.keyNavigation or not self:isVisible() then
        return false
    end

    self:selectNext()
    return true
end

---Called when the `Enter` key is pressed on the associated entry.
---@return boolean handled
function SuggestBox:onPressEnter()
    if not self.suggestOnEnter or not self:isVisible() then
        return false
    end

    return self:insertSelected()
end

---Called when the `Escape` key is pressed on the associated entry.
---@return boolean handled
function SuggestBox:onPressEscape()
    if not self:isVisible() then
        return false
    end

    self:setVisible(false)
    return true
end

---Called when the `Tab` key is pressed on the associated entry.
---@return boolean handled
function SuggestBox:onPressTab()
    if not self.suggestOnTab or not self:isVisible() then
        return false
    end

    return self:insertSelected()
end

---Called when the `Up` key is pressed on the associated entry.
---@return boolean handled
function SuggestBox:onPressUp()
    if not self.keyNavigation or not self:isVisible() then
        return false
    end

    self:selectPrevious()
    return true
end

---Called when the associated entry is resized.
function SuggestBox:onResizeEntry()
    self:update()
end

---Called when the text changes on the associated entry.
---@param text string
---@param ignoreDelay boolean?
function SuggestBox:onTextChange(text, ignoreDelay)
    self:tryPopulate(text, ignoreDelay)
end

---Handles prerendering for the auto-suggest box.
function SuggestBox:prerender()
    if self.vscroll then
        if self.vscroll.height ~= self.height then
            self.vscroll:setHeight(self.height)
        end

        local targetX = self.width - 16
        if self.vscroll.x ~= targetX then
            self.vscroll:setX(targetX)
        end
    end

    ListBox.prerender(self)
end

---Sets the entry associated with the suggest box.
---@param entry TextEntry The entry to associate with the suggest box.
---@param notify boolean? If `true`, this will immediately fire a text change event for the suggest box.
function SuggestBox:setEntry(entry, notify)
    entry:setSuggestBox(self, notify)
end

---Sets the callback invoked after inserting a suggestion.
---@param target any?
---@param callback Callback.SuggestBox.Insert?
---@param ...any
function SuggestBox:setOnInsert(target, callback, ...)
    self.callbacks.insert = core.callback(target, callback, ...)
end

---Sets the function used to populate suggestions.
---@param target any?
---@param callback Callback.SuggestBox.Populate?
---@param ...any
function SuggestBox:setOnPopulate(target, callback, ...)
    self.callbacks.populate = core.callback(target, callback, ...)
end

---Sets the current list of suggestions.
---@param suggestions SuggestBox.Suggestion[]
function SuggestBox:setSuggestions(suggestions)
    self:clear()
    self:setYScroll(0)
    if #suggestions == 0 then
        self:setVisible(false)
        return
    end

    for i = 1, #suggestions do
        local suggestion = suggestions[i]
        local text = suggestion.text or suggestion.content

        local item = self:addItem(text, suggestion) --[[@as ListBoxItem]]
        item.tooltip = suggestion.tooltip
        item.textColor = suggestion.textColor
        item.texture = suggestion.texture
    end

    self:updatePosition()

    if not self:isVisible() then
        self:setVisible(true)
    end
end

---Sets the visibility state of the suggest box.
---@param visible boolean
function SuggestBox:setVisible(visible)
    ListBox.setVisible(self, visible)

    if visible then
        self:addToUIManager()
        self:update()
    end
end

---Calls the populate callback if the delay period is over.
---@param text string?
---@param ignoreDelay boolean?
---@return boolean populated
function SuggestBox:tryPopulate(text, ignoreDelay)
    if not text then
        local entry = self.entry
        if not entry then
            return false
        end

        text = entry:getInternalText()
    end

    local now
    if not ignoreDelay then
        now = getTimestampMs()
        if self.nextPopulateTime and self.nextPopulateTime > now then
            self.awaitingPopulate = true
            return false
        end
    end

    now = now or getTimestampMs()

    self.awaitingPopulate = false
    self.nextPopulateTime = now + self.delay
    core.callback.invoke(self.callbacks.populate, self, text)
    return true
end

---Called every 100ms while the element is visible.
function SuggestBox:update()
    local entry = self.entry
    if not entry or #self.items == 0 then
        self:setVisible(false)
        return
    end

    if entry and not entry:isReallyVisible() then
        self:setVisible(false)
        return
    end

    if self.awaitingPopulate then
        self:tryPopulate(entry:getInternalText())
    end

    self:updatePosition()
end

---Updates the size and position of the suggest box based on its entry.
function SuggestBox:updatePosition()
    local entry = self.entry
    if not entry then
        return
    end

    local h = self.itemheight * min(#self.items, self.visibleItems)
    self:setX(entry:getAbsoluteX())
    self:setWidth(entry:getWidth())
    self:setHeight(h)
    self:setScrollHeight(self.itemheight * #self.items)

    local absY = entry:getAbsoluteY()
    local entryHeight = entry:getHeight()
    if self.openUpwards or absY + entryHeight + self.height > gameCore:getScreenHeight() then
        self:setY(absY - self.height)
    else
        self:setY(absY + entryHeight)
    end

    if self.vscroll then
        self.vscroll:setHeight(h)
    end
end


---Triggered when the mouse button is pressed on a list item.
---@param item SuggestBox.Suggestion?
---@protected
function SuggestBox:_onMouseDown(item)
    if self.callbacks.mouseDown then
        ListBox._onMouseDown(self, item)
    elseif item then
        self:defaultOnMouseDown(item)
    end
end


---Creates an auto-suggest box.
---@param args Args.SuggestBox
---@return SuggestBox
function SuggestBox:new(args)
    local this = UI.new(self, ListBox.new, args)

    this.awaitingPopulate = false
    this.delay = args.delay or 0
    this.visibleItems = args.visibleItems or 5
    this.openUpwards = args.openUpwards or false
    this.keyNavigation = args.keyNavigation ~= false
    this.suggestOnTab = args.suggestOnTab ~= false
    this.suggestOnEnter = args.suggestOnEnter or false
    this.refocusOverScrollbar = args.refocusOverScrollbar or false
    this.populateAfterInsert = args.populateAfterInsert or false

    this:setFont(args.font or UIFont.Medium)
    this:setOnInsert(args.onInsertTarget or args.target, args.onInsert, unpack(args.onInsertArgs or {}))
    this:setOnPopulate(args.populateTarget or args.target, args.populate, unpack(args.populateArgs or {}))

    if args.entry then
        args.entry:setSuggestBox(this, true)
        this:updatePosition()
    end

    return this
end


return SuggestBox

--#region Type Definitions

---@class Args.SuggestBox : Args.ListBox
---@field visibleItems? integer The maximum number of items that should be visible without scrolling. Defaults to `5`.
---@field openUpwards? boolean If `true`, the suggest box will appear on top of the entry.
---@field entry? TextEntry The entry to associate with the suggest box.
---@field suggestOnTab? boolean If `true`, the suggest box will treat a `Tab` press on an associated entry as a click. Defaults to `true`.
---@field suggestOnEnter? boolean If `true`, the suggest box will treat an `Enter` press on an associated entry as a click. Defaults to `false`.
---@field keyNavigation? boolean If `false`, the suggest box won't change the selection when `Up` or `Down` is pressed.
---@field refocusOverScrollbar? boolean If `true`, the suggest box will refocus its entry when focus is lost while the mouse is over its scrollbar.
---@field populateAfterInsert? boolean If `true`, the suggest box will attempt to populate suggestions immediately after inserting a suggestion.
---@field delay? integer The delay in milliseconds to wait between calls to the populate callback. Defaults to `0`.
---@field populate? Callback.SuggestBox.Populate Invoked to populate suggestions.
---@field populateArgs? table Arguments for `populate`.
---@field populateTarget? any The first argument to pass to the `populate` callback.
---@field onInsert? Callback.SuggestBox.Insert Invoked after inserting text into an entry.
---@field onInsertArgs? table Arguments for `onInsert`.
---@field onInsertTarget? any The first argument to pass to the `onInsert` callback.

---@class InitArgs.SuggestBox : Args.SuggestBox, InitArgs.Shared
---@field items? SuggestBox.Suggestion[] Items to include in the suggester.


---@class SuggestBox.Callbacks : ListBox.Callbacks
---@field insert? CallbackInfo Invoked after inserting text into an entry.
---@field populate? CallbackInfo Invoked to populate suggestions.

---@class SuggestBox.Suggestion
---@field content string The content of the suggestion.
---@field text? string The text to display in the box. Defaults to the suggestion content.
---@field texture? Texture A texture to display with the suggestion.
---@field tooltip? string The tooltip to display when the suggestion is hovered.
---@field textColor? ColorTableRGBA<number> The text color to use for the suggestion.
---@field append? boolean If `true`, the suggestion content will be appended instead of replacing the current input.
---@field prepend? boolean If `true`, the suggestion content will be prepended instead of replacing the current input.


---@alias Callback.SuggestBox.Insert fun(target: any?, suggestBox: SuggestBox, entry: TextEntry, suggestion: SuggestBox.Suggestion)

---@alias Callback.SuggestBox.Populate fun(target: any?, suggestBox: SuggestBox, text: string)

--#endregion
