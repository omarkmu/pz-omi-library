---Cache for player data.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local callback = require 'OmiLibrary/Module/Callback'
local Cache = require 'OmiLibrary/Component/Cache/Cache'

local getPlayerByOnlineID = getPlayerByOnlineID
local getPlayerFaction = Faction.getPlayerFaction


---@class PlayerCache<TData : PlayerCacheData> : Cache<TData>
---@field protected callbacks PlayerCache.Callbacks Container for callbacks.
local PlayerCache = Cache:derive('PlayerCache')


---Creates a cache item given a player.
---@param player IsoPlayer
---@return TData
function PlayerCache:createPlayerData(player)
    if self.callbacks.createPlayerData then
        return callback.invoke(self.callbacks.createPlayerData, player)
    end

    return self:defaultCreatePlayerData(player)
end

---Default handler for creating data for a cache item.
---@param index string
---@param key any
---@return TData?
function PlayerCache:defaultCreateItemData(index, key)
    local player ---@type IsoPlayer?
    if index == 'username' then
        player = core.getPlayerByUsername(key)
    elseif index == 'onlineID' then
        player = getPlayerByOnlineID(key)
    end

    if player then
        return self:createPlayerData(player)
    end
end

---Default handler to create cache item data given a player.
---@param player IsoPlayer
---@return PlayerCacheData
function PlayerCache:defaultCreatePlayerData(player)
    local desc = player:getDescriptor()
    local faction = getPlayerFaction(player)

    local speechColor ---@type ColorTable<integer>
    local color = player:getSpeakColour()
    if color then
        speechColor = {
            r = color:getRed(),
            g = color:getGreen(),
            b = color:getBlue(),
        }
    else
        speechColor = { r = 255, g = 255, b = 255 }
    end

    ---@type PlayerCacheData
    local item = {
        username = player:getUsername(),
        forename = desc:getForename(),
        surname = desc:getSurname(),
        onlineID = player:getOnlineID(),
        speechColor = speechColor --[[@as ColorTable<integer>]],
        faction = faction and faction:getName(),
    }

    return item
end

---Sets the callback to use to create items given a player.
---@param target any?
---@param func? cache.Callback.CreatePlayerData<TData>
---@param ...any?
function PlayerCache:setOnCreatePlayerData(target, func, ...)
    self.callbacks.createPlayerData = callback(target, func --[[@as function]], ...)
end

---Updates the cache with the player's information.
---@param player IsoPlayer
---@return TData
function PlayerCache:updatePlayer(player)
    local data = self:createPlayerData(player)
    self:setByIndex('onlineID', data.onlineID, data)

    return data
end


---Creates a new player cache.
---@generic T : PlayerCacheData
---@param args Args.PlayerCache<T>?
---@return PlayerCache<T>
function PlayerCache:new(args)
    ---@diagnostic disable-next-line: cast-type-mismatch
    args = core.copy(args)
    args.primaryKey = args.primaryKey or 'onlineID'

    local indexes = core.copyList(args.indexes)
    if not core.includes(indexes, 'onlineID') then
        indexes[#indexes + 1] = 'onlineID'
    end

    if not core.includes(indexes, 'username') then
        indexes[#indexes + 1] = 'username'
    end

    args.indexes = indexes

    local this = core.new(self, Cache.new, args)

    this:setOnCreatePlayerData(
        args.onCreatePlayerDataTarget or args.target,
        args.onCreatePlayerData,
        unpack(args.onCreatePlayerDataArgs or {})
    )

    return this
end


return PlayerCache

--#region Type Definitions

---@class Args.PlayerCache<TData : PlayerCacheData> : Args.Cache.Base<TData>
---@field primaryKey? string The primary key to index cache items by. Defaults to `onlineID`.
---@field onCreatePlayerData? cache.Callback.CreatePlayerData<TData> Invoked to create player data given a player.
---@field onCreatePlayerDataArgs? table Arguments for `onCreatePlayerData`.
---@field onCreatePlayerDataTarget? any The first argument to pass to the `onCreatePlayerData` callback.


---@class PlayerCache.Callbacks : Cache.Callbacks
---@field createPlayerData? CallbackInfo Invoked to create cache item data for a player.

---@class PlayerCacheData
---@field username string The username of the player.
---@field forename string The forename of the player.
---@field surname string The surname of the player.
---@field onlineID integer The player's online ID.
---@field speechColor ColorTable<integer> An RGB table representing the player's speech color.
---@field faction? string The name of the player's faction.


---@alias cache.Callback.CreatePlayerData<T> fun(target: any?, player: IsoPlayer): T?

--#endregion
