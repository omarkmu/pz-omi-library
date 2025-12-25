---Set of elements with constant access.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'

local select = select

---@class Set<TElement> : Class
---@field protected _count integer The number of elements in the set.
---@field protected _elements table<TElement, any?> The internal table for set elements.
local Set = core.class('Set')


---Adds an element to the set.
---@param element TElement
function Set:add(element)
    if element == nil then
        return
    end

    if self._elements[element] == nil then
        self._count = self._count + 1
    end

    self._elements[element] = true
end

---Returns a clone of the set.
---@return Set<TElement>
function Set:clone()
    return Set:new(self)
end

---Returns a new set without the elements in the given set.
---@param set Set<TElement>
---@return Set<TElement>
function Set:difference(set)
    local elements = {} ---@type TElement[]

    for el in self:elements() do
        if not set:has(el) then
            elements[#elements + 1] = el
        end
    end

    return Set:new(elements)
end

---Returns an iterator over the set's elements.
---@return fun(): TElement?
function Set:elements()
    local key
    local iterator, state = pairs(self._elements)
    return function()
        key = iterator(state, key) ---@diagnostic disable-line: redundant-parameter
        if key ~= nil then
            return key
        end
    end
end

---Checks whether the set contains the given element.
---@param element TElement
---@return boolean
function Set:has(element)
    return self._elements[element] ~= nil
end

---Returns the set as a list.
---The order of elements is undefined.
---@return TElement[]
function Set:list()
    return core.keys(self._elements)
end

---Removes an element from the set.
---@param element TElement
function Set:remove(element)
    if self._elements[element] ~= nil then
        self._count = self._count - 1
    end

    self._elements[element] = nil
end

---Returns the number of elements in the set.
---@return integer
function Set:size()
    return self._count
end

---Returns the set as an association of elements to `true`.
---@return SetTable<TElement>
function Set:table()
    return core.copy(self._elements)
end

---Updates the set with the elements from the given sources.
---@param ... TElement[] | Set<TElement>
function Set:update(...)
    for i = 1, select('#', ...) do
        local source = select(i, ...)
        if core.isinstance(source, Set) then
            self:updateFromSet(source)
        elseif source then
            self:updateFromList(source)
        end
    end
end

---Updates the set with the elements from the given list.
---@param list TElement[]
function Set:updateFromList(list)
    for i = 1, #list do
        local el = list[i]
        if not self._elements[el] then
            self._count = self._count + 1
            self._elements[el] = true
        end
    end
end

---Updates the set with the elements from the given set.
---@param set Set<TElement>
function Set:updateFromSet(set)
    for k in pairs(set._elements) do
        if not self._elements[k] then
            self._elements[k] = true
            self._count = self._count + 1
        end
    end
end


---Gets the size of the set.
---@protected
function Set:__len()
    return self:size()
end


---Creates a new set.
---@generic T
---@param source? T[] | Set<T>
---@return Set<T>
function Set:new(source)
    local this = core.new(self)

    this._count = 0
    this._elements = {}

    this:update(source or {})
    return this
end


return Set
