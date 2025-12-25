---Entry for key-value input.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/UI/Core'
local ListEntry = require 'OmiLibrary/Component/UI/ListEntry'


---@class MapEntry : ListEntry
---@field keyEntry TextEntry The text entry for entering map keys.
---@field keyValueSeparator string The string used to separate keys from values in the listbox.
---@field protected init MapEntry.Init Information used only during initialization.
---@field protected __base ListEntry The base class.
local MapEntry = ListEntry:derive('OmiMapEntry')


---Creates the children of the entry element.
function MapEntry:createChildren()
    ListEntry.createChildren(self)

    self:_sortList()
end

---Gets the map value of the entry.
---@return table<string, any>
function MapEntry:getValue()
    local map = {}

    for i = 1, #self.listbox.items do
        local item = self.listbox.items[i]
        local data = item.item
        if type(data) == 'table' and data[1] then
            map[tostring(data[1])] = data[2]
        end
    end

    return map
end

---Sets whether the map entry is currently enabled.
---@param enabled boolean
function MapEntry:setEnabled(enabled)
    ListEntry.setEnabled(self, enabled)
    self.keyEntry:setEnabled(enabled)
end

---Sets a callback function to be called for creating a new item.
---@param target any?
---@param callback Callback.MapEntry.Add?
---@param ...any?
function MapEntry:setOnAdd(target, callback, ...)
    self.callbacks.add = core.callback(target, callback, ...)
end

---Sets a callback function to be called when the list changes.
---@param target any?
---@param callback Callback.MapEntry.Change?
---@param ...any?
function MapEntry:setOnChange(target, callback, ...)
    self.callbacks.change = core.callback(target, callback, ...)
end

---Sets the value of the entry.
---The values will be used as both the text and the item for the listbox items.
---@param value table<string, any>? The new value for the list entry.
---@param notify boolean? If `true`, this will trigger the change callback.
function MapEntry:setValue(value, notify)
    value = value or {}
    local listbox = self.listbox
    listbox:clear()

    for key, val in pairs(value) do
        local item = { key, val }
        local text = key .. self.keyValueSeparator .. tostring(val)

        listbox:addItem(text, item)
    end

    self:_sortList()
    if notify then
        core.callback.invoke(self.callbacks.change, self)
    end
end

---Called every 100ms while the map entry is visible.
---Updates the enable state of the add button.
function MapEntry:update()
    local valid = self.entry:isValid() and self.keyEntry:isValid()
    self.addBtn:setEnable(valid)
end


---Adds the current value to the entry.
---@return ListBoxItem?
---@protected
function MapEntry:_add()
    local info = self:_getItemArgs() --[[@as MapEntry.AddResult]]
    if not info or not info.key then
        return
    end

    -- remove the existing value for the key
    self:_removeFromListbox(info.key)

    local item = self:_addToListbox(info)
    local value = item.item or item.text

    item.text = info.key .. self.keyValueSeparator .. item.text
    item.item = {
        info.key,
        value,
    }

    self:_sortList()
    return item
end

---Checks whether the state is valid for adding to the map.
---@return boolean
---@protected
function MapEntry:_canAdd()
    return ListEntry._canAdd(self) and self:_isEntryValid(self.keyEntry)
end

---Clears text entries.
---@protected
function MapEntry:_clearTextEntries()
    ListEntry._clearTextEntries(self)
    self.keyEntry:clear()
end

---Called to create text entries.
---@param entryArgs InitArgs.TextEntry
---@protected
function MapEntry:_createTextEntries(entryArgs)
    local keyArgs = core.copy(entryArgs)
    keyArgs.tooltip = self.init.keyTooltip or keyArgs.tooltip
    keyArgs.placeholderText = self.init.keyPlaceholder

    self.keyEntry = UI.textEntry(keyArgs)

    entryArgs.x = self.keyEntry:getRight() + 4
    entryArgs.placeholderText = self.init.valuePlaceholder

    self.entry = UI.textEntry(entryArgs)
end

---Creates listbox item args based on the current input.
---This assumes the input is valid.
---@return MapEntry.AddResult?
---@protected
function MapEntry:_getItemArgs()
    local text = self.entry:getInternalText():trim()
    local keyText = self.keyEntry:getInternalText():trim()

    local info ---@type MapEntry.AddResult?
    if self.callbacks.add then
        info = core.callback.invoke(self.callbacks.add, keyText, text, self)
        if not info then
            self:_clearTextEntries()
            return
        elseif type(info) == 'string' then
            info = { text = info, key = keyText }
        end
    else
        info = { text = text, key = keyText }
    end

    info.key = tostring(info.key or keyText)
    return info
end

---Removes an item from the listbox if it has the given key.
---@param key string
---@protected
function MapEntry:_removeFromListbox(key)
    local listbox = self.listbox

    local idx
    for i = 1, #listbox.items do
        local item = listbox.items[i]
        local data = item.item

        if type(data) == 'table' and data[1] == key then
            idx = i
            break
        end
    end

    if idx then
        listbox:removeItemByIndex(idx)
    end
end

---Comparator for sorting the listbox by key.
---@param a ListBoxItem
---@param b ListBoxItem
---@return boolean
---@protected
function MapEntry._sortByKey(a, b)
    local aKey = type(a.item) == 'table' and tostring(a.item[1])
    local bKey = type(b.item) == 'table' and tostring(b.item[1])

    if bKey and not aKey then
        return true
    end

    if not aKey or not bKey then
        return false
    end

    return aKey < bKey
end

---Sorts the listbox.
---@protected
function MapEntry:_sortList()
    ---@diagnostic disable-next-line: redundant-parameter
    self.listbox:sort(self._sortByKey)
end


---Creates a new map entry.
---@param args Args.MapEntry
---@return MapEntry
function MapEntry:new(args)
    local itemMap = args.items

    args = core.copy(args)
    args.items = nil
    args.includeReorderButtons = args.includeReorderButtons or false

    local this = ListEntry.new(self, args) --[[@as MapEntry]]
    this.keyValueSeparator = ' = '

    ---@type InitArgs.ListBoxItem[]
    local items = {}
    if itemMap then
        for k, v in pairs(itemMap) do
            local item = this:_valueToItem(v)
            item.item = { k, item.item }
            item.text = k .. this.keyValueSeparator .. item.text

            items[#items + 1] = item
        end
    end

    this.init.keyPlaceholder = args.keyPlaceholder
    this.init.valuePlaceholder = args.valuePlaceholder
    this.init.items = items

    return this
end

return MapEntry

--#region Type Definitions

---@class Args.MapEntry : Args.ListEntry
---@field keyTooltip? string | false The tooltip to set on the key text entry. Defaults to the entry tooltip.
---@field keyPlaceholder? string The string to use for the key entry placeholder.
---@field valuePlaceholder? string The string to use for the value entry placeholder.
---@field items? table<string, string | InitArgs.ListBoxItem> Initial items to include in the listbox.
---@field includeReorderButtons? boolean If `true`, buttons to reorder list elements will be included. Defaults to `false`.
---@field add? Callback.MapEntry.Add Called when adding a new item. Creates an item with the return value.
---@field addArgs? table Arguments for `add`.
---@field addTarget? any The first argument to pass to the `add` callback.
---@field onChange? Callback.MapEntry.Change Invoked when the entry list changes.
---@field onChangeArgs? table Arguments for `change`.
---@field onChangeTarget? any The first argument to pass to the `change` callback.

---@class InitArgs.MapEntry : Args.MapEntry, InitArgs.ListEntry


---@class MapEntry.Init : ListEntry.Init
---@field keyTooltip? string | false The tooltip to set on the key text entry.
---@field keyPlaceholder? string The string to use for the key entry placeholder.
---@field valuePlaceholder? string The string to use for the value entry placeholder.

---@class MapEntry.AddResult : InitArgs.ListBoxItem
---@field key string The key to use for the entry.

---@alias Callback.MapEntry.Add fun(target: any?, key: string, text: string, entry: MapEntry): MapEntry.AddResult?

---@alias Callback.MapEntry.Change fun(target: any?, entry: MapEntry)

--#endregion
