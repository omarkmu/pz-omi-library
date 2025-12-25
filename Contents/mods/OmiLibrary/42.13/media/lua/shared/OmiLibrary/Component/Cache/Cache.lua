---Cache for arbitrary data.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local callback = require 'OmiLibrary/Module/Callback'

local getTimestampMs = getTimestampMs
local sort = table.sort


---@class Cache<TData> : Class
---@field protected callbacks Cache.Callbacks Container for callbacks.
---@field protected _count integer The number of items in the cache.
---@field protected _indexes table<string, cache.Index<TData>> Indexes containing cache tables.
---@field protected _primaryKey string The primary key to index cache items by.
---@field protected _capacity? integer The capacity for the cache.
---@field protected _lru boolean If `true`, accessing cache items will reset their expiry timer.
---@field protected _ttl? integer The time-to-live for cache items in milliseconds.
local Cache = core.class('Cache')


---Removes all items from the cache.
function Cache:clear()
    self._count = 0
    for k in pairs(self._indexes) do
        self._indexes[k] = {}
    end
end

---Returns the number of items currently in the cache.
---@return integer
function Cache:count()
    return self._count
end

---Default handler for creating data for a cache item.
---For the base cache, this returns `nil`.
---@param index string
---@param key any
---@return TData?
---@diagnostic disable-next-line: unused
function Cache:defaultCreateItemData(index, key) end

---Clears the cache and replaces its items with those in the list.
---@param list TData[]
function Cache:fromList(list)
    self:clear()
    for i = 1, #list do
        local item = list[i]
        self:set(item[self._primaryKey], item)
    end
end

---Clears the cache and replaces its items with those in the table.
---@param map table<any, TData>
function Cache:fromMap(map)
    self:clear()
    for _, item in pairs(map) do
        self:set(item[self._primaryKey], item)
    end
end

---Gets cached data by primary key.
---@param key any
---@param createOnMiss boolean?
---@return TData?
function Cache:get(key, createOnMiss)
    return self:getByIndex(self._primaryKey, key, createOnMiss)
end

---Gets cached data by an index key.
---@param index string
---@param key any
---@param createOnMiss boolean?
---@return TData?
function Cache:getByIndex(index, key, createOnMiss)
    local indexTable = self._indexes[index]
    if not indexTable then
        return
    end

    self:update()
    local now = getTimestampMs()
    local item = indexTable[key] ---@type Cache.Item<TData>?
    if not item and createOnMiss ~= false then
        item = self:_createItem(index, key, now)
    end

    if not item then
        return
    end

    item.lastAccess = now
    return item.data
end

---Gets a cache item's primary key value given an index.
---@param index string
---@param key any
---@param createOnMiss boolean?
---@return any | nil
function Cache:getPrimaryValue(index, key, createOnMiss)
    local data = self:getByIndex(index, key, createOnMiss)
    if not data then
        return
    end

    return data[self._primaryKey]
end

---Gets cached data by primary key.
---Throws an error if an item could not be retrieved or created.
---@param key any
---@param createOnMiss boolean?
---@return TData
function Cache:getRequired(key, createOnMiss)
    local value = self:get(key, createOnMiss)
    if not value then
        error(string.format('Failed to get cache item for key %s', tostring(key)))
    end

    return value
end

---Checks whether the cache has a value with the given key.
---@param key any
---@param index string?
---@return boolean
function Cache:has(key, index)
    index = index or self._primaryKey

    local indexTable = self._indexes[index]
    if not indexTable then
        return false
    end

    return indexTable[key] ~= nil
end

---Returns an iterator over cache items by primary key.
---@return fun(): any?, TData?
function Cache:iterate()
    local key, value
    local iterator, state = pairs(self._indexes[self._primaryKey])
    return function()
        key, value = iterator(state, key) ---@diagnostic disable-line: redundant-parameter
        if value ~= nil then
            return key, value.data
        end
    end
end

---Removes a cache item by the primary key.
---@param key any
---@return TData?
function Cache:remove(key)
    return self:removeByIndex(self._primaryKey, key)
end

---Removes a cache item by an index key.
---@param index string
---@param key any
---@return TData?
function Cache:removeByIndex(index, key)
    local indexTable = self._indexes[index]
    if not indexTable then
        return
    end

    local item = indexTable[key]
    if not item then
        return
    end

    local data = item.data
    for k in pairs(self._indexes) do
        local indexKey = data[k]
        if indexKey then
            self._indexes[k][indexKey] = nil
        end
    end

    self._count = self._count - 1
    return data
end

---Adds an item to the cache based on the primary key.
---@param key any
---@param data TData
---@return boolean success
function Cache:set(key, data)
    return self:setByIndex(self._primaryKey, key, data)
end

---Adds an item to the cache.
---@param index string
---@param key any
---@param data table
---@return boolean success
function Cache:setByIndex(index, key, data)
    local indexTable = self._indexes[index]
    if not indexTable then
        return false
    end

    self:update()
    return self:_createItem(index, key, getTimestampMs(), data) ~= nil
end

---Sets the callback to use to create items on cache miss.
---@param target any?
---@param func cache.Callback.CreateItemData<TData>?
---@param ...any?
function Cache:setOnCreateItem(target, func, ...)
    self.callbacks.createItemData = callback(target, func --[[@as function]], ...)
end

---Converts the cache to a list of cache items.
---@return TData[]
function Cache:toList()
    local primaryIndex = self._indexes[self._primaryKey]

    local items = {} ---@type Cache.Item<TData>[]
    for _, item in pairs(primaryIndex) do
        items[#items + 1] = item
    end

    sort(items, core.bind(self._compareItems, self))

    local list = {}
    for i = 1, #items do
        list[#list + 1] = items[i].data
    end

    return list
end

---Converts the cache to a mapping from the primary key to the cache item.
---@return table<any, TData>
function Cache:toMap()
    local primaryIndex = self._indexes[self._primaryKey]

    local map = {}
    for _, item in pairs(primaryIndex) do
        local key = item.data[self._primaryKey]
        if key then
            map[key] = item.data
        end
    end

    return map
end

---Removes expired items from the cache.
function Cache:update()
    if not self._ttl then
        return
    end

    local toRemove = {}
    local now = getTimestampMs()

    for k, item in pairs(self._indexes[self._primaryKey]) do
        local compareTime = self._lru and item.lastAccess or item.created
        if now - compareTime >= self._ttl then
            toRemove[#toRemove + 1] = k
        end
    end

    for i = 1, #toRemove do
        self:remove(toRemove[i])
    end
end


---Compares items by creation or access time.
---@param a Cache.Item<TData>
---@param b Cache.Item<TData>
---@return boolean
---@protected
function Cache:_compareItems(a, b)
    local aTime = self._lru and a.lastAccess or a.created
    local bTime = self._lru and b.lastAccess or b.created

    return aTime < bTime
end

---Creates an item associated with an index and a key.
---@param index string
---@param key any
---@param now integer
---@param data TData?
---@return Cache.Item<TData>?
---@protected
function Cache:_createItem(index, key, now, data)
    data = data or self:_createItemData(index, key)
    if not data then
        return
    end

    -- remove the item if it already exists
    self:removeByIndex(index, key)

    self:_ensureUnderCapacity()

    ---@type Cache.Item<TData>
    local newItem = {
        data = data,
        created = now,
        lastAccess = now,
    }

    self._indexes[index][key] = newItem
    for k in pairs(self._indexes) do
        local indexKey = data[k]
        if indexKey then
            self._indexes[k][indexKey] = newItem
        end
    end

    self._count = self._count + 1
    return self._indexes[index][key]
end

---Creates data for a cache item associated with an index and a key.
---@param index string
---@param key any
---@return TData?
---@protected
function Cache:_createItemData(index, key)
    if self.callbacks.createItemData then
        return callback.invoke(self.callbacks.createItemData, key, index)
    end

    return self:defaultCreateItemData(index, key)
end

---Removes the oldest items until the cache is under the capacity.
---@protected
function Cache:_ensureUnderCapacity()
    if not self._capacity then
        return
    end

    while self._count >= self._capacity do
        self:_removeOldest()
    end
end

---Removes the oldest item in the cache.
---@protected
function Cache:_removeOldest()
    local oldestKey
    local oldestTime

    for k, item in pairs(self._indexes[self._primaryKey]) do
        local compareTime = self._lru and item.lastAccess or item.created
        if not oldestTime or compareTime < oldestTime then
            oldestKey = k
            oldestTime = compareTime
        end
    end

    if oldestKey then
        self:remove(oldestKey)
    end
end


---Creates a new cache.
---@generic T : table
---@param args Args.Cache<T>
---@return Cache<T>
function Cache:new(args)
    local this = core.new(self)

    this._ttl = args.ttl
    this._capacity = args.capacity
    this._lru = args.lru ~= false
    this._count = 0
    this._primaryKey = args.primaryKey
    this._indexes = { [this._primaryKey] = {} }

    local indexKeys = args.indexes or {}
    for i = 1, #indexKeys do
        this._indexes[indexKeys[i]] = {}
    end

    this.callbacks = {}
    this:setOnCreateItem(args.onCreateItemTarget or args.target, args.onCreateItem, unpack(args.onCreateItemArgs or {}))

    return this
end


return Cache

--#region Type Definitions

---@class Args.Cache.Base<TData>
---@field indexes? string[] Additional keys to index cache items by.
---@field capacity? integer The capacity for the cache.
---@field lru? boolean If `true`, accessing cache items will reset their expiry timer. Defaults to `true`.
---@field ttl? integer The time-to-live for cache items in milliseconds.
---@field onCreateItem? cache.Callback.CreateItemData<TData> Invoked to create a cache item on miss.
---@field onCreateItemArgs? table Arguments for `onCreateItem`.
---@field onCreateItemTarget? any The first argument to pass to the `onCreateItem` callback.
---@field target? any The default first argument to use for callbacks when a target is unspecified.

---@class Args.Cache<TData> : Args.Cache.Base<TData>
---@field primaryKey string The primary key to index cache items by.


---@class Cache.Callbacks
---@field createItemData? CallbackInfo Invoked to create a cache item on miss.

---@class Cache.Item<TData>
---@field created integer The timestamp at which the item was created.
---@field lastAccess integer The last time the cache item was accessed.
---@field data TData The cached data.


---@alias cache.Index<T> table<any, Cache.Item<T>>

---@alias cache.Callback.CreateItemData<T> fun(target: any?, key: any, index: string): T?

--#endregion
