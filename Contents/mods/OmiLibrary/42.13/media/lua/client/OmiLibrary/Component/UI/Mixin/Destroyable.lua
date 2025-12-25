---Mixin with functionality to perform events when destroying an element.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'

local setJoypadFocus = setJoypadFocus
local setPrevFocusForPlayer = setPrevFocusForPlayer

---@class Mixin.Destroyable : ISUIElement
---@field playerNum? integer The player number of the owning player.
---@field protected _clearFocusOnDestroy? boolean Whether the joypad focus should be cleared when the element is destroyed.
---@field protected _restoreFocusOnDestroy? boolean Whether the element should set joypad focus to the previous focus when it's destroyed.
---@field protected _destroyableOwners? SetTable<Mixin.Destroyable> Elements that will remove this element when they're destroyed.
---@field protected _removeOnDestroySet? SetTable<ISUIElement> Elements to remove when destroying this element.
local Destroyable = {}


---Removes an element registered to be removed on destroy.
---@param element ISUIElement
function Destroyable:cancelRemoveOnDestroy(element)
    if not self._removeOnDestroySet then
        return
    end

    ---@cast element Mixin.Destroyable
    if element._destroyableOwners then
        element._destroyableOwners[self] = nil
    end

    self._removeOnDestroySet[element] = nil
end

---Clears the set of elements to be removed on destroy.
function Destroyable:clearRemoveOnDestroy()
    if not self._removeOnDestroySet then
        return
    end

    for el in pairs(self._removeOnDestroySet) do
        self:cancelRemoveOnDestroy(el)
    end
end

---Removes the element and its children from the UI.
function Destroyable:destroy()
    self:setVisible(false)

    local parent = self:getParent()
    if parent then
        parent:removeChild(self)
    else
        self:removeFromUIManager()
    end

    if self._removeOnDestroySet then
        for el in pairs(self._removeOnDestroySet) do
            local elParent = el:getParent()
            if elParent then
                elParent:removeChild(el)
            else
                el:removeFromUIManager()
            end
        end

        self._removeOnDestroySet = nil
    end


    if self._destroyableOwners then
        for owner in pairs(self._destroyableOwners) do
            owner:cancelRemoveOnDestroy(self)
        end

        self._destroyableOwners = nil
    end

    if self._restoreFocusOnDestroy then
        setPrevFocusForPlayer(self.playerNum or 0)
    elseif self._clearFocusOnDestroy then
        setJoypadFocus(self.playerNum or 0, nil)
    end
end

---Returns the set of items that will be removed when this element is destroyed.
---@return SetTable<ISUIElement>
function Destroyable:getRemoveOnDestroy()
    return core.copy(self._removeOnDestroySet)
end

---Adds an element to remove when destroying this element.
---@param element ISUIElement
function Destroyable:removeOnDestroy(element)
    self._removeOnDestroySet = self._removeOnDestroySet or {}
    self._removeOnDestroySet[element] = true

    ---@cast element Mixin.Destroyable
    if type(element.destroy) == 'function' then
        element._destroyableOwners = element._destroyableOwners or {}
        element._destroyableOwners[self] = true
    end
end


return Destroyable
