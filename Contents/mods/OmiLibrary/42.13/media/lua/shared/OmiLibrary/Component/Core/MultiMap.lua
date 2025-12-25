---Immutable set of key-value entries which permits multiple entries with the same key.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'


---@class MultiMap : Class
---@field protected _entries Entry[] The list of entries in the multimap.
---@field protected _map table<any, Entry[]> Mapping of entry keys to entries.
local MultiMap = core.class('MultiMap')


---Creates a multimap with list items as indexed entries.
---@static
---@param list any[]?
---@return MultiMap
function MultiMap.fromList(list)
    list = list or {}
    local entries = {} ---@type Entry[]

    for i = 1, #list do
        entries[#entries + 1] = { i, list[i] }
    end

    return MultiMap:new(entries)
end

---Creates a multimap with set items as entries.
---The set items are set to the keys and values of each entry.
---@static
---@param set SetTable<any>?
---@return MultiMap
function MultiMap.fromSet(set)
    set = set or {}
    local entries = {} ---@type Entry[]

    for k, v in pairs(set) do
        if v ~= false then
            entries[#entries + 1] = { k, k }
        end
    end

    return MultiMap:new(entries)
end


---Concatenates the stringified values of this multimap.
---@param sep string? The separator to use. Defaults to the empty string.
---@param i integer? The start index.
---@param j integer? The end index.
---@return string
function MultiMap:concat(sep, i, j)
    return core.concat(core.pack(self:values()), sep, i, j)
end

---Returns the nth entry in the multimap.
---@param n integer
---@return Entry?
function MultiMap:entry(n)
    local e = self._entries[n]
    if e then
        return core.copy(e)
    end
end

---Returns the value of the first entry in the multimap.
---@return any | nil
function MultiMap:first()
    local e = self._entries[1]
    if e then
        return e[2]
    end
end

---Gets the first value associated with a key.
---@param key any The key to query.
---@param default any? A default value to return if there are no entries associated with the key.
---@return any | nil
function MultiMap:get(key, default)
    local list = self._map[key]
    if not list or not list[1] then
        return default
    end

    return list[1][2]
end

---Gets the boolean value of the first value associated with a key.
---Empty strings will be considered false.
---@param key any The key to query.
---@return boolean
function MultiMap:getBoolean(key)
    local value = self:get(key)
    return not not (value and value ~= '')
end

---Gets the numeric value of the first non-nil value associated with a key as a string.
---@param key any The key to query.
---@param default number? A default value to return if there are no values associated with the key. Defaults to `0`.
---@return number
function MultiMap:getNumber(key, default)
    return tonumber(self:get(key, default)) or 0
end

---Gets the first value associated with a key as a string.
---@param key any The key to query.
---@param default string? A default value to return if there are no values associated with the key. Defaults to the empty string.
---@return string
function MultiMap:getString(key, default)
    return tostring(self:get(key, default) or '')
end

---Returns true if there is a value associated with the given key.
---@param key any
---@return boolean
function MultiMap:has(key)
    return self._map[key] ~= nil
end

---Creates a list-style multimap of entries associated with a key.
---@param key any The key to query.
---@param default any? A default value to return if there are no entries associated with the key.
---@return any | nil
function MultiMap:index(key, default)
    local entryList = self._map[key]
    if not entryList then
        return default
    end

    return MultiMap:new(entryList)
end

---Returns an iterator for the keys in this multimap.
---@return fun(): any?
function MultiMap:keys()
    return core.iterMapListValues(function(e) return e[1] end, self._entries)
end

---Returns the value of the last entry in the multimap.
---@return any | nil
function MultiMap:last()
    local e = self._entries[#self._entries]
    if e then
        return e[2]
    end
end

---Returns an iterator for the entries in this multimap.
---@return fun(): any?, any?
function MultiMap:pairs()
    local i = 0
    return function()
        i = i + 1
        local e = self._entries[i]
        if e then
            return e[1], e[2]
        end
    end
end

---Returns the number of entries in this multimap.
---@return integer
function MultiMap:size()
    return #self._entries
end

---Converts a multimap to an options multimap.
---This converts strings that evaluate to case-insensitive `false` to a boolean.
---@return MultiMap
function MultiMap:toOptions()
    local entries = {} ---@type Entry[]
    for k, v in self:pairs() do
        if tostring(v):lower() == 'false' then
            v = false
        end

        entries[#entries + 1] = { k, v }
    end

    return MultiMap:new(entries)
end

---Gets a set of the multimap's values.
---@return SetTable
function MultiMap:toValueSet()
    local set = {}

    for value in self:values() do
        set[value] = true
    end

    return set
end

---Returns a multimap with only the unique values from this multimap.
---@return MultiMap
function MultiMap:unique()
    local seen = {}
    local entries = {}
    for key, value in self:pairs() do
        if not seen[value] then
            entries[#entries + 1] = { key, value }
            seen[value] = true
        end
    end

    return MultiMap:new(entries)
end

---Returns an iterator for the values in this multimap.
---@return fun(): any?
function MultiMap:values()
    return core.iterMapListValues(function(e) return e[2] end, self._entries)
end

---Creates a new multimap with the items from this multimap and an additional set.
---The set items are set to the keys and values of each entry.
---@param set SetTable<any>?
---@return MultiMap
function MultiMap:withSet(set)
    set = set or {}
    local entries = {} ---@type Entry[]

    for k, v in pairs(set) do
        if v ~= false then
            entries[#entries + 1] = { k, k }
        end
    end

    return MultiMap:new(self, entries)
end

---Creates a new multimap with the items from this multimap and an additional value.
---The value is added as an entry with the same key and value.
---@param value any
---@return MultiMap
function MultiMap:withSetValue(value)
    return MultiMap:new(self, { { value, value } })
end


---Gets the size of the multimap.
---@protected
function MultiMap:__len()
    return self:size()
end

---Gets the first value in the multimap converted to a string.
---@protected
function MultiMap:__tostring()
    return tostring(self:first() or '')
end


---Creates a new multimap.
---@param ...(Entry[] | MultiMap) Sources to copy entries from.
---@return MultiMap
function MultiMap:new(...)
    local this = core.new(self)

    local map = {}
    local entries = {}
    for i = 1, select('#', ...) do
        local source = select(i, ...)

        local entryArray ---@type Entry[]?
        if core.isinstance(source, MultiMap) then
            entryArray = source._entries
        elseif type(source) == 'table' then
            entryArray = source
        end

        if entryArray then
            for j = 1, #entryArray do
                local entry = entryArray[j]
                entries[#entries + 1] = entry

                local mapEntries = map[entry[1]]
                if not mapEntries then
                    mapEntries = {}
                    map[entry[1]] = mapEntries
                end

                local index = #mapEntries + 1
                mapEntries[index] = { index, entry[2] }
            end
        end
    end

    this._map = map
    this._entries = entries
    return this
end


return MultiMap
