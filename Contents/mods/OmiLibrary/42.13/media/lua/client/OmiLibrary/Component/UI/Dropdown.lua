---UI element for a dropdown box.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/UI/Core'

---@class Dropdown : ISComboBox, BaseUI
---@field font UIFont The font to use for the text.
---@field tooltip? Dropdown.TooltipMap The tooltip to show when hovering over the dropdown.
---@field noSelectionText? string The text to display when no option is selected.
---@field image? Texture The image to use for the dropdown icon.
---@field openUpwards? boolean If `true`, the dropdown will always open upwards.
---@field textColor? ColorTableRGBA<number> The color to use for text.
---@field borderColor? ColorTableRGBA<number> The color to use for the border.
---@field backgroundColor? ColorTableRGBA<number> The color to use for the background.
---@field backgroundColorMouseOver? ColorTableRGBA<number> The color to use for the background while the mouse is over the dropdown.
---@field disabled boolean Whether interactions with the dropdown are ignored.
---@field protected callbacks Dropdown.Callbacks Container for callbacks.
---@field protected __base ISComboBox The base class.
local Dropdown = UI.class('OmiDropdown', ISComboBox)


---Returns whether the dropdown is currently enabled.
---@return boolean
function Dropdown:isEnabled()
    return not self.disabled
end

---Sets whether the dropdown is enabled.
---@param enabled boolean
function Dropdown:setEnabled(enabled)
    self.disabled = not enabled
end

---Sets a callback to be invoked when the dropdown value changes.
---@param target any?
---@param callback Callback.Dropdown.Change?
---@param ...any
function Dropdown:setOnChange(target, callback, ...)
    self.callbacks.change = core.callback(target, callback, ...)
end

---Triggered when the dropdown value changes.
---@protected
function Dropdown:_onChange()
    local index = self.selected
    local data = self:getOptionData(index)
    core.callback.invoke(self.callbacks.change, index, data, self)
end


---Creates a new dropdown.
---@param args Args.Dropdown
---@return Dropdown
function Dropdown:new(args)
    local x = args.x or 0
    local y = args.y or 0
    local h = args.h or 0
    local w = args.w or 0

    local this = UI.new(self, Dropdown.__base.new, x, y, w, h)
    this:_setBaseArgs(args)

    this.font = args.font or this.font
    this.noSelectionText = args.placeholderText
    this.image = args.image or this.image
    this.openUpwards = args.openUpwards
    this.textColor = core.copy(args.textColor or this.textColor)
    this.borderColor = core.copy(args.borderColor or this.borderColor)
    this.backgroundColor = core.copy(args.backgroundColor or this.backgroundColor)
    this.backgroundColorMouseOver = core.copy(args.backgroundColorMouseOver or this.backgroundColorMouseOver)
    this.disabled = not (args.enable ~= false)
    this.tooltip = args.tooltip and { defaultTooltip = args.tooltip } or this.tooltip

    this.callbacks = {}

    local target = args.onChangeTarget or args.target or (args.targetSelf and this or nil)
    this.target = this
    this.onChange = this._onChange
    this:setOnChange(target, args.onChange, unpack(args.onChangeArgs or {}))

    return this
end


return Dropdown

--#region Type Definitions

---@class Args.Dropdown : Args.BaseUI
---@field font? UIFont The font to use for the text.
---@field tooltip? string The tooltip to show when hovering over the dropdown.
---@field placeholderText? string The text to display when no option is selected.
---@field image? Texture The image to use for the dropdown icon.
---@field enable? boolean Whether the dropdown should be enabled. Defaults to `true`.
---@field openUpwards? boolean If `true`, the dropdown will always open upwards.
---@field textColor? ColorTableRGBA<number> The color to use for text.
---@field borderColor? ColorTableRGBA<number> The color to use for the border.
---@field backgroundColor? ColorTableRGBA<number> The color to use for the background.
---@field backgroundColorMouseOver? ColorTableRGBA<number> The color to use for the background while the mouse is over the dropdown.
---@field onChange? Callback.Dropdown.Change Invoked when the dropdown value changes.
---@field onChangeArgs? table Arguments for `onChange`.
---@field onChangeTarget? any The first argument to pass to the `onChange` callback.
---@field target? any The default first argument to use for callbacks when a target is unspecified.
---@field targetSelf? boolean Flag for whether the default first argument for callbacks should be the created instance.

---@class InitArgs.Dropdown : Args.Dropdown, InitArgs.Shared
---@field options? Dropdown.OptionOrString[] Options to include in the dropdown.
---@field maxWidth? number The maximum width to set the dropdown width to. Only used if an explicit width is not given.
---@field selected? integer The index of the dropdown item that should initially be selected.


---@class Dropdown.Callbacks
---@field change? CallbackInfo Invoked when the dropdown value changes.

---@class Dropdown.TooltipMap
---@field defaultTooltip? string The tooltip to use for options if one is not specified.
---@field [string]? string The tooltip associated with an option's text.

---@class Dropdown.Option
---@field text string The text to display in the dropdown.
---@field data? any Data associated with the dropdown option.
---@field tooltip? string The tooltip to display when the option is selected.


---@alias Callback.Dropdown.Change fun(target: any?, selected: integer, data: any?, dropdown: Dropdown, ...: any)

---@alias Dropdown.OptionOrString Dropdown.Option | string

--#endregion
