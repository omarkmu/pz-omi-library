---Handles invoking callbacks after a delay.
---@namespace omi
---@diagnostic disable: access-invisible

local class = require 'OmiLibrary/Module/Class'
local callback = require 'OmiLibrary/Module/Callback'
local Timer = require 'OmiLibrary/Component/Core/Timer'

local pairs = pairs
local pcall = pcall
local getTimestampMs = getTimestampMs
local IS_SERVER = isServer()


---@class Scheduler : Class
---@field protected _tickTimers Timer[] Timers to be checked on every tick.
---@field protected _uiUpdateTimers Timer[] Timers to be checked on every UI update.
---@field protected _uiIntervalTimers table<Timer, true> Timers to be executed on every UI update.
---@field protected _instance? ISUIElement The UI element used to get updates. Only exists on the client.
---@field protected _onTickListener? function The current listener for `OnTickEvenPaused`.
local Scheduler = class('Scheduler')


---Cancels all timers managed by the scheduler.
function Scheduler:clear()
    for i = 1, #self._tickTimers do
        self._tickTimers[i]:cancel()
    end

    for i = 1, #self._uiUpdateTimers do
        self._uiUpdateTimers[i]:cancel()
    end

    for timer in pairs(self._uiIntervalTimers) do
        timer:cancel()
        self._uiIntervalTimers[timer] = nil
    end

    self._tickTimers = {}
    self._uiUpdateTimers = {}
    self._uiIntervalTimers = {}
    self:_disconnectOnTick()
end

---Sets a function to be called every `interval` milliseconds.
---@param interval integer
---@param func function
---@param ...any
---@return Timer
function Scheduler:setInterval(interval, func, ...)
    return self:_add('interval', interval, func, ...)
end

---Sets a function to be called on every UI update.
---This can only be used on the client.
---@param func function
---@param ...any
---@return Timer
function Scheduler:setIntervalUI(func, ...)
    if IS_SERVER then
        error('setIntervalUI cannot be used on the server')
    end

    return self:_add('ui', 0, func, ...)
end

---Sets a function to be called after `delay` milliseconds.
---@param delay integer
---@param func function
---@param ...any
---@return Timer
function Scheduler:setTimeout(delay, func, ...)
    return self:_add('timeout', delay, func, ...)
end


---Adds an interval or timeout to the scheduler.
---@param timerType TimerType
---@param value integer
---@param func function
---@param ...any
---@return Timer
---@protected
function Scheduler:_add(timerType, value, func, ...)
    if not func then
        error('Cannot add a timer with no callback')
    end

    ---@type Timer
    local timer = setmetatable({
        value = value,
        target = timerType == 'ui' and 0 or (getTimestampMs() + value),
        isInterval = timerType ~= 'timeout',
        isCancelled = false,
        func = callback(..., func, select(2, ...)) --[[@as CallbackInfo]],
    }, Timer)

    if timerType ~= 'ui' then
        -- timers <250ms run on tick, otherwise on UI update
        -- server can't use UI update timers, so all timers will be tied to tick
        if IS_SERVER or value < 250 then
            self._tickTimers[#self._tickTimers + 1] = timer
            self:_connectOnTick()
            return timer
        end

        self._uiUpdateTimers[#self._uiUpdateTimers + 1] = timer
    else
        self._uiIntervalTimers[timer] = true
    end

    return timer
end

---Connects a listener for `OnTickEvenPaused`.
---@protected
function Scheduler:_connectOnTick()
    if self._onTickListener then
        Events.OnTickEvenPaused.Remove(self._onTickListener)
    end

    self._onTickListener = function() self:_update(false) end
    Events.OnTickEvenPaused.Add(self._onTickListener)
end

---Disconnects the listener for `OnTickEvenPaused`.
---@protected
function Scheduler:_disconnectOnTick()
    if self._onTickListener then
        Events.OnTickEvenPaused.Remove(self._onTickListener)
        self._onTickListener = nil
    end
end

---Sets up the UI element used to capture UI updates.
---Should only be called on the client.
---@protected
function Scheduler:_createUI()
    local instance = self._instance
    if not instance then
        instance = ISUIElement:new(0, 0, 0, 0)
        instance.update = function() self:_update(true) end
        instance:initialise()
        self._instance = instance
    end

    instance:addToUIManager()
    instance:setVisible(false)
end

---Invokes a timer's callback.
---@param timer Timer
---@protected
function Scheduler:_invoke(timer)
    local s, e = callback.safeInvoke(timer.func)
    if not s then
        -- display error but continue
        pcall(error, e)
    end
end

---Updates timers, invoking callbacks as appropriate.
---@param isUI boolean If `true`, this is a UI update.
---@protected
function Scheduler:_update(isUI)
    if isUI then
        for timer in pairs(self._uiIntervalTimers) do
            if not timer.isCancelled then
                self:_invoke(timer)
            else
                self._uiIntervalTimers[timer] = nil
            end
        end
    end

    local currentList = isUI and self._uiUpdateTimers or self._tickTimers
    if #currentList == 0 then
        if not isUI then
            self:_disconnectOnTick()
        end

        return
    end

    local updateList = {}
    local swapList = {}
    local now = getTimestampMs()

    -- ugly loop for fewer calls on tick
    for i = 1, #currentList do
        local timer = currentList[i]
        if timer.isCancelled then
            -- skip, will be removed
        elseif now < timer.target then
            -- swap from UI to tick when <250ms & not on server
            if not IS_SERVER and isUI and timer.target - now < 250 then
                swapList[#swapList + 1] = timer
            else
                updateList[#updateList + 1] = timer
            end
        else
            self:_invoke(timer)

            if timer.isInterval then
                timer.target = now + timer.value

                -- swap from tick to UI when >250ms & not on server
                if IS_SERVER or isUI or timer.value < 250 then
                    updateList[#updateList + 1] = timer
                else
                    swapList[#swapList + 1] = timer
                end
            else
                timer.isCancelled = true
            end
        end
    end

    if isUI then
        self._uiUpdateTimers = updateList

        if #swapList > 0 then
            for i = 1, #swapList do
                self._tickTimers[#self._tickTimers + 1] = swapList[i]
            end

            self:_connectOnTick()
        end
    else
        self._tickTimers = updateList

        for i = 1, #swapList do
            self._uiUpdateTimers[#self._uiUpdateTimers + 1] = swapList[i]
        end
    end
end


---Creates a new scheduler.
---@return Scheduler
function Scheduler:new()
    ---@type Scheduler
    local this = setmetatable({}, self)

    this._tickTimers = {}
    this._uiUpdateTimers = {}
    this._uiIntervalTimers = {}

    if not IS_SERVER then
        Events.OnGameBoot.Add(function() this:_createUI() end)
        Events.OnGameStart.Add(function() this:_createUI() end)
    end

    return this
end


return Scheduler

--#region Type Definitions

---@alias TimerType
---| 'timeout'
---| 'interval'
---| 'ui'

--#endregion
