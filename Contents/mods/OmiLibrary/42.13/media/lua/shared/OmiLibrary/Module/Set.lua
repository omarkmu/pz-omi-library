---Contains functionality related to sets.
---@namespace omi

local Set = require 'OmiLibrary/Component/Set/Set'
local OrderedSet = require 'OmiLibrary/Component/Set/OrderedSet'


---@class set
---@overload fun(source?: any[] | Set): Set
local set = {}

---Set of elements with constant access.
set.Set = Set

---Ordered set of elements with constant access.
set.OrderedSet = OrderedSet


---Creates a set.
---@generic T
---@param source (T[] | Set<T>)?
---@return Set<T>
function set.new(source)
    return Set:new(source)
end

---Creates an ordered set.
---@generic T
---@param source (T[] | OrderedSet<T>)?
---@return OrderedSet<T>
function set.ordered(source)
    return OrderedSet:new(source)
end

---Creates a table-based set, associating elements to `true`.
---@generic T
---@param source T[]?
---@return SetTable<T>
function set.table(source)
    if not source then
        return {}
    end

    local elements = {}
    for i = 1, #source do
        elements[source[i]] = true
    end

    return elements
end


setmetatable(set, { __call = function(self, ...) return self.new(...) end })
return set
