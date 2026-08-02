---Individual timer for use by the scheduler.
---@namespace omi

local class = require 'OmiLibrary/Module/Class'


---@class Timer
---@field protected value integer The delay or interval value for the timer. For UI interval timers, `0`.
---@field protected target integer The target time, as a milliseconds timestamp, to execute the callback. For UI interval timers, `0`.
---@field protected isInterval boolean Whether the timer should be automatically restarted.
---@field protected isCancelled boolean Whether the timer was cancelled.
---@field protected func CallbackInfo The callback of the timer.
local Timer = class('Timer') --[[@as Timer]]


---Cancels the timer.
function Timer:cancel()
    self.isCancelled = true
end


return Timer
