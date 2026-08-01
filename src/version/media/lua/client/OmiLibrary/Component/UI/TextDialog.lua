---UI element for a dialog with a text entry.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/Core/UI'
local Dialog = require 'OmiLibrary/Component/UI/Dialog'
local TextEntry = require 'OmiLibrary/Component/UI/TextEntry'

local max = math.max
local setJoypadFocus = setJoypadFocus
local textManager = getTextManager()
local OnScreenKeyboard = OnScreenKeyboard
local FONT_DEFAULT = UIFont.Medium


---@class TextDialog : Dialog
---@field protected init TextDialog.Init Information used only during initialization.
---@field protected entry? TextEntry The text entry component.
---@field protected lineCount integer The number of lines to display.
---@field protected errorMessage? string An error message to display below the entry.
---@field protected lastErrH number The last calculated error message height.
---@field protected errorPreventsClose boolean Whether an error message should prevent closing the dialog.
---@field protected __base Dialog The base class.
local TextDialog = Dialog:derive('OmiTextDialog')


---Returns the text entry of the dialog.
---@return TextEntry?
function TextDialog:getEntry()
    return self.entry
end

---Gets the number of lines to display.
---@return integer
function TextDialog:getLineCount()
    return self.lineCount
end

---Returns the current text of the entry.
---@return string
function TextDialog:getText()
    if not self.entry then
        return ''
    end

    return self.entry:getInternalText()
end

---Hides the error message.
function TextDialog:hideErrorMessage()
    self:showErrorMessage(nil)
end

---Hides the warning message.
function TextDialog:hideWarningMessage()
    self:hideErrorMessage()
end

---Returns whether the entry is multiline.
---@return boolean
function TextDialog:isMultipleLine()
    if not self.entry then
        return false
    end

    return self.entry:isMultipleLine()
end

---Called when a dialog button is clicked.
---@param button ISButton
function TextDialog:onClick(button)
    if self.callbacks.click then
        core.callback.invoke(self.callbacks.click, self:_getClickArgs(button))
    end

    if not self.errorMessage or not self.errorPreventsClose then
        self:destroy()
    end
end

---Called when the down direction button is pressed on the joypad.
---@param joypadData JoypadData
function TextDialog:onJoypadDirDown(joypadData)
    Dialog.onJoypadDirDown(self, joypadData)
    self:_showOnScreenKeyboard(joypadData)
end

---Called at the beginning of each render.
function TextDialog:prerender()
    Dialog.prerender(self)

    if self.entry and self.errorMessage then
        local y = self.entry.y + self.entry.height + self.lastErrH
        self:drawTextCentre(self.errorMessage, self.width * 0.5, y, 1, 0, 0, 1, self.textFont)
    end

    self:updateButtons()
end

---Sets the number of lines to display.
---@param count integer
function TextDialog:setLineCount(count)
    self.lineCount = count

    if self.entry then
        self.entry:setHeight(textManager:getFontHeight(self.entry:getFont()) * self.lineCount + 4)
    end

    self:_updateSize()
end

---Sets whether the entry is multiline.
---@param multiple boolean
function TextDialog:setMultipleLine(multiple)
    if self.entry then
        self.entry:setMultipleLine(multiple)
    else
        self.init.isMultipleLine = multiple
    end
end

---Sets the callback for clicking a dialog button.
---@param target any?
---@param callback Callback.TextDialog.Click?
---@param ...any
function TextDialog:setOnClick(target, callback, ...)
    Dialog.setOnClick(self, target, callback, ...)
end

---Sets whether the entry should accept only numbers.
---@param onlyNumbers boolean
function TextDialog:setOnlyNumbers(onlyNumbers)
    if self.entry then
        self.entry:setOnlyNumbers(onlyNumbers)
    else
        self.init.isOnlyNumbers = onlyNumbers
    end
end

---Sets the callback for resize.
---@param target any?
---@param callback Callback.TextDialog.Resize?
---@param ...any
function TextDialog:setOnResize(target, callback, ...)
    Dialog.setOnResize(self, target, callback, ...)
end

---Sets the function called to validate the entry.
---@param target any?
---@param callback Callback.TextEntry.Validate?
---@param ...any
function TextDialog:setValidateFunction(target, callback, ...)
    if self.entry then
        self.entry:setValidateFunction(target, callback, ...)
    else
        self.init.validateCallback = core.callback(target, callback, ...)
    end
end

---Sets the tooltip used when validation fails.
---@param text string?
function TextDialog:setValidateTooltipText(text)
    if self.entry then
        self.entry:setValidateTooltipText(text)
    else
        self.init.validateTooltipText = text
    end
end

---Sets the error message to display.
---@param message string?
---@param warning boolean? If this is `true`, errors won't prevent closing the dialog.
function TextDialog:showErrorMessage(message, warning)
    self.errorMessage = message
    self.errorPreventsClose = not warning

    if message then
        self.lastErrH = textManager:getFontHeight(self.textFont)
    end
end

---Sets the warning message to display.
---@param message string?
function TextDialog:showWarningMessage(message)
    self:showErrorMessage(message, true)
end

---Updates the state of the buttons based on validation state.
function TextDialog:updateButtons()
    Dialog.updateButtons(self)
    if not self.entry then
        return
    end

    local valid = self.entry:isValid()

    self:_updateButtonValidationState(self.okBtn, valid)
    self:_updateButtonValidationState(self.yesBtn, valid)
end


---Adds an entry to the dialog.
---@protected
function TextDialog:_addEntry()
    if self.entry then
        self.entry:destroy()
        self.entry = nil
    end

    self.entry = self:_createEntry() ---@type TextEntry
    self.entry:setX(0)
    self.entry:setWidth(self.width - 40)
    self.entry:setHeight(textManager:getFontHeight(self.init.font or FONT_DEFAULT) * self.lineCount + 4)
    self.entry:setAutoUpdateTooltip(false)
    self.entry:setTooltip(self.init.tooltipText)
    self.entry:setValidateTooltipText(self.init.validateTooltipText)
    self.entry:setMinLength(self.init.minLength)
    self.entry:setMaxLength(self.init.maxLength)

    if self.init.minLength and self.init.minLength > 0 then
        self.entry:setRequireValue(true)
    end

    if self.init.isMultipleLine then
        self.entry:setMultipleLine(true)
    end

    if self.init.isOnlyNumbers then
        self.entry:setOnlyNumbers(true)
    end

    -- validation color is shown on button instead
    local color = self.entry:getBorderColorValid()
    self.entry:setBorderColorInvalid(color.r, color.g, color.b, color.a)

    local cb = self.init.validateCallback
    if cb then
        self.entry:setValidateFunction(cb.target, cb.callback, unpack(cb.args, 1, cb.args.n))
    end

    self.entry:initialise()
    self:addChild(self.entry)
end

---Calculates the minimum size of the dialog.
---@return number
---@return number
---@protected
function TextDialog:_calcMinSize()
    local minW, minH = Dialog._calcMinSize(self)
    local entry = self.entry
    if not entry then
        return minW, minH
    end

    return max(minW, 60), minH + entry.height + 40
end

---Creates an entry for the dialog.
---@return TextEntry
---@protected
function TextDialog:_createEntry()
    return TextEntry:new {
        playerNum = self.playerNum,
        text = self.init.defaultEntryText,
        font = self.init.font,
        maxLines = self.init.maxLines,
        anchorTop = false,
        anchorLeft = false,
        joypadNavigate = { up = self },
    }
end

---Gets arguments to pass to a click callback.
---@param button ISButton
---@return Args.TextDialog.Click
---@protected
function TextDialog:_getClickArgs(button)
    local args = Dialog._getClickArgs(self, button) --[[@as Args.TextDialog.Click]]
    args.text = self:getText()
    return args
end

---Gets the Y position of the text.
---@return number
---@protected
function TextDialog:_getTextY()
    if not self.entry then
        return Dialog._getTextY(self)
    end

    return self.entry:getY() - self.lastTextH - 10
end

---Creates the children of the dialog.
---@protected
function TextDialog:_initialiseChildren()
    Dialog._initialiseChildren(self)
    self:_addEntry()
end

---Shows an on screen keyboard for the joypad.
---@param joypadData JoypadData
---@protected
function TextDialog:_showOnScreenKeyboard(joypadData)
    if not self.joyfocus then
        return
    end

    local entry = self.entry
    if not entry then
        return
    end

    if OnScreenKeyboard.IsVisible() then
        return
    end

    local playerNum = joypadData.player --[[@as integer]]
    local osk = OnScreenKeyboard.Show(playerNum, entry:getInternalEntry(), joypadData)
    if OnScreenKeyboard.instance then
        OnScreenKeyboard.instance.prevFocus = nil
    end

    setJoypadFocus(playerNum, osk)
end

---Updates the validation state for a button.
---@param button ISButton?
---@param valid boolean
---@protected
function TextDialog:_updateButtonValidationState(button, valid)
    if not button or not self.entry then
        return
    end

    button:setEnable(valid)
    button:setTooltip(not valid and self.entry:getValidateTooltipText() or nil)
end

---Updates dialog controls.
---@protected
function TextDialog:_updateControls()
    Dialog._updateControls(self)
    self:_updateEntry()
end

---Updates the size and position of the text entry.
---@protected
function TextDialog:_updateEntry()
    local entry = self.entry
    if not entry then
        return
    end

    local y = ((self.height - entry.height) * 0.5)
    if y + entry.height + 40 >= self.btnContainer.y then
        y = self.btnContainer.y - entry.height - 40
    end

    entry:setX(20)
    entry:setY(y)
    entry:setWidth(self.width - 40)
end


---Creates a new text dialog box.
---@param args Args.TextDialog
---@return TextDialog
function TextDialog:new(args)
    args = core.copy(args)
    args.includeTitlebar = args.includeTitlebar ~= false -- include by default for text dialogs

    local this = UI.new(self, Dialog.new, args)

    local target = args.validateTarget or args.target or (args.targetSelf and this or nil)
    this.init.validateCallback = core.callback(target, args.validate, unpack(args.validateArgs or {}))
    this.init.defaultEntryText = args.defaultText
    this.init.tooltipText = args.tooltip
    this.init.minLength = args.minLength
    this.init.maxLength = args.maxLength
    this.init.maxLines = args.maxLines or 1
    this.init.font = args.entryFont or FONT_DEFAULT

    this.lineCount = args.lineCount or this.init.maxLines
    this.errorPreventsClose = true
    this.lastErrH = 0

    return this
end


return TextDialog

--#region Type Definitions

---@class Args.TextDialog : Args.Dialog
---@field minLength? number The minimum length of the input.
---@field maxLength? number The maximum length of the input.
---@field defaultText? string The default text to use for the entry.
---@field tooltip? string The tooltip to use for the entry.
---@field entryFont? UIFont The font to use for the entry. Defaults to `UIFont.Medium`.
---@field lineCount? integer The number of lines to display.
---@field maxLines? integer The maximum number of lines for the entry.
---@field onClick? Callback.TextDialog.Click Invoked when a dialog button is clicked.
---@field onResize? Callback.TextDialog.Resize Invoked when the dialog is resized.
---@field validate? Callback.TextEntry.Validate Invoked to validate the entry's text content.
---@field validateArgs? table Arguments for `validate`.
---@field validateTarget? any The first argument to pass to the `validate` callback.

---@class Args.TextDialog.Click : Args.Dialog.Click
---@field text string The input text.
---@field dialog TextDialog The dialog.

---@class InitArgs.TextDialog : Args.TextDialog, InitArgs.Shared


---@class TextDialog.Init : Dialog.Init
---@field defaultEntryText? string The default text to use for the entry.
---@field tooltipText? string The tooltip to use for the entry.
---@field validateTooltipText? string The tooltip to use for the entry when validation fails.
---@field validateCallback? CallbackInfo Validation callback.
---@field minLength? number The minimum length of the input.
---@field maxLength? number The maximum length of the input.
---@field maxLines integer The maximum number of lines for the entry.
---@field font? UIFont The font to use for the entry.
---@field isMultipleLine boolean? Flag for whether the entry is multiline.
---@field isOnlyNumbers boolean? Flag for whether the entry only allows number.


---@alias Callback.TextDialog.Click fun(target: any?, args: Args.TextDialog.Click, ...: any)

---@alias Callback.TextDialog.Resize fun(target: any?, dialog: TextDialog, ...: any)

--#endregion
