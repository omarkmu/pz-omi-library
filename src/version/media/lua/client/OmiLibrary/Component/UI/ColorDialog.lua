---UI element for a dialog with a color entry.
---@namespace omi

local UI = require 'OmiLibrary/Module/Core/UI'
local TextDialog = require 'OmiLibrary/Component/UI/TextDialog'
local ColorEntry = require 'OmiLibrary/Component/UI/ColorEntry'


---@class ColorDialog : TextDialog
---@field protected init ColorDialog.Init Information used only during initialization.
---@field protected entry? ColorEntry The color entry component.
---@field protected __base TextDialog The base class.
local ColorDialog = TextDialog:derive('OmiColorDialog')


---Gets the current color of the entry.
---@return ColorTable<integer>?
function ColorDialog:getColor()
    return self.entry and self.entry:getColor()
end

---Returns the color entry of the dialog.
---@return ColorEntry?
function ColorDialog:getEntry()
    return self.entry
end

---Sets the callback for clicking a dialog button.
---@param target any?
---@param callback Callback.ColorDialog.Click?
---@param ...any
function ColorDialog:setOnClick(target, callback, ...)
    TextDialog.setOnClick(self, target, callback, ...)
end

---Sets the callback for resize.
---@param target any?
---@param callback Callback.ColorDialog.Resize?
---@param ...any
function ColorDialog:setOnResize(target, callback, ...)
    TextDialog.setOnResize(self, target, callback, ...)
end


---Creates an entry for the dialog.
---@return ColorEntry
---@protected
function ColorDialog:_createEntry()
    return ColorEntry:new {
        playerNum = self.playerNum,
        text = self.init.defaultEntryText,
        font = self.init.font,
        maxLines = self.init.maxLines,
        anchorTop = false,
        anchorLeft = false,
        defaultColor = self.init.defaultColor,
        emptyColor = self.init.emptyColor,
        minValue = self.init.minValue,
        maxValue = self.init.maxValue,
        joypadNavigate = { up = self },
    }
end

---Gets arguments to pass to a click callback.
---@param button ISButton
---@return Args.ColorDialog.Click
---@protected
function ColorDialog:_getClickArgs(button)
    local args = TextDialog._getClickArgs(self, button) --[[@as Args.ColorDialog.Click]]
    args.color = self:getColor()
    return args
end


---Creates a new color dialog box.
---@param args Args.ColorDialog
---@return ColorDialog
function ColorDialog:new(args)
    local this = UI.new(self, TextDialog.new, args)

    this.init.defaultColor = args.defaultColor
    this.init.emptyColor = args.emptyColor
    this.init.minValue = args.minValue
    this.init.maxValue = args.maxValue

    return this
end


return ColorDialog

--#region Type Definitions

---@class Args.ColorDialog : Args.TextDialog
---@field defaultColor? ColorTable<integer> The default color to populate the dialog's color entry with.
---@field emptyColor? ColorTable<integer> The color to use when the entry is empty.
---@field maxValue? integer The maximum RGB value of each color component.
---@field minValue? integer The minimum RGB value of each color component.
---@field onClick? Callback.ColorDialog.Click Invoked when a dialog button is clicked.
---@field onResize? Callback.ColorDialog.Resize Invoked when the dialog is resized.

---@class Args.ColorDialog.Click : Args.TextDialog.Click
---@field color? ColorTable<integer> The current color.
---@field dialog ColorDialog The dialog.

---@class InitArgs.ColorDialog : Args.ColorDialog, InitArgs.Shared


---@class ColorDialog.Init : TextDialog.Init
---@field defaultColor? ColorTable<integer> The default color to populate the dialog's color entry with.
---@field emptyColor? ColorTable<integer> The color to use when the entry is empty.
---@field maxValue? integer The maximum RGB value of each color component.
---@field minValue? integer The minimum RGB value of each color component.


---@alias Callback.ColorDialog.Click fun(target: any?, args: Args.ColorDialog.Click, ...)

---@alias Callback.ColorDialog.Resize fun(target: any?, dialog: ColorDialog, ...)

--#endregion
