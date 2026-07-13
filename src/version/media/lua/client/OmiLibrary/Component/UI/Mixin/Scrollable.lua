---Mixin with functionality for scrolling within an element.
---@namespace omi

local core = require 'OmiLibrary'

local abs = math.abs
local getMillisSinceLastRender = UIManager.getMillisSinceLastRender


---@class Mixin.Scrollable : ISUIElement
---@field protected _handleScrolling? boolean Whether the element should respond to the scroll wheel. Defaults to `true`.
---@field protected _scrollMultiplier? number A multiplier to apply to the scroll delta. Defaults to `40`.
---@field protected _scrollingChildren? SetTable<ISUIElement> A set of child elements that should be checked for scrolling.
---@field protected _doSmoothScroll? boolean If `true`, the element will smooth scroll. Defaults to `true`.
---@field protected _lastYScroll? number The previous y scroll value. Used for smooth scrolling.
---@field protected _smoothScrollTargetY? number The target Y for smooth scrolling.
---@field protected _smoothScrollSpeed? number The speed at which the smooth scroll should scroll. Defaults to `0.25`.
local Scrollable = {}


---Event handler for mouse scroll.
---@param delta number
---@return boolean?
function Scrollable:onMouseWheel(delta)
    if self._handleScrolling == false or not self:isVScrollBarVisible() then
        return
    end

    if self._scrollingChildren then
        for target in pairs(self._scrollingChildren) do
            if target:isVScrollBarVisible() and target:isMouseOver() then
                local yScroll = target:getYScroll()
                if delta < 0 and yScroll ~= 0 then
                    -- scrolling up → don't process unless at top of target
                    return
                elseif delta > 0 then
                    local maxScroll = target:getScrollHeight() - target:getScrollAreaHeight() - 2
                    if -yScroll < maxScroll then
                        -- scrolling down → don't process unless at bottom of target
                        return
                    end
                end
            end
        end
    end

    local isSmoothScroll = self._doSmoothScroll ~= false
    local yScroll = isSmoothScroll and self._smoothScrollTargetY or self:getYScroll()
    local targetY = yScroll - delta * (self._scrollMultiplier or 40)

    if isSmoothScroll then
        if not self._smoothScrollTargetY then
            self._lastYScroll = yScroll
        end

        self._smoothScrollTargetY = targetY
    else
        self:setYScroll(targetY)
    end

    return true
end

---Updates smooth scrolling for the scrollable element.
function Scrollable:prerender()
    self:_updateSmoothScrolling()
end

---Registers a child element as one that should receive scrolling events when the mouse is over it.
---@param element ISUIElement The element to register.
---@param recursive boolean? Whether scrolling children of the element should be recursively registered.
function Scrollable:registerScrollingChild(element, recursive)
    self._scrollingChildren = self._scrollingChildren or {}
    self._scrollingChildren[element] = true

    ---@cast element Mixin.Scrollable
    if recursive and element._scrollingChildren then
        for el in pairs(element._scrollingChildren) do
            self:registerScrollingChild(el, true)
        end
    end
end

---Unregisters an element as a scrolling child element.
---@param element ISUIElement The element to unregister.
---@param recursive boolean? Whether scrolling children of the element should be recursively unregistered.
function Scrollable:unregisterScrollingChild(element, recursive)
    if not self._scrollingChildren or not self._scrollingChildren[element] then
        return
    end

    self._scrollingChildren[element] = nil

    ---@cast element Mixin.Scrollable
    if recursive and element._scrollingChildren then
        for el in pairs(element._scrollingChildren) do
            self:unregisterScrollingChild(el)
        end
    end
end


---Sets values for scrollable arguments.
---@param args Args.Mixin.Scrollable
---@param defaults Args.Mixin.Scrollable?
---@protected
function Scrollable:_setScrollArgs(args, defaults)
    if not defaults then
        defaults = {
            scrollMultiplier = self._scrollMultiplier or 40,
            handleScrolling = true,
        }
    end

    self._scrollMultiplier = args.scrollMultiplier
        or defaults.scrollMultiplier
        or self._scrollMultiplier
        or 40

    if args.handleScrolling ~= nil then
        self._handleScrolling = args.handleScrolling
    elseif defaults.handleScrolling ~= nil then
        self._handleScrolling = defaults.handleScrolling
    elseif self._handleScrolling == nil then
        self._handleScrolling = true
    end
end

---Updates smooth scrolling for the scrollable element.
---@protected
function Scrollable:_updateSmoothScrolling()
    local scrollTarget = self._smoothScrollTargetY
    if not scrollTarget then
        return
    end

    local lastY = self._lastYScroll or self:getYScroll()
    local dy = scrollTarget - lastY
    local frameRateFrac = getMillisSinceLastRender() / 33.3

    local multiplier = frameRateFrac * (self._smoothScrollSpeed or 0.25)
    if multiplier > 1 then
        multiplier = 1
    elseif multiplier < 0.05 then
        multiplier = 0.05
    end

    local maxScroll = self:getScrollHeight() - self:getScrollAreaHeight()
    local targetY = core.clamp(lastY + dy * multiplier, -maxScroll, 0)
    if abs(targetY - lastY) > 0.1 then
        self:setYScroll(targetY)
        self._lastYScroll = targetY
    else
        self:setYScroll(scrollTarget)
        self._lastYScroll = nil
        self._smoothScrollTargetY = nil
    end
end


return Scrollable


--#region Type Definition

---@class Args.Mixin.Scrollable
---@field handleScrolling? boolean If `true`, the panel will scroll its contents when the mouse is scrolled. Defaults to `true`.
---@field scrollMultiplier? number A multiplier to apply to the scroll delta. Defaults to `40`.
---@field doSmoothScroll? boolean If `true`, the element will smooth scroll. Defaults to `true`.

--#endregion
