---Overrides for `Core` to track option values.
---@diagnostic disable: access-invisible

local color = require 'OmiLibrary/Module/Color'
local _Core = __classmetatables[Core.class].__index ---@type any
local _setBad = _Core.setBadHighlitedColor
local _setGood = _Core.setGoodHighlitedColor

function _Core:setBadHighlitedColor(...)
    -- luacov: disable
    _setBad(...)
    color._updateBad()
    -- luacov: enable
end

function _Core:setGoodHighlitedColor(...)
    -- luacov: disable
    _setGood(...)
    color._updateGood()
    -- luacov: enable
end
