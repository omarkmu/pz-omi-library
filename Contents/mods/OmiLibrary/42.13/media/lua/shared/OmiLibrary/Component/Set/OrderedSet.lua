---Ordered set of elements with constant access.
---@namespace omi

local Set = require 'OmiLibrary/Component/Set/Set'
local core = require 'OmiLibrary/Module/Utils'

local select = select
local remove = table.remove

---@class OrderedSet<TElement> : Set<TElement>
---@field protected _count integer Unused.
---@field protected _list TElement[] The list of set elements.
---@field protected _elements table<TElement, integer?> Mapping of set elements to their indices in the element list.
local OrderedSet = Set:derive('OrderedSet')


---Adds an element to the set.
---@param element TElement
function OrderedSet:add(element)
    if element == nil then
        return
    end

    if self:has(element) then
        return
    end

    self._list[#self._list + 1] = element
    self._elements[element] = #self._list
end

---Returns a clone of the set.
---@return OrderedSet<TElement>
function OrderedSet:clone()
    return OrderedSet:new(self)
end

---Returns a new set without the elements in the given set.
---@param set Set<TElement>
---@return OrderedSet<TElement>
function OrderedSet:difference(set)
    local elements = {} ---@type TElement[]

    for el in self:elements() do
        if not set:has(el) then
            elements[#elements + 1] = el
        end
    end

    return OrderedSet:new(elements)
end

---Returns an iterator over the set's elements.
---@return fun(): TElement?
---@return any...
function OrderedSet:elements()
    local i = 0
    return function()
        if i >= #self._list then
            return
        end

        i = i + 1
        return self._list[i]
    end
end

---Returns the index associated with the element.
---@param element TElement
---@return integer?
function OrderedSet:index(element)
    return self._elements[element]
end

---Inserts an element into the ordered set at the given index.
---@param element TElement
---@param index integer
function OrderedSet:insert(element, index)
    if self:has(element) then
        self:remove(element)
    end

    if index > #self._list then
        self:add(element)
        return
    end

    table.insert(self._list, index, element)
    self:_incrementAfter(index)

    self._elements[element] = index
end

---Returns the set as a list.
---@return TElement[]
function OrderedSet:list()
    return core.copyList(self._list)
end

---Returns an iterator over the set's indices and elements.
---@return fun(): integer?, TElement?
function OrderedSet:pairs()
    local i = 0
    return function()
        if i >= #self._list then
            return
        end

        i = i + 1
        return i, self._list[i]
    end
end

---Removes an element from the set.
---@param element TElement
function OrderedSet:remove(element)
    local index = self:index(element)
    if not index then
        return
    end

    local count = #self._list
    remove(self._list, index)

    if index ~= count then
        self:_decrementAfter(index)
    end

    self._elements[element] = nil
end

---Returns the number of elements in the set.
---@return integer
function OrderedSet:size()
    return #self._list
end

---Returns the set as an association of elements to `true`.
---@return SetTable<TElement>
function OrderedSet:table()
    local elements = {}

    for element in pairs(self._elements) do
        elements[element] = true
    end

    return elements
end

---Updates the set with the elements from the given list.
---@param list TElement[]
function OrderedSet:updateFromList(list)
    for i = 1, #list do
        local element = list[i]
        if not self._elements[element] then
            self._list[#self._list + 1] = element
            self._elements[element] = #self._list
        end
    end
end

---Updates the set with the elements from the given set.
---@param set Set<TElement>
function OrderedSet:updateFromSet(set)
    for k in set:elements() do
        if not self._elements[k] then
            self._list[#self._list + 1] = k
            self._elements[k] = #self._list
        end
    end
end


---Decrements indices after the given index.
---@param index integer
---@protected
function OrderedSet:_decrementAfter(index)
    for element, idx in pairs(self._elements) do
        if idx > index then
            self._elements[element] = idx - 1
        end
    end
end

---Increments indices after the given index.
---@param index integer
---@protected
function OrderedSet:_incrementAfter(index)
    for element, idx in pairs(self._elements) do
        if idx > index then
            self._elements[element] = idx + 1
        end
    end
end


---Creates a new set.
---@generic T
---@param source (T[] | OrderedSet<T>)?
---@return OrderedSet<T>
function OrderedSet:new(source)
    local this = core.new(self, Set.new)

    this._list = {}
    this._elements = {}

    this:update(source or {})
    return this
end


return OrderedSet
