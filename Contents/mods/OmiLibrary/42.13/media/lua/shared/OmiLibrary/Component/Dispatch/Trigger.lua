---Conditions for automatically triggering a request.
---@namespace omi

---@class dispatch.trigger
local Trigger = {}

---@enum Trigger.Type
Trigger.Type = {
    EveryDay = 'EveryDay',
    EveryHour = 'EveryHour',
    EveryTenMinutes = 'EveryTenMinutes',
    EveryMinute = 'EveryMinute',
    Interval = 'Interval',
    PlayerDeath = 'PlayerDeath',
    PlayerJoined = 'PlayerJoined',
}


---Trigger to send a request at midnight of every in-game day.
---@return Trigger
function Trigger.everyDay()
    return Trigger._create('EveryDay')
end

---Trigger to send a request at the start of every in-game hour.
---@return Trigger
function Trigger.everyHour()
    return Trigger._create('EveryHour')
end

---Trigger to send a request every ten in-game minutes.
---@return Trigger
function Trigger.everyTenMinutes()
    return Trigger._create('EveryTenMinutes')
end

---Trigger to send a request every in-game minute.
---@return Trigger
function Trigger.everyMinute()
    return Trigger._create('EveryMinute')
end

---Trigger to send a request every `interval` milliseconds.
---@param interval integer The interval on which a request should be sent on the channel.
---@return Trigger
function Trigger.onInterval(interval)
    local options = { interval = interval } ---@type TriggerOptions.Interval
    return Trigger._create('Interval', options)
end

---Triggers a request when a player joins the server.
---The trigger is fired on the first tick for which player 1 is available.
---This only works on the client.
---@return Trigger
function Trigger.onPlayerJoined()
    return Trigger._create('PlayerJoined')
end

---Triggers a request when a player dies.
---This only works on the client.
---@param options TriggerOptions.PlayerDeath?
---@return Trigger
function Trigger.onPlayerDeath(options)
    return Trigger._create('PlayerDeath', options)
end


---Creates a trigger.
---@param type Trigger.Type
---@param options table?
---@return Trigger
---@protected
function Trigger._create(type, options)
    ---@type Trigger
    local trigger = {
        type = type,
        options = options or {},
    }

    return trigger
end


return Trigger

--#region Type Definitions

---@class Trigger
---@field type Trigger.Type The type of the trigger.
---@field options table Options that were passed to the trigger.

---@class TriggerOptions.Event
---@field event string The event to listen for.

---@class TriggerOptions.Interval
---@field interval integer The interval on which on which a request should be sent on the channel.

---@class TriggerOptions.PlayerDeath
---@field onlyPlayer1 boolean If `true`, the condition will trigger only for player 1.

--#endregion
