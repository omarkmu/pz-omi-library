---UI element for a panel to contain other elements.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/UI/Core'
local Mixin = require 'OmiLibrary/Module/UI/Mixin'


---@class Panel : Mixin.Scrollable, BaseUI, ISPanelJoypad
---@field borderColor ColorTableRGBA<number> The border color to use for the panel.
---@field backgroundColor ColorTableRGBA<number> The background color to use for the panel.
---@field protected clip boolean If `true`, the panel will draw a stencil rect around its contents.
---@field protected clipPrerender boolean If `true`, the stencil rect will be applied during prerender.
---@field protected savedStencil? [number, number, number, number] The saved stencil to be repainted.
---@field protected doOriginalPrerender boolean If `true`, `ISPanelJoypad.prerender` will be called during prerender.
---@field protected doOriginalRender boolean If `true`, `ISPanelJoypad.render` will be called during render.
---@field protected doRepaintStencil boolean If `true`, the stencil rect will be repainted after rendering.
---@field protected callbacks Panel.Callbacks The registered callbacks.
---@field protected __base ISPanelJoypad The base class.
local Panel = UI.class('OmiPanel', ISPanelJoypad, Mixin.Scrollable)


---Called when the panel is resized.
function Panel:onResize()
    Panel.__base.onResize(self)
    core.callback.invoke(self.callbacks.resize)
end

---Handles prerendering for the panel.
function Panel:prerender()
    if self.doOriginalPrerender then
        Panel.__base.prerender(self)
    end

    self:_updateSmoothScrolling()

    if self.clip and self.clipPrerender then
        self.savedStencil = { self:clampStencilRectToParent(0, 0, self.width or 0, self.height or 0) }
    end
end

---Handles rendering for the panel.
function Panel:render()
    if self.clip and not self.clipPrerender then
        self.savedStencil = { self:clampStencilRectToParent(0, 0, self.width or 0, self.height or 0) }
    end

    if self.doOriginalRender then
        Panel.__base.render(self)
    end

    if self.clip then
        self:clearStencilRect()

        if self.doRepaintStencil and self.savedStencil then
            self:repaintStencilRect(unpack(self.savedStencil))
        end
    end
end

---Sets a callback to be invoked when the panel is resized.
---@param target any?
---@param callback UICallback?
---@param ...any
function Panel:setOnResize(target, callback, ...)
    self.callbacks.resize = core.callback(target, callback, ...)
end


---Creates a new panel.
---@param args Args.Panel
---@return Panel
function Panel:new(args)
    local x = args.x or 0
    local y = args.y or 0
    local w = args.w or 0
    local h = args.h or 0

    local this = UI.new(self, Panel.__base.new, x, y, w, h)
    this:_setBaseArgs(args)
    this:_setScrollArgs(args, { handleScrolling = false })

    this.moveWithMouse = args.moveWithMouse or false
    this.background = args.background ~= false
    this.borderColor = args.borderColor or this.borderColor
    this.backgroundColor = args.backgroundColor or this.backgroundColor

    this.clip = args.clip ~= false
    this.clipPrerender = args.clipPrerender ~= false
    this.doOriginalPrerender = true
    this.doOriginalRender = true
    this.doRepaintStencil = args.doRepaintStencil or false

    this.callbacks = {}
    this:setOnResize(args.onResizeTarget or args.target, args.onResize, unpack(args.onResizeArgs or {}))

    return this
end


return Panel

--#region Type Definitions

---@class Args.Panel : Args.BaseUI, Args.Mixin.Scrollable
---@field moveWithMouse? boolean If `true`, the panel will be moveable with the mouse. Defaults to `true`.
---@field background? boolean If `true`, a background will be rendered. Defaults to `true`.
---@field borderColor? ColorTableRGBA<number> The border color to use for the panel.
---@field backgroundColor? ColorTableRGBA<number> The background color to use for the panel.
---@field handleScrolling? boolean If `true`, the panel will scroll its contents when the mouse is scrolled. Defaults to `false`.
---@field clip? boolean If `true`, the panel will draw a stencil rect around its contents. Defaults to `true`.
---@field clipPrerender? boolean If `true`, the stencil rect will be applied during prerender. Defaults to `true`.
---@field doRepaintStencil? boolean If `true`, the stencil rect will be repainted after rendering.
---@field onResize? UICallback Invoked when the panel is resized.
---@field onResizeArgs? table Arguments for `onResize`.
---@field onResizeTarget? any The first argument to pass to the `onResize` callback.
---@field target? any The default first argument to use for callbacks when a target is unspecified.

---@class InitArgs.Panel : Args.Panel, InitArgs.Shared


---@class Panel.Callbacks
---@field resize? CallbackInfo Invoked when the panel is resized.

--#endregion
