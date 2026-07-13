---Module containing cache functionality.
---@namespace omi

---@class cache
local cache = {}

---Cache component for associating keys to arbitrary data.
cache.Cache = require 'OmiLibrary/Component/Cache/Cache'

---Cache component for associating keys to player data.
cache.PlayerCache = require 'OmiLibrary/Component/Cache/PlayerCache'


---Creates a basic cache.
---@generic T : table
---@param args Args.Cache<T>
---@return Cache<T>
function cache.new(args)
    return cache.Cache:new(args)
end

---Creates a basic player cache.
---@generic T : PlayerCacheData
---@param args Args.PlayerCache<T>?
---@return PlayerCache<T>
function cache.player(args)
    return cache.PlayerCache:new(args)
end


return cache
