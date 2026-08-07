---UI element for a checkbox group.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/Core/UI'

local UI_BORDER_SPACING = 10
local textManager = getTextManager()


---@class CheckboxGroup : ISTickBox, BaseUI
---@field tooltip? string The tooltip to show when hovering over a checkbox.
---@field font UIFont The font to use for the text.
---@field boxSize number The size of a checkbox box.
---@field textGap number The size of the gap between a checkbox and text.
---@field leftMargin number The margin to add to the left of the checkbox.
---@field itemTooltips table<integer, string> Tooltips to show for individual checkboxes.
---@field choicesColor ColorTableRGBA<number> The color to use for text.
---@field disabledChoicesColor ColorTableRGBA<number> The color to use for text when a checkbox is disabled.
---@field borderColor ColorTableRGBA<number> The color to use for the border.
---@field backgroundColor ColorTableRGBA<number> The color to use for the background.
---@field protected callbacks CheckboxGroup.Callbacks Container for callbacks.
---@field protected __base ISTickBox The base class.
local CheckboxGroup = UI.class('OmiCheckboxGroup', ISTickBox)


---Gets a set of the data associated with the selected values.
---@return SetTable
function CheckboxGroup:getSelectedSet()
    local set = {}

    for i = 1, #self.optionData do
        local data = self.optionData[i]
        if data ~= nil and self.selected[i] then
            set[data] = true
        end
    end

    return set
end

---Sets the color components of `color` based on the enabled state of the checkbox group.
---@param index integer
---@param color table | ColorTableRGBA<number>?
---@return ColorTableRGBA<number>
function CheckboxGroup:getTextColor(index, color)
    color = color or {}

    local text = self.optionsIndex[index]
    local target = self.disabledOptions[text] and self.disabledChoicesColor or self.choicesColor

    color.r = target.r
    color.g = target.g
    color.b = target.b
    color.a = target.a

    return color --[[@as ColorTableRGBA<number>]]
end

---Returns whether the checkbox at the given index is selected.
---@param index integer
---@return boolean
function CheckboxGroup:isSelected(index)
    if not index then
        return false
    end

    return self.selected[index] == true
end

---Renders the checkbox group.
---Modified code from `ISTickBox`.
function CheckboxGroup:render()
    local y = 0.0
    local textDY = (self.itemHgt - self.fontHgt) / 2
    self._textColor = self._textColor or { r = 1, g = 1, b = 1, a = 1 }

    local isMouseOver = self:isMouseOver()

    -- render options
    for i = 1, #self.options do
        local opt = self.options[i]
        if isMouseOver and self.enable and (i == self.mouseOverOption) and not self.disabledOptions[self.optionsIndex[self.mouseOverOption]] then
            self:drawRect(self.leftMargin, y, self.boxSize, self.boxSize, 1.0, 0.3, 0.3, 0.3)
        else
            self:drawRectBorder(self.leftMargin, y, self.boxSize, self.boxSize, self.borderColor.a,
                self.borderColor.r, self.borderColor.g, self.borderColor.b)
        end

        if self.joypadFocused and i == self.joypadIndex then
            self:drawRectBorder(self.leftMargin - 2, y - 2, self.width + 4, self.boxSize + 4, 1.0, 0.6, 0.6, 0.6)
            self:drawRect(self.leftMargin, y, self.boxSize, self.boxSize, 1.0, 0.3, 0.3, 0.3)
        end

        if self.selected[i] then
            local ghc = core.color.good01
            self:drawTextureScaled(self.tickTexture, self.leftMargin + 2, y + 2, self.boxSize - 4, self.boxSize - 4, 1,
                ghc.r, ghc.g, ghc.b)
        end

        local textColor = self._textColor
        self:getTextColor(i, textColor)

        local texture = self.textures[i]
        local textPad = 0
        if texture then
            textPad = 25
            local imgW = 20.0
            local imgH = 20.0

            local texW = texture:getWidth()
            local texH = texture:getHeight()

            if texW < 32 then
                imgW = (imgW * texW) / 32
            end

            if texH < 32 then
                imgH = (imgH * texH) / 32
            end

            self:drawTextureScaled(texture, self.leftMargin + self.boxSize + self.textGap, y,
                self.boxSize - 4, self.boxSize - 4, 1, 1, 1, 1)
        end

        self:drawText(opt, self.leftMargin + self.boxSize + self.textGap + textPad, y + textDY, textColor.r, textColor.g,
            textColor.b, textColor.a, self.font)

        y = y + self.itemHgt + UI_BORDER_SPACING
        i = i + 1
    end

    -- render tooltip
    local hasMouseOverItem = self.mouseOverOption and self.mouseOverOption ~= 0
    local tooltip = self.tooltip
    if hasMouseOverItem and self.itemTooltips[self.mouseOverOption] then
        tooltip = self.itemTooltips[self.mouseOverOption]
    end

    if isMouseOver and tooltip and hasMouseOverItem then
        self.tooltipUI = self.tooltipUI or UI.tooltip {
            owner = self,
            alwaysOnTop = true,
            text = tooltip,
        }

        if not self.tooltipUI:isVisible() or tooltip ~= self.tooltipUI.description then
            self.tooltipUI.description = tooltip
            self.tooltipUI.maxLineWidth = tooltip:contains('\n') and 1000 or 300
            self.tooltipUI:setVisible(true)
        end
    elseif self.tooltipUI then
        self.tooltipUI:setVisible(false)
        self.tooltipUI:removeFromUIManager()
        self.tooltipUI = nil
        return
    end
end

---Enables or disables all options in the checkbox group.
---@param enabled boolean
function CheckboxGroup:setEnabled(enabled)
    -- intentionally not setting `enable`, so the tooltip can still show

    local disabled = not enabled
    for i = 1, #self.options do
        local option = self.options[i]
        self.disabledOptions[option] = disabled
    end
end

---Sets a callback to be invoked when the checkbox value changes.
---@param target any?
---@param callback Callback.CheckboxGroup.Change?
---@param ...any
function CheckboxGroup:setOnChange(target, callback, ...)
    self.callbacks.change = core.callback(target, callback, ...)
end

---Sets whether the checkbox at a given index is selected.
---@param index integer
---@param selected boolean?
function CheckboxGroup:setSelected(index, selected)
    self.selected[index] = not not selected
end

---Sets whether the checkboxes are selected based on a set of data.
---@param set SetTable
function CheckboxGroup:setSelectedSet(set)
    for i = 1, #self.optionData do
        local data = self.optionData[i]
        self.selected[i] = not not (data and set[data])
    end
end


---Triggered when the value of a checkbox changes.
---@param index integer
---@param value boolean
---@protected
function CheckboxGroup:_onChange(index, value)
    core.callback.invoke(self.callbacks.change, index, value, self)
end


---Creates a new checkbox.
---@param args Args.CheckboxGroup
---@return CheckboxGroup
function CheckboxGroup:new(args)
    local x = args.x or 0
    local y = args.y or 0
    local h = args.h or 0
    local w = args.w or 0
    local font = args.font or UIFont.Small

    local this = UI.new(self, CheckboxGroup.__base.new, x, y, w, h, '')
    this:_setBaseArgs(args)

    this.keepOnScreen = false
    this.boxSize = args.boxSize or this.boxSize
    this.textGap = args.textGap or this.textGap
    this.leftMargin = args.marginLeft or this.leftMargin
    this.tickTexture = args.tickTexture or this.tickTexture
    this.choicesColor = core.copy(args.textColor or this.choicesColor)
    this.backgroundColor = core.copy(args.backgroundColor or this.backgroundColor)
    this.borderColor = core.copy(args.borderColor or this.borderColor)
    this.tooltip = args.tooltip
    this.itemTooltips = core.copy(args.itemTooltips)

    local disabledChoicesColor = core.color.defaultRGBA(args.textColorDisabled, 0.5, 0.5, 0.5, this.choicesColor.a)
    this.disabledChoicesColor = core.copy(disabledChoicesColor)

    if font ~= UIFont.Small then
        this:setFont(font)
    end

    local target = args.onChangeTarget or args.target or (args.targetSelf and this or nil)
    this.callbacks = {}
    this.changeOptionTarget = this
    this.changeOptionMethod = this._onChange
    this.changeOptionArgs = {}
    this:setOnChange(target, args.onChange, unpack(args.onChangeArgs or {}))

    local maxW = 0
    local items = args.items or {} --[[@as Checkbox.ItemOrString[] ]]
    for i = 1, #items do
        local item = items[i]
        if type(item) == 'string' then
            item = { text = item }
        end

        this:addOption(item.text, item.data, item.texture)
        this.selected[i] = not not item.checked

        if item.tooltip then
            this.itemTooltips[i] = item.tooltip
        end

        if not args.w then
            maxW = math.max(maxW, textManager:MeasureStringX(font, item.text) + 20)
        end
    end

    if not args.w then
        this:setWidth(maxW)
    end

    return this
end


return CheckboxGroup

--#region CheckboxGroup

---@class Args.CheckboxGroup.Base : Args.BaseUI
---@field tooltip? string The tooltip to show when hovering over a checkbox.
---@field itemTooltips? table<integer, string> Tooltips to show for individual checkboxes.
---@field font? UIFont The font to use for the text.
---@field boxSize? number The size of a checkbox box. Defaults to `16`.
---@field textGap? number The size of the gap between a checkbox and text. Defaults to `4`.
---@field marginLeft? number The margin to add to the left of the checkbox. Defaults to `0`.
---@field tickTexture? Texture The texture to use for checked boxes.
---@field textColor? ColorTableRGBA<number> The color to use for text.
---@field textColorDisabled? ColorTableRGBA<number> The color to use for text when a checkbox is disabled.
---@field borderColor? ColorTableRGBA<number> The color to use for the border.
---@field backgroundColor? ColorTableRGBA<number> The color to use for the background.
---@field onChangeArgs? table Arguments for `onChange`.
---@field onChangeTarget? any The first argument to pass to the `onChange` callback.
---@field target? any The default first argument to use for callbacks when a target is unspecified.
---@field targetSelf? boolean Flag for whether the default first argument for callbacks should be the created instance.

---@class Args.CheckboxGroup : Args.CheckboxGroup.Base
---@field items? Checkbox.ItemOrString[] Items to include in the checkbox group.
---@field onChange? Callback.CheckboxGroup.Change Invoked when a checkbox value changes.

---@class InitArgs.CheckboxGroup : Args.CheckboxGroup, InitArgs.Shared


---@class CheckboxGroup.Callbacks
---@field change? CallbackInfo Invoked when a checkbox value changes.

---@class CheckboxGroup.Item
---@field text string The text to display alongside the checkbox.
---@field tooltip? string The tooltip to show when hovering over a checkbox.
---@field data? any Data associated with the checkbox item.
---@field texture? Texture An image to include before the checkbox text.
---@field checked? boolean Whether the checkbox is checked.


---@alias Callback.CheckboxGroup.Change fun(target: any?, index: number, value: boolean, checkboxGroup: CheckboxGroup, ...: any)

---@alias Checkbox.ItemOrString CheckboxGroup.Item | string

--#endregion
