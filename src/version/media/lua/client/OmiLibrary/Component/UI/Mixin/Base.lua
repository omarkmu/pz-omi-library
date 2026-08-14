---Mixin with base functionality shared among UI elements.
---This should not be used directly; use `UI.class`.
---@namespace omi

local core = require 'OmiLibrary'
local Destroyable = require 'OmiLibrary/Component/UI/Mixin/Destroyable'

local min = math.min


---@class BaseUI : ISUIElement, Mixin.Destroyable
---@field x number The X position of the element.
---@field y number The Y position of the element.
---@field width number The width of the element.
---@field height number The height of the element.
---@field parent? ISUIElement The parent element.
---@field minimumWidth number The minimum width of the element.
---@field minimumHeight number The minimum height of the element.
---@field anchorLeft boolean Whether the element's position should be anchored relative to the left of its parent.
---@field anchorRight boolean Whether the element's position should be anchored relative to the right of its parent.
---@field anchorTop boolean Whether the element's position should be anchored relative to the top of its parent.
---@field anchorBottom boolean Whether the element's position should be anchored relative to the bottom of its parent.
---@field playerNum integer The player number of the owning player.
---@field joypadNavigate? table<string, ISUIElement?> Targets for joypad navigation.
---@field protected __base ISUIElement The base class.
---@field keepOnScreen boolean? Flag for whether setX and setY should be limited to the screen size.
local Base = core.extend({}, Destroyable)


---Override for `clampStencilRectToParent` to fix logic error in clamp functions.
---@param x number
---@param y number
---@param w number
---@param h number
---@return number
---@return number
---@return number
---@return number
function Base:clampStencilRectToParent(x, y, w, h)
    local obj = self.javaObject
    if not obj then
        self:instantiate()
    end

    local parent = self.parent ---@type any
    if not parent then
        obj:setStencilRect(x, y, w, h)
        return x, y, w, h
    end

    local absX = self:getAbsoluteX()
    local absY = self:getAbsoluteY()
    local x2, y2 = x + w, y + h
    if parent:isVScrollBarVisible() then
        x2 = min(x2, parent.width - parent.vscroll.width)
    end

    x = self:_clampToParentX(absX + x) - absX
    x2 = self:_clampToParentX(absX + x2) - absX
    y = self:_clampToParentY(absY + y) - absY
    y2 = self:_clampToParentY(absY + y2) - absY

    w = x2 - x
    h = y2 - y

    self:setStencilRect(x, y, w, h)
    return x, y, w, h
end

---Derives a base class and injects a reference to the base type.
---@param type string The name of the new type.
---@param ...table Additional mixins to add.
---@return BaseUI cls
function Base:derive(type, ...)
    local cls = ISBaseObject.derive(self, type) --[[@as BaseUI]]
    cls.__base = self

    return core.extend(cls, ...)
end

---Gets the player number of the owner of this UI element.
---@return integer
function Base:getPlayerNum()
    return self.playerNum or 0
end

---Sets the width and height of the element.
---@param w number
---@param h number
function Base:setSize(w, h)
    self:setWidth(w)
    self:setHeight(h)
end


---Clamps an absolute X value to the parent area.
---@param x number
---@return number
---@protected
function Base:_clampToParentX(x)
    local parent = self:getParent()
    if not parent then
        return x
    end

    local absX = parent:getAbsoluteX()
    local minVal = Base._clampToParentX(parent, absX)
    local maxVal = Base._clampToParentX(parent, absX + parent:getWidth())

    if x < minVal then
        x = minVal
    end

    if x > maxVal then
        x = maxVal
    end

    return x
end

---Clamps an absolute Y value to the parent area.
---@param y number
---@return number
---@protected
function Base:_clampToParentY(y)
    local parent = self:getParent()
    if not parent then
        return y
    end

    local absY = parent:getAbsoluteY()
    local minVal = Base._clampToParentY(parent, absY)
    local maxVal = Base._clampToParentY(parent, absY + parent:getHeight())

    if y < minVal then
        y = minVal
    end

    if y > maxVal then
        y = maxVal
    end

    return y
end

---Sets the values for base arguments, excluding position and size arguments.
---@param args Args.BaseUI
---@protected
function Base:_setBaseArgs(args)
    self.playerNum = args.playerNum or self.playerNum or 0
    self.minimumWidth = args.minWidth or self.minimumWidth or 0
    self.minimumHeight = args.minHeight or self.minimumHeight or 0
    self.anchorLeft = args.anchorLeft ~= false
    self.anchorRight = args.anchorRight or false
    self.anchorTop = args.anchorTop ~= false
    self.anchorBottom = args.anchorBottom or false
    self.joypadNavigate = args.joypadNavigate and core.copy(args.joypadNavigate) or self.joypadNavigate
    self.keepOnScreen = core.default(args.keepOnScreen, self.keepOnScreen)
end


return Base

--#region Type Definitions

---@class Args.BaseUI
---@field x? number The X position of the element.
---@field y? number The Y position of the element.
---@field w? number The width of the element.
---@field h? number The height of the element.
---@field minWidth? number The minimum width of the element.
---@field minHeight? number The minimum height of the element.
---@field anchorLeft? boolean Whether the element's position should be anchored relative to the left of its parent.
---@field anchorRight? boolean Whether the element's position should be anchored relative to the right of its parent.
---@field anchorTop? boolean Whether the element's position should be anchored relative to the top of its parent.
---@field anchorBottom? boolean Whether the element's position should be anchored relative to the bottom of its parent.
---@field playerNum? integer The player number of the player who owns the element.
---@field joypadNavigate? umbrella.JoypadNavigate Targets for joypad navigation.
---@field keepOnScreen? boolean Flag for whether setX and setY should be limited to the screen size.

--#endregion
