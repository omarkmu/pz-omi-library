---UI element for a button.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/UI/Core'


local max = math.max
local textManager = getTextManager()


---@class Button : ISButton, BaseUI
---@field title string The button text.
---@field internal? string The internal identifier for the button.
---@field tooltip? string The tooltip to show when hovering over the button.
---@field font UIFont The font to use for the button.
---@field image? Texture An image to display on the button.
---@field textColor ColorTableRGBA<number> The color to use for button text.
---@field textureColor ColorTableRGBA<number> The color to use for the button image.
---@field borderColor ColorTableRGBA<number> The color to use for the button border.
---@field backgroundColor ColorTableRGBA<number> The color to use for the button background.
---@field backgroundColorMouseOver ColorTableRGBA<number> The color to use for the button background while the mouse is over the button.
---@field background? boolean Whether the background should be rendered.
---@field protected callbacks Button.Callbacks Container for callbacks.
---@field protected __base ISButton The base class.
local Button = UI.class('OmiButton', ISButton)


---Invoked when the button is resized.
function Button:onResize()
    Button.__base.onResize(self)
    core.callback.invoke(self.callbacks.resize)
end

---Sets the enabled state of the button.
---@param enabled boolean
function Button:setEnabled(enabled)
    self:setEnable(enabled)
end

---Sets a callback to be invoked when the button is clicked.
---@param target any?
---@param callback Callback.Button.Click?
---@param ...any
function Button:setOnClick(target, callback, ...)
    self.callbacks.click = core.callback(target, callback, ...)
end

---Sets a callback to be invoked when the mouse button is pressed over the button.
---@param target any?
---@param callback Callback.Button.Mouse?
---@param ...any
function Button:setOnMouseDown(target, callback, ...)
    self.callbacks.mouseDown = core.callback(target, callback, ...)
end

---Sets a callback to be invoked when the the mouse button moves out of the button.
---@param target any?
---@param callback Callback.Button.MouseOut?
---@param ...any
function Button:setOnMouseOut(target, callback, ...)
    self.callbacks.mouseOut = core.callback(target, callback, ...)
end

---@deprected Use `setOnMouseOut`.
function Button:setOnMouseOutFunction(callback)
    self:setOnMouseOut(self, callback)
end

---Sets a callback to be invoked when the the mouse button moves over the button.
---@param target any?
---@param callback Callback.Button.Mouse?
---@param ...any
function Button:setOnMouseOver(target, callback, ...)
    self.callbacks.mouseOver = core.callback(target, callback, ...)
end

---@deprected Use `setOnMouseOver`.
function Button:setOnMouseOverFunction(callback)
    self:setOnMouseOver(self, callback)
end

---Sets a callback to be invoked when the button is resized.
---@param target any?
---@param callback Callback.Button.Resize?
---@param ...any
function Button:setOnResize(target, callback, ...)
    self.callbacks.resize = core.callback(target, callback, ...)
end


---Triggered when the button is clicked.
---@protected
function Button:_onClick()
    core.callback.invoke(self.callbacks.click, self)
end

---Triggered when the mouse button is pressed over the button.
---@param target any?
---@param x number
---@param y number
---@protected
---@diagnostic disable-next-line: unused
function Button:_onMouseDown(target, x, y)
    core.callback.invoke(self.callbacks.mouseDown, self, x, y)
end

---Triggered when the mouse button moves out of the button.
---@param target any?
---@param dx number
---@param dy number
---@protected
---@diagnostic disable-next-line: unused
function Button:_onMouseOut(target, dx, dy)
    core.callback.invoke(self.callbacks.mouseOut, self, dx, dy)
end

---Triggered when the mouse button moves over the button.
---@param target any?
---@param x number
---@param y number
---@protected
---@diagnostic disable-next-line: unused
function Button:_onMouseOver(target, x, y)
    core.callback.invoke(self.callbacks.mouseOut, self, x, y)
end


---Creates a new button.
---@param args Args.Button
---@return Button
function Button:new(args)
    local x = args.x or 0
    local y = args.y or 0
    local w = args.w
    local h = args.h
    local text = args.text or ''
    local font = args.font or UIFont.Small
    local minW = args.minWidth or 0
    local minH = args.minHeight or 0

    local imageOnly = args.image and text == ''
    if not w then
        if imageOnly then ---@cast args.image -?
            w = args.image:getWidth()
        else
            w = max(minW, textManager:MeasureStringX(font, text) + 10)
        end
    end

    if not h then
        if imageOnly then ---@cast args.image -?
            h = args.image:getHeight()
        else
            h = max(minH, textManager:getFontHeight(font) + 10)
        end
    end

    local this = UI.new(self, Button.__base.new, x, y, w, h, text)
    this:_setBaseArgs(args)

    this.font = font
    this.tooltip = args.tooltip
    this.internal = args.internal
    this.image = args.image
    this.allowMouseUpProcessing = args.processMouseUp
    this.enable = args.enable ~= false
    this.displayBackground = args.background ~= false
    this.borderColor = core.color.defaultRGBA(args.borderColor, 1, 1, 1, 0.2)
    this.backgroundColor = args.backgroundColor or this.backgroundColor
    this.backgroundColorMouseOver = args.backgroundColorMouseOver or this.backgroundColorMouseOver
    this.textColor = args.textColor or this.textColor
    this.textureColor = args.textureColor or this.textureColor

    this.callbacks = {}
    this.onClickArgs = {}
    this.target = this
    this.onclick = this._onClick
    this.onmousedown = this._onMouseDown
    this.onmouseoutfunction = this._onMouseOut
    this.onmouseover = this._onMouseOver
    this:setOnClick(args.onClickTarget or args.target, args.onClick, unpack(args.onClickArgs or {}))
    this:setOnMouseDown(args.onMouseDownTarget or args.target, args.onMouseDown, unpack(args.onMouseDownArgs or {}))
    this:setOnMouseOut(args.onMouseOutTarget or args.target, args.onMouseOut, unpack(args.onMouseOutArgs or {}))
    this:setOnMouseOver(args.onMouseOverTarget or args.target, args.onMouseOver, unpack(args.onMouseOverArgs or {}))
    this:setOnResize(args.onResizeTarget or args.target, args.onResize, unpack(args.onResizeArgs or {}))

    if args.setWidthToText then
        this:setWidthToTitle(this.minimumWidth)
        this.x = x
    end

    if args.useAcceptStyle then
        this:enableAcceptColor()
    elseif args.useCancelStyle then
        this:enableCancelColor()
    end

    return this
end


return Button

--#region Type Definition

---@class Args.Button : Args.BaseUI
---@field text? string The button text.
---@field internal? string The internal identifier for the button.
---@field tooltip? string The tooltip to show when hovering over the button.
---@field font? UIFont The font to use for the button.
---@field image? Texture An image to display on the button.
---@field textColor? ColorTableRGBA<number> The color to use for text.
---@field textureColor? ColorTableRGBA<number> The color to use for the image.
---@field borderColor? ColorTableRGBA<number> The color to use for the border.
---@field backgroundColor? ColorTableRGBA<number> The color to use for the background.
---@field backgroundColorMouseOver? ColorTableRGBA<number> The color to use for the background while the mouse is over the button.
---@field processMouseUp? boolean If `true`, the click callback will be called when the mouse is released on the button, even if it wasn't pressed on the button.
---@field background? boolean Whether the background should be rendered.
---@field enable? boolean Whether the button should be enabled.
---@field setWidthToText? boolean If `true`, the width of the button will be set to the minimum to fit the button text. The minimum width will be respected.
---@field useAcceptStyle? boolean Flag for whether the standard 'accept' style should be applied when creating the button.
---@field useCancelStyle? boolean Flag for whether the standard 'accept' style should be applied when creating the button.
---@field onMouseDown? Callback.Button.Mouse Invoked when the mouse is pressed on the button.
---@field onMouseDownArgs? table Arguments for `onMouseDown`.
---@field onMouseDownTarget? any The first argument to pass to the `onMouseDown` callback.
---@field onMouseOut? Callback.Button.MouseOut Invoked when the mouse moves out of the button.
---@field onMouseOutArgs? table Arguments for `onMouseOut`.
---@field onMouseOutTarget? any The first argument to pass to the `onMouseOut` callback.
---@field onMouseOver? Callback.Button.Mouse Invoked while the mouse is over the button.
---@field onMouseOverArgs? table Arguments for `onMouseOver`.
---@field onMouseOverTarget? any The first argument to pass to the `onMouseOver` callback.
---@field onResize? Callback.Button.Resize Invoked when the button is resized.
---@field onResizeArgs? table Arguments for `onResize`.
---@field onResizeTarget? any The first argument to pass to the `onResize` callback.
---@field onClick? Callback.Button.Click Invoked on button click.
---@field onClickArgs? table Arguments for `onClick`.
---@field onClickTarget? any The first argument to pass to the `onClick` callback.
---@field target? any The default first argument to use for callbacks when a target is unspecified.

---@class InitArgs.Button : Args.Button, InitArgs.Shared


---@class Button.Callbacks
---@field click? CallbackInfo Invoked on button click.
---@field mouseDown? CallbackInfo Invoked when the mouse is pressed on the button.
---@field mouseOut? CallbackInfo Invoked when the mouse moves out of the button.
---@field mouseOver? CallbackInfo Invoked while the mouse is over the button.
---@field resize? CallbackInfo Invoked when the button is resized.


---@alias Callback.Button.Click fun(target: any?, button: Button, ...: any)

---@alias Callback.Button.Mouse fun(target: any?, button: Button, x: number, y: number, ...: any)

---@alias Callback.Button.MouseOut fun(target: any?, button: Button, dx: number, dy: number, ...: any)

---@alias Callback.Button.Resize fun(target: any?, button: Button, ...: any)

--#endregion
