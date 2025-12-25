---Entry for text input with optional validation.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/UI/Core'
local Mixin = require 'OmiLibrary/Module/UI/Mixin'

local ColorInfo = ColorInfo
local KEY_UP = Keyboard.KEY_UP
local KEY_DOWN = Keyboard.KEY_DOWN
local KEY_RETURN = Keyboard.KEY_RETURN
local KEY_ESCAPE = Keyboard.KEY_ESCAPE
local KEY_TAB = Keyboard.KEY_TAB
local getText = core.l10n.getText


---@class TextEntry : Mixin.Scrollable, BaseUI
---@field suggestBox? SuggestBox The auto-suggest box associated with the entry.
---@field font UIFont The font to use for the text.
---@field protected init TextEntry.Init Information used only during initialization.
---@field protected borderColor ColorTableRGBA<number> Reference to the border color table of the underlying entry.
---@field protected backgroundColor ColorTableRGBA<number> Reference to the background color table of the underlying entry.
---@field protected vscroll? ISScrollBar The vertical scroll bar.
---@field protected hscroll? ISScrollBar The horizontal scroll bar.
---@field protected minLength? integer The minimum string length of the entry.
---@field protected maxLength? integer The maximum string length of the entry.
---@field protected tooltipText? string The tooltip text to use when the input is valid.
---@field protected validateTooltipText? string The tooltip text to use when the input is invalid.
---@field protected requireInteger boolean If `true`, the text entry will not be valid if its content is not an integer.
---@field protected requireNumber boolean If `true`, the text entry will not be valid if its content is not a number.
---@field protected requireValue boolean If `true`, the text entry will not be valid if empty.
---@field protected minValue? number The minimum numeric value of the entry.
---@field protected maxValue? number The maximum numeric value of the entry.
---@field protected callbacks TextEntry.Callbacks The registered callbacks.
---@field protected hasBeenFocused boolean Set to `true` the first time the entry is focused.
---@field protected wasFocused boolean Used to track whether the entry was focused during the last update.
---@field protected entry ISTextEntryBox The internal entry element.
---@field protected fade UITransition The transition used to fade the underlying entry.
---@field protected widthRatio number The ratio of the container width to the entry width.
---@field protected heightRatio number The ratio of the container height to the entry height.
---@field protected padTop number The amount of padding to include above the text entry.
---@field protected padBottom number The amount of padding to include below the text entry.
---@field protected padLeft number The amount of padding to include to the left of the text entry.
---@field protected padRight number The amount of padding to include to the right of the text entry.
---@field protected valid boolean Whether the entry is currently valid.
---@field protected autoUpdateTooltip boolean Whether the tooltip should update based on the validation state.
---@field protected borderColorValid ColorTableRGBA<number> The border color to use when the entry is valid.
---@field protected borderColorInvalid ColorTableRGBA<number> The border color to use when the entry is invalid.
---@field protected borderColorDisabled ColorTableRGBA<number> The border color to use when the entry is disabled.
---@field protected textColor ColorTableRGBA<number> The color to use for the entry.
---@field protected textColorDisabled ColorTableRGBA<number> The color to use when the entry is disabled.
local TextEntry = UI.class('OmiTextEntry', nil, Mixin.Scrollable)


---Adds scrollbars to the underlying entry.
---@param addHorizontal boolean?
function TextEntry:addScrollBars(addHorizontal)
    self.entry:addScrollBars(addHorizontal)

    self.vscroll = self.entry.vscroll
    self.hscroll = self.entry.hscroll
end

---Clears the text entry input.
---@param notify boolean? If `true`, this will trigger onTextChange.
function TextEntry:clear(notify)
    if notify then
        -- clear notifies already
        self.entry:clear()
        return
    end

    self:setText('', notify)
end

---Default validation handler.
---@param text string
---@return boolean
function TextEntry:defaultValidate(text)
    if #core.trim(text) == 0 then
        if self.requireValue then
            self:setValidateTooltipText(getText('@error.require-value'))
            return false
        end

        return true
    end

    if self.minLength and #text < self.minLength then
        self:setValidateTooltipText(getText('@error.length-min', { min = self.minLength }))
        return false
    elseif self.maxLength and #text > self.maxLength then
        self:setValidateTooltipText(getText('@error.length-max', { max = self.maxLength }))
        return false
    end

    local num = tonumber(text)
    if num then
        if self.minValue and num < self.minValue then
            self:setValidateTooltipText(getText('@error.value-min', { min = self.minValue }))
            return false
        elseif self.maxValue and num > self.maxValue then
            self:setValidateTooltipText(getText('@error.value-max', { max = self.maxValue }))
            return false
        elseif self.requireInteger and math.floor(num) ~= num then
            self:setValidateTooltipText(getText('@error.require-integer'))
            return false
        end
    elseif self.requireNumber or self.requireInteger then
        local id = self.requireInteger and '@error.require-integer' or '@error.require-number'
        self:setValidateTooltipText(getText(id))
        return false
    end

    return true
end

---Focuses the entry.
---@param notify boolean? If `true`, this will trigger the focus gain callback.
function TextEntry:focus(notify)
    self.entry:focus()
    self:_onFocus(notify)
end

---Returns whether the entry will automatically update its tooltip based on validation state.
---@return boolean
function TextEntry:getAutoUpdateTooltip()
    return self.autoUpdateTooltip
end

---Returns the border color to use when the entry is invalid.
---@return ColorTableRGBA
function TextEntry:getBorderColorInvalid()
    return core.copy(self.borderColorInvalid)
end

---Returns the border color to use when the entry is valid.
---@return ColorTableRGBA
function TextEntry:getBorderColorValid()
    return core.copy(self.borderColorValid)
end

---Gets the current cursor position of the text entry.
---This returns the position on the current line.
---@return integer
function TextEntry:getCursorPos()
    return self.entry:getCursorPos()
end

---Gets the font of the entry.
---@return UIFont
function TextEntry:getFont()
    if not self.entry then
        return self.font
    end

    return self.entry.font
end

---Returns whether text entry input is forced to uppercase.
---@return boolean
function TextEntry:getForceUpperCase()
    if not self.entry then
        return self.init.forceUppercase
    end

    return self.entry.javaObject:getForceUpperCase()
end

---Gets the opacity of the text entry frame.
---@return number
function TextEntry:getFrameAlpha()
    return self.entry:getFrameAlpha()
end

---Gets whether the text entry has a frame.
---@return boolean
function TextEntry:getHasFrame()
    if not self.entry then
        return self.init.hasFrame == true
    end

    return self.entry:getHasFrame()
end

---Gets the internal entry object.
---@return ISTextEntryBox
function TextEntry:getInternalEntry()
    return self.entry
end

---Gets the current internal text of the input.
---@return string
function TextEntry:getInternalText()
    return self.entry:getInternalText()
end

---Gets the current text of the input.
---@return string
function TextEntry:getText()
    return self.entry:getText()
end

---Gets the maximum lines of the text entry.
---@return integer
function TextEntry:getMaxLines()
    return self.entry:getMaxLines()
end

---Returns the maximum text length, used for validation.
---@return integer?
function TextEntry:getMaxLength()
    return self.maxLength
end

---Gets the enforced maximum length of the entry.
---@return integer
function TextEntry:getMaxTextLength()
    return self.entry.javaObject:getMaxTextLength()
end

---Returns the maximum numeric value of the input.
---@return number?
function TextEntry:getMaxValue()
    return self.maxValue
end

---Returns the minimum text length, used for validation.
---@return integer?
function TextEntry:getMinLength()
    return self.minLength
end

---Returns the minimum numeric value of the input.
---@return number?
function TextEntry:getMinValue()
    return self.minValue
end

---Gets the text to display when the input is empty.
---@return string?
function TextEntry:getPlaceholderText()
    return self.entry:getPlaceholderText()
end

---Returns whether the entry requires numeric input.
---@return boolean
function TextEntry:getRequireNumber()
    return self.requireNumber
end

---Returns the scroll area height of the underlying entry.
---@return number
function TextEntry:getScrollAreaHeight()
    if not self.entry then
        return 0
    end

    return self.entry:getScrollAreaHeight()
end

---Returns the scroll area width of the underlying entry.
---@return number
function TextEntry:getScrollAreaWidth()
    if not self.entry then
        return 0
    end

    return self.entry:getScrollAreaWidth()
end

---Returns the scroll height of the underlying entry.
---@return number
function TextEntry:getScrollHeight()
    if not self.entry then
        return 0
    end

    return self.entry:getScrollHeight()
end

---Returns the scroll width of the underlying entry.
---@return number
function TextEntry:getScrollWidth()
    if not self.entry then
        return 0
    end

    return self.entry:getScrollWidth()
end

---Gets the auto-suggest box associated with the entry.
---@return SuggestBox?
function TextEntry:getSuggestBox()
    return self.suggestBox
end

---Returns the tooltip text used when the input is valid.
---@return string?
function TextEntry:getTooltipText()
    return self.tooltipText
end

---Returns the tooltip text used when the input is invalid.
---@return string?
function TextEntry:getValidateTooltipText()
    return self.validateTooltipText
end

---Returns the X scroll amount of the underlying entry.
---@return number
function TextEntry:getXScroll()
    if not self.entry then
        return 0
    end

    return self.entry:getXScroll()
end

---Returns the Y scroll amount of the underlying entry.
---@return number
function TextEntry:getYScroll()
    if not self.entry then
        return 0
    end

    return self.entry:getYScroll()
end

---Returns `true` if the entry has had focus at least once.
---@return boolean
function TextEntry:hasHadFocus()
    return self.hasBeenFocused
end

---Sets that the entry should ignore the first input.
function TextEntry:ignoreFirstInput()
    self.entry:ignoreFirstInput()
end

---Performs initialization.
function TextEntry:initialise()
    TextEntry.__base.initialise(self)

    self.entry = self:_createInternalEntry()
    self.fade = self.entry.fade

    self:addChild(self.entry)
end

---Returns whether the entry is currently editable.
---@return boolean
function TextEntry:isEditable()
    if not self.entry then
        return self.init.editable
    end

    return self.entry:isEditable()
end

---Returns whether the entry is enabled.
---This is treated as equivalent to "editable".
---@return boolean
function TextEntry:isEnabled()
    return self:isEditable()
end

---Returns whether the entry currently has focus.
---@return boolean
function TextEntry:isFocused()
    if not self.entry then
        return false
    end

    return self.entry:isFocused()
end

---Returns whether entry input is masked.
---@return boolean
function TextEntry:isMasked()
    if not self.entry then
        return self.init.masked
    end

    return self.entry.javaObject:isMasked()
end

---Returns whether the entry is multiline.
---@return boolean
function TextEntry:isMultipleLine()
    return self.entry:isMultipleLine()
end

---Returns whether the text in the entry can be selected.
---@return boolean
function TextEntry:isSelectable()
    if not self.entry then
        return self.init.selectable
    end

    return self.entry:isSelectable()
end

---Returns whether the vertical scrollbar is visible.
---@return boolean
function TextEntry:isVScrollBarVisible()
    if not self.entry then
        return false
    end

    return self.entry:isVScrollBarVisible()
end

---Returns whether the value of the entry is currently valid.
---@return boolean
function TextEntry:isValid()
    return self.valid
end

---Called when `Enter` is pressed while focused.
function TextEntry:onCommandEntered()
    local suggestBox = self.suggestBox
    if suggestBox and suggestBox:onPressEnter() then
        return
    end

    core.callback.invoke(self.callbacks.key, KEY_RETURN)
    core.callback.invoke(self.callbacks.command)
end

---Called when `Tab` or `Escape` is pressed while focused.
---@param key integer
function TextEntry:onOtherKey(key)
    local suggestBox = self.suggestBox
    if suggestBox then
        if key == KEY_ESCAPE and suggestBox:onPressEscape() then
            return
        end

        if key == KEY_TAB and suggestBox:onPressTab() then
            return
        end
    end

    core.callback.invoke(self.callbacks.key, key)
    core.callback.invoke(self.callbacks.otherKey, key)
end

---Called when `Down` is pressed while focused.
function TextEntry:onPressDown()
    local suggestBox = self.suggestBox
    if suggestBox and suggestBox:onPressDown() then
        return
    end

    core.callback.invoke(self.callbacks.key, KEY_DOWN)
    core.callback.invoke(self.callbacks.down, KEY_DOWN)
end

---Called when `Up` is pressed while focused.
function TextEntry:onPressUp()
    local suggestBox = self.suggestBox
    if suggestBox and suggestBox:onPressUp() then
        return
    end

    core.callback.invoke(self.callbacks.key, KEY_UP)
    core.callback.invoke(self.callbacks.up, KEY_UP)
end

---Called when the entry container is resized.
function TextEntry:onResize()
    TextEntry.__base.onResize(self)

    self:_resizeEntry()
    core.callback.invoke(self.callbacks.resize)

    if self.suggestBox then
        self.suggestBox:onResizeEntry()
    end
end

---Called when text is changed in the entry.
function TextEntry:onTextChange()
    core.callback.invoke(self.callbacks.change)

    if self.suggestBox and self:isFocused() then
        self.suggestBox:onTextChange(self:getInternalText())
    end
end

---Runs before each render.
function TextEntry:prerender()
    self:_updateSmoothScrolling()
    self:setValid(self:validate())
end

---Selects all text in the entry.
function TextEntry:selectAll()
    self.entry:selectAll()
end

---Sets whether the entry should automatically update its tooltip based on validation state.
---@param auto boolean
function TextEntry:setAutoUpdateTooltip(auto)
    self.autoUpdateTooltip = auto
end

---Sets the border color to use when the entry is invalid.
---@param r number
---@param g number
---@param b number
---@param a number?
function TextEntry:setBorderColorInvalid(r, g, b, a)
    self.borderColorInvalid = {
        r = r,
        g = g,
        b = b,
        a = a or self.borderColorInvalid.a,
    }
end

---Sets the border color to use when the entry is valid.
---@param r number
---@param g number
---@param b number
---@param a number?
function TextEntry:setBorderColorValid(r, g, b, a)
    self.borderColorValid = {
        r = r,
        g = g,
        b = b,
        a = a or self.borderColorValid.a,
    }
end

---Sets whether the text entry has a clear button.
---@param hasButton boolean
function TextEntry:setClearButton(hasButton)
    self.entry:setClearButton(hasButton)
end

---Sets the current cursor position of the text entry.
---This sets the position on the current line.
---@param pos integer
function TextEntry:setCursorPos(pos)
    self.entry:setCursorPos(pos)
end

---Sets whether the entry can be edited.
---@param editable boolean
function TextEntry:setEditable(editable)
    editable = not not editable
    if not self.entry or not self.entry.javaObject then
        self.init.editable = editable
        return
    end

    self.entry.javaObject:setEditable(editable)
    self:_updateColors()
end

---Sets whether the entry is enabled.
---This is treated as equivalent to "editable".
---@param enabled boolean
function TextEntry:setEnabled(enabled)
    self:setEditable(enabled)
end

---Sets whether text entry input should be forced to be uppercase.
---@param forceUpperCase boolean
function TextEntry:setForceUpperCase(forceUpperCase)
    if not self.entry then
        self.init.forceUppercase = forceUpperCase
        return
    end

    self.entry:setForceUpperCase(forceUpperCase)
end

---Sets the opacity of the text entry frame.
---@param alpha number
function TextEntry:setFrameAlpha(alpha)
    self.entry:setFrameAlpha(alpha)
end

---Sets whether the text entry has a frame.
---@param hasFrame boolean
function TextEntry:setHasFrame(hasFrame)
    if not self.entry then
        self.init.hasFrame = hasFrame
    end

    self.entry:setHasFrame(hasFrame)
end

---Sets joypad focus on the entry.
---@param focused boolean
---@param joypadData JoypadData?
function TextEntry:setJoypadFocused(focused, joypadData)
    self.entry:setJoypadFocused(focused, joypadData)
end

---Sets whether text entry input should be masked.
---@param masked boolean
function TextEntry:setMasked(masked)
    if not self.entry then
        self.init.masked = masked
        return
    end

    self.entry:setMasked(masked)
end

---Sets the maximum lines of the entry.
---@param maxLines integer
function TextEntry:setMaxLines(maxLines)
    if not self.entry then
        self.init.maxLines = maxLines
    end

    self.entry:setMaxLines(maxLines)
end

---Sets the maximum length of the entry for validation.
---@param length number?
function TextEntry:setMaxLength(length)
    self.maxLength = length
end

---Sets the maximum length of the entry.
---This enforces the maximum, unlike `setMaxLength`.
---@param length number
function TextEntry:setMaxTextLength(length)
    self.entry:setMaxTextLength(length)
end

---Sets the maximum value of the input.
---@param val number?
function TextEntry:setMaxValue(val)
    self.maxValue = val
end

---Sets the minimum length of the entry for validation.
---@param length number?
function TextEntry:setMinLength(length)
    self.minLength = length
end

---Sets the minimum value of the input.
---@param val number
function TextEntry:setMinValue(val)
    self.minValue = val
end

---Sets whether the entry is multiline.
---@param multiple boolean
function TextEntry:setMultipleLine(multiple)
    self.entry:setMultipleLine(multiple)
end

---Sets whether the input requires a valid integer.
---@param requireInteger boolean
function TextEntry:setRequireInteger(requireInteger)
    self.requireInteger = requireInteger
end

---Sets whether the input requires a valid number.
---@param requireNumber boolean
function TextEntry:setRequireNumber(requireNumber)
    self.requireNumber = requireNumber
end

---Sets whether the input requires a value.
---@param requireValue boolean
function TextEntry:setRequireValue(requireValue)
    self.requireValue = requireValue
end

---Sets the auto-suggest box associated with the entry.
---@param suggestBox SuggestBox? The auto-suggest box.
---@param notify boolean? If `true`, this will immediately fire a text change for the suggest box.
function TextEntry:setSuggestBox(suggestBox, notify)
    if self.suggestBox == suggestBox then
        return
    end

    local isEntryChange = false
    if self.suggestBox then
        local entry = self.suggestBox:getEntry()
        if entry and entry ~= self then
            notify = true
            isEntryChange = true
        end

        self.suggestBox.entry = nil ---@diagnostic disable-line: access-invisible
        self.suggestBox:setVisible(false)
    end

    self.suggestBox = suggestBox
    if not suggestBox then
        return
    end

    suggestBox.entry = self ---@diagnostic disable-line: access-invisible
    if notify and self.entry then
        suggestBox:onTextChange(self:getInternalText(), isEntryChange)
    end
end

---Sets a callback function to be called when focus is lost on the text entry.
---@param target any?
---@param callback UICallback?
---@param ...any
function TextEntry:setOnBlur(target, callback, ...)
    self.callbacks.blur = core.callback(target, callback, ...)
end

---Sets a callback function to be called on text change.
---@param target any?
---@param callback UICallback?
---@param ...any
function TextEntry:setOnChange(target, callback, ...)
    self.callbacks.change = core.callback(target, callback, ...)
end

---Sets a callback function to be called when Enter is pressed.
---@param target any?
---@param callback UICallback?
---@param ...any
function TextEntry:setOnCommandEntered(target, callback, ...)
    self.callbacks.command = core.callback(target, callback, ...)
end

---Sets a callback function to be called when focus is gained on the text entry.
---@param target any?
---@param callback UICallback?
---@param ...any
function TextEntry:setOnFocus(target, callback, ...)
    self.callbacks.focus = core.callback(target, callback, ...)
end

---Sets a callback function to be called when Enter, Tab, Escape, Up, or Down is pressed.
---@param target any?
---@param callback Callback.TextEntry.Key?
---@param ...any
function TextEntry:setOnKey(target, callback, ...)
    self.callbacks.key = core.callback(target, callback, ...)
end

---Sets a callback function to be called when Tab or Escape is pressed.
---@param target any?
---@param callback Callback.TextEntry.Key?
---@param ...any
function TextEntry:setOnOtherKey(target, callback, ...)
    self.callbacks.otherKey = core.callback(target, callback, ...)
end

---Sets a callback function to be called when the Down key is pressed.
---@param target any?
---@param callback UICallback?
---@param ...any
function TextEntry:setOnPressDown(target, callback, ...)
    self.callbacks.down = core.callback(target, callback, ...)
end

---Sets a callback function to be called when the Up key is pressed.
---@param target any?
---@param callback UICallback?
---@param ...any
function TextEntry:setOnPressUp(target, callback, ...)
    self.callbacks.up = core.callback(target, callback, ...)
end

---Sets whether the input should accept only numbers.
---@param onlyNumbers boolean
function TextEntry:setOnlyNumbers(onlyNumbers)
    if onlyNumbers then
        self:setRequireNumber(true)
    end

    self.entry:setOnlyNumbers(onlyNumbers)
end

---Sets whether the input should accept only text.
---@param onlyText boolean
function TextEntry:setOnlyText(onlyText)
    self.entry:setOnlyText(onlyText)
end

---Sets a callback function to be called when the entry is resized.
---@param target any?
---@param callback UICallback?
---@param ...any
function TextEntry:setOnResize(target, callback, ...)
    self.callbacks.resize = core.callback(target, callback, ...)
end

---Sets the color to use for placeholder text.
---@param r number The red color component in [0.0, 1.0].
---@param g number The green color component in [0.0, 1.0].
---@param b number The blue color component in [0.0, 1.0].
---@param a number The alpga color component in [0.0, 1.0].
function TextEntry:setPlaceholderRGBA(r, g, b, a)
    if not self.entry then
        self.init.placeholderColor = { r = r, g = g, b = b, a = a }
        return
    end

    self.entry:setPlaceholderTextRGBA(r, g, b, a)
end

---Sets text to display when the input is empty.
---@param placeholder string?
function TextEntry:setPlaceholderText(placeholder)
    if not self.entry then
        self.init.placeholderText = placeholder
        return
    end

    self.entry:setPlaceholderText(placeholder --[[@as string]])
end

---Sets the scroll height of the underlying entry.
---@param h number
function TextEntry:setScrollHeight(h)
    if not self.entry then
        self.init.scrollHeight = h
        return
    end

    self.entry:setScrollHeight(h)
end

---Sets the scroll width of the underlying entry.
---@param w number
function TextEntry:setScrollWidth(w)
    if not self.entry then
        self.init.scrollWidth = w
        return
    end

    self.entry:setScrollWidth(w)
end

---Sets whether text in the entry can be selected.
---@param selectable boolean
function TextEntry:setSelectable(selectable)
    self.entry:setSelectable(selectable)
end

---Sets the current text of the entry.
---@param text string? The text to set on the entry.
---@param notify boolean? If `true`, this will trigger onTextChange.
function TextEntry:setText(text, notify)
    self.entry.javaObject:SetText(text or '')
    self.__lastText = text

    if notify then
        self:onTextChange()
    elseif self.suggestBox and self:isFocused() then
        self.suggestBox:onTextChange(self:getInternalText())
    end
end

---Sets the text color of the entry.
---@param r number The red color component in [0.0, 1.0].
---@param g number The green color component in [0.0, 1.0].
---@param b number The blue color component in [0.0, 1.0].
---@param a number The alpga color component in [0.0, 1.0].
function TextEntry:setTextRGBA(r, g, b, a)
    self.entry.javaObject:setTextRGBA(r, g, b, a)
end

---Sets the tooltip used when text is valid.
---@param text string?
function TextEntry:setTooltip(text)
    self.tooltipText = text and text:gsub('\\n', '\n') or nil

    if self.entry and self:isValid() then
        self.entry.tooltip = self.tooltipText
    end
end

---Sets whether the current text is valid.
---@param valid boolean
function TextEntry:setValid(valid)
    self.valid = valid
    if not self.entry then
        return
    end

    self:_updateColors()

    if not self.autoUpdateTooltip then
        return
    end

    if valid then
        self.entry.tooltip = self.tooltipText
    else
        self.entry.tooltip = self.validateTooltipText
    end
end

---Sets the function called to validate the text entry.
---@param target any?
---@param callback Callback.TextEntry.Validate?
---@param ...any
function TextEntry:setValidateFunction(target, callback, ...)
    self.callbacks.validate = core.callback(target, callback, ...)
end

---Sets the tooltip used when validation fails.
---@param text string?
function TextEntry:setValidateTooltipText(text)
    self.validateTooltipText = text
end

---Sets the X scroll amount of the underlying entry.
---@param x number
function TextEntry:setXScroll(x)
    if not self.entry then
        self.init.xScroll = x
        return
    end

    self.entry:setXScroll(x)
end

---Sets the Y scroll amount of the underlying entry.
---@param y number
function TextEntry:setYScroll(y)
    if not self.entry then
        self.init.yScroll = y
        return
    end

    self.entry:setYScroll(y)
end

---Releases focus from the entry.
---@param notify boolean? If `true`, this will trigger the focus loss callback.
function TextEntry:unfocus(notify)
    self.entry:unfocus()
    self:_onBlur(notify)
end

---Called every 100ms while the entry is visible.
function TextEntry:update()
    self:_checkFocus()
    self:_resizeEntry()

    -- TODO(vanilla bug): remove when https://theindiestone.com/forums/index.php?/topic/87909-4 is fixed
    do
        if not self.entry then
            return
        end

        local text = self.entry:getInternalText()
        if not self.__lastText then
            self.__lastText = text
            return
        end

        if text ~= self.__lastText then
            self.__lastText = text
            self:onTextChange()
        end
    end
end

---Validates the input text.
---@param text string? Text to validate. Defaults to the current input.
---@return boolean valid
function TextEntry:validate(text)
    if not text then
        text = self:getInternalText()
    end

    if self.callbacks.validate and not core.callback.invoke(self.callbacks.validate, text) then
        return false
    end

    return self:defaultValidate(text)
end


---Checks for focus gain or loss.
---@protected
function TextEntry:_checkFocus()
    if not self.entry then
        return
    end

    local isFocused = self.entry:isFocused()
    if isFocused == self.wasFocused then
        return
    end

    self.wasFocused = isFocused
    if isFocused then
        self:_onFocus(true)
    else
        self:_onBlur(true)
    end
end

---Creates the internal text entry box.
---@return ISTextEntryBox
---@protected
function TextEntry:_createInternalEntry()
    local entry = ISTextEntryBox:new(self.init.text, 0, 0, self.width, self.height)

    entry.anchorRight = true
    entry.anchorBottom = true
    entry.overrideBPrompt = true
    entry.font = self.font
    entry.tooltip = self.tooltipText
    entry.onPressUp = self._onEntryPressUp
    entry.onPressDown = self._onEntryPressDown
    entry.onCommandEntered = self._onEntryCommandEntered
    entry.onOtherKey = self._onEntryOtherKey
    entry.onTextChange = self._onEntryTextChange
    entry.onJoypadDown = self._onEntryJoypadDown --[[@as function]]
    entry.onMouseWheel = self._onEntryMouseWheel --[[@as function]]
    entry.onResize = core.noop
    entry.onLostFocus = self._checkFocus
    entry.getAPrompt = self._getEntryAPrompt --[[@as function]]
    entry.getBPrompt = self._getEntryBPrompt --[[@as function]]
    entry.getXPrompt = self._getEntryXPrompt --[[@as function]]
    entry.getYPrompt = self._getEntryYPrompt --[[@as function]]
    entry.getRBPrompt = self._getEntryRBPrompt --[[@as function]]
    entry.getLBPrompt = self._getEntryLBPrompt --[[@as function]]
    entry.isValidPrompt = self._isEntryValidForPrompt --[[@as function]]

    -- use the same references so this can more easily act as a wrapper
    entry.borderColor = self.borderColor
    entry.backgroundColor = self.backgroundColor

    entry:initialise()
    entry:instantiate()

    local textColor = self.textColor
    entry.javaObject:setTextColor(ColorInfo.new(textColor.r, textColor.g, textColor.b, textColor.a))

    local maxLines = self.init.maxLines
    entry:setMaxLines(maxLines)
    entry:setMultipleLine(maxLines > 1)

    if self.init.placeholderText then
        entry:setPlaceholderText(self.init.placeholderText)
    end

    if not self.init.editable then
        entry:setEditable(false)
    end

    if not self.init.selectable then
        entry:setSelectable(false)
    end

    if self.init.onlyNumbers then
        entry:setOnlyNumbers(true)
    end

    if self.init.masked then
        entry:setMasked(true)
    end

    if self.init.forceUppercase then
        entry:setForceUpperCase(true)
    end

    if self.init.hasFrame then
        entry:setHasFrame(true)
    end

    if self.init.scrollHeight then
        entry:setScrollHeight(self.init.scrollHeight)
    end

    if self.init.scrollWidth then
        entry:setScrollWidth(self.init.scrollWidth)
    end

    if self.init.yScroll then
        entry:setYScroll(self.init.yScroll)
    end

    if self.init.xScroll then
        entry:setXScroll(self.init.xScroll)
    end

    return entry
end

---`getAPrompt` handler for the text entry.
---@param entry ISTextEntryBox
---@return string?
---@protected
---@diagnostic disable-next-line: unused
function TextEntry._getEntryAPrompt(entry)
    return getText('OmiLibrary.prompt-edit')
end

---`getBPrompt` handler for the text entry.
---@param entry ISTextEntryBox
---@return string?
---@protected
---@diagnostic disable-next-line: unused
function TextEntry._getEntryBPrompt(entry) end

---`getXPrompt` handler for the text entry.
---@param entry ISTextEntryBox
---@return string?
---@protected
---@diagnostic disable-next-line: unused
function TextEntry._getEntryXPrompt(entry) end

---`getYPrompt` handler for the text entry.
---@param entry ISTextEntryBox
---@return string?
---@protected
---@diagnostic disable-next-line: unused
function TextEntry._getEntryYPrompt(entry) end

---`getLBPrompt` handler for the text entry.
---@param entry ISTextEntryBox
---@return string?
---@protected
---@diagnostic disable-next-line: unused
function TextEntry._getEntryLBPrompt(entry) end

---`getRBPrompt` handler for the text entry.
---@param entry ISTextEntryBox
---@return string?
---@protected
---@diagnostic disable-next-line: unused
function TextEntry._getEntryRBPrompt(entry) end

---`isValidPrompt` handler for the text entry.
---@param entry ISTextEntryBox
---@return boolean
---@protected
function TextEntry._isEntryValidForPrompt(entry)
    return entry:isVisible()
end

---Called when the entry loses focus.
---@param notify boolean?
---@protected
function TextEntry:_onBlur(notify)
    if notify then
        core.callback.invoke(self.callbacks.blur)
    end

    if self.suggestBox then
        self.suggestBox:onBlurEntry()
    end
end

---`onCommandEntered` handler for the text entry.
---@param entry ISTextEntryBox
---@protected
function TextEntry._onEntryCommandEntered(entry)
    local parent = entry.parent ---@type TextEntry?
    if not parent or not parent.onCommandEntered then
        return
    end

    parent.onCommandEntered(parent)
end

---`onJoypadDown` handler for the text entry.
---@param entry ISTextEntryBox
---@param button integer
---@param joypadData JoypadData
---@protected
function TextEntry._onEntryJoypadDown(entry, button, joypadData)
    ISTextEntryBox.onJoypadDown(entry, button, joypadData)

    if OnScreenKeyboard.instance then
        OnScreenKeyboard.instance.prevFocus = nil
    end
end

---Called when the mouse is scrolled over the entry.
---@param entry ISTextEntryBox
---@param delta number
---@return boolean?
---@protected
function TextEntry._onEntryMouseWheel(entry, delta)
    local parent = entry.parent --[[@as TextEntry]]
    return parent.onMouseWheel(parent, delta)
end

---`onOtherKey` handler for the text entry.
---@param entry ISTextEntryBox
---@param key integer
---@protected
function TextEntry._onEntryOtherKey(entry, key)
    local parent = entry.parent ---@type TextEntry?
    if not parent or not parent.onOtherKey then
        return
    end

    parent.onOtherKey(parent, key)
end

---`onPressDown` handler for the text entry.
---@param entry ISTextEntryBox
---@protected
function TextEntry._onEntryPressDown(entry)
    local parent = entry.parent ---@type TextEntry?
    if not parent or not parent.onPressDown then
        return
    end

    parent.onPressDown(parent)
end

---`onPressUp` handler for the text entry.
---@param entry ISTextEntryBox
---@protected
function TextEntry._onEntryPressUp(entry)
    local parent = entry.parent ---@type TextEntry?
    if not parent or not parent.onPressUp then
        return
    end

    parent.onPressUp(parent)
end

---`onTextChange` handler for the text entry.
---@param entry ISTextEntryBox
---@protected
function TextEntry._onEntryTextChange(entry)
    local parent = entry.parent ---@type TextEntry?
    if not parent or not parent.onTextChange then
        return
    end

    parent.onTextChange(parent)
end

---Called when the entry gains focus.
---@param notify boolean?
---@protected
function TextEntry:_onFocus(notify)
    self.hasBeenFocused = true

    if notify then
        core.callback.invoke(self.callbacks.focus)
    end

    if self.suggestBox then
        self.suggestBox:onFocusEntry()
    end
end

---Syncs the entry size.
---@protected
function TextEntry:_resizeEntry()
    if not self.entry then
        return
    end

    self.entry:setX(self.padLeft)
    self.entry:setY(self.padTop)
    self.entry:setWidth(self.width * self.widthRatio - self.padRight - self.padLeft)
    self.entry:setHeight(self.height * self.heightRatio - self.padBottom - self.padTop)

    -- avoid frame growing beyond entry after resizing
    local obj = self.entry.javaObject
    if obj:getInset() > 2 then
        local frame = obj:getFrame() --[[@as UIElement]]
        frame:setX(self.entry.x)
        frame:setY(self.entry.y)
        frame:setWidth(self.entry.width)
        frame:setHeight(self.entry.height)
    end
end

---Updates the border color based on validation and enabled state.
---@protected
function TextEntry:_updateColors()
    local borderColor
    local textColor = self.textColor

    if not self:isEditable() then
        textColor = self.textColorDisabled
        borderColor = self.borderColorDisabled
    elseif self.valid then
        borderColor = self.borderColorValid
    else
        borderColor = self.borderColorInvalid
    end

    self.entry.borderColor = borderColor

    if self.entry.javaObject then
        self.entry.javaObject:setTextRGBA(textColor.r, textColor.g, textColor.b, textColor.a)
    end
end


---Creates a new text entry.
---@param args Args.TextEntry
---@return TextEntry
function TextEntry:new(args)
    local x = args.x or 0
    local y = args.y or 0
    local w = args.w or 0
    local h = args.h or 0

    local this = UI.new(self, TextEntry.__base.new, x, y, w, h)
    this:_setBaseArgs(args)

    this.init = {
        editable = args.editable ~= false,
        selectable = args.selectable ~= false,
        onlyNumbers = args.onlyNumbers or false,
        forceUppercase = args.forceUppercase or false,
        masked = args.masked or false,
        text = tostring(args.text or ''),
        maxLines = args.maxLines or 1,
        hasFrame = args.hasFrame or false,
        placeholderText = args.placeholderText,
        placeholderColor = core.color.defaultRGBA(args.placeholderColor, 0.5, 0.5, 0.5, 1.0),
    }

    this.valid = true
    this.hasBeenFocused = false
    this.x = x
    this.y = y
    this.width = w
    this.height = h

    this.widthRatio = 1
    this.heightRatio = 1
    this.padRight = 0
    this.padLeft = 0
    this.padBottom = 0
    this.padTop = 0

    this.minLength = args.minLength
    this.maxLength = args.maxLength
    this.minValue = args.minValue
    this.maxValue = args.maxValue
    this.requireNumber = args.requireNumber or false
    this.requireInteger = args.requireInteger or false
    this.requireValue = args.requireValue or (args.minLength ~= nil and args.minLength > 0)
    this.autoUpdateTooltip = args.autoUpdateTooltip ~= false

    this.font = args.font or UIFont.Medium
    this.tooltipText = args.tooltip
    this.validateTooltipText = args.validateTooltip
    this.borderColorValid = core.color.defaultRGBA(args.borderColorValid, 0.4, 0.4, 0.4, 1)
    this.borderColorInvalid = core.color.defaultRGBA(args.borderColorInvalid, 0.7, 0.1, 0.1, 0.7)
    this.borderColorDisabled = core.color.defaultRGBA(args.borderColorDisabled, 0.4, 0.4, 0.4, 0.5)

    this.borderColor = core.copy(this.borderColorValid)
    this.backgroundColor = core.color.defaultRGBA(args.backgroundColor, 0.0, 0.0, 0.0, 0.5)

    this.textColor = core.color.defaultRGBA(args.textColor, 1, 1, 1, 1)
    this.textColorDisabled = core.color.defaultRGBA(args.textColorDisabled, 0.5, 0.5, 0.5, this.textColor.a)

    this:setSuggestBox(args.suggestBox, true)

    this.callbacks = {}
    local target = args.target
    this:setOnKey(args.onKeyTarget or target, args.onKey, unpack(args.onKeyArgs or {}))
    this:setOnBlur(args.onBlurTarget or target, args.onBlur, unpack(args.onBlurArgs or {}))
    this:setOnFocus(args.onFocusTarget or target, args.onFocus, unpack(args.onFocusArgs or {}))
    this:setOnResize(args.onResizeTarget or target, args.onResize, unpack(args.onResizeArgs or {}))
    this:setOnChange(args.onChangeTarget or target, args.onChange, unpack(args.onChangeArgs or {}))
    this:setOnPressUp(args.onPressUpTarget or target, args.onPressUp, unpack(args.onPressUpArgs or {}))
    this:setOnOtherKey(args.onOtherKeyTarget or target, args.onOtherKey, unpack(args.onOtherKeyArgs or {}))
    this:setValidateFunction(args.validateTarget or target, args.validate, unpack(args.validateArgs or {}))
    this:setOnCommandEntered(args.onCommandTarget or target, args.onCommand, unpack(args.onCommandArgs or {}))
    this:setOnPressDown(args.onPressDownTarget or target, args.onPressDown, unpack(args.onPressDownArgs or {}))

    return this
end


return TextEntry

--#region Type Definitions

---@class Args.TextEntry : Args.BaseUI
---@field text? string The initial text of the entry.
---@field tooltip? string The tooltip text to use when the input is valid.
---@field validateTooltip? string The tooltip text to use when the input is invalid.
---@field font? UIFont The font to use for the text. Defaults to `UIFont.Medium`.
---@field minLength? integer The minimum string length of the entry.
---@field maxLength? integer The maximum string length of the entry.
---@field maxLines? integer The maximum lines in the entry.
---@field requireInteger? boolean If `true`, the text entry will not be valid if its content is not an integer.
---@field requireNumber? boolean If `true`, the text entry will not be valid if its content is not a number.
---@field requireValue? boolean If `true`, the text entry will not be valid if empty.
---@field minValue? number The minimum numeric value of the entry.
---@field maxValue? number The maximum numeric value of the entry.
---@field editable? boolean If `false`, the text entry will not be editable.
---@field selectable? boolean If `false`, the text in the entry will not be able to be selected.
---@field onlyNumbers? boolean If `true`, the text entry will only accept numbers as input.
---@field forceUppercase? boolean If `true`, text in the entry will be forced into uppercase.
---@field masked? boolean If `true`, characters typed into the entry will display as `*`.
---@field hasFrame? boolean If `true`, a frame will be added to the entry.
---@field autoUpdateTooltip? boolean Whether the tooltip should update based on the validation state.
---@field placeholderText? string The text to display when the input is empty.
---@field backgroundColor? ColorTableRGBA<number> The background color to use for the entry.
---@field placeholderColor? ColorTableRGBA<number> The color to use for placeholder text.
---@field borderColorValid? ColorTableRGBA<number> The border color to use when the entry is valid.
---@field borderColorInvalid? ColorTableRGBA<number> The border color to use when the entry is invalid.
---@field borderColorDisabled? ColorTableRGBA<number> The border color to use when the entry is disabled.
---@field textColor? ColorTableRGBA<number> The color to use for the entry.
---@field textColorDisabled? ColorTableRGBA<number> The color to use when the entry is disabled.
---@field suggestBox? SuggestBox The auto-suggest box associated with the entry.
---@field onBlur? UICallback Invoked when focus is lost.
---@field onBlurArgs? table Arguments for `onBlur`.
---@field onBlurTarget? any The first argument to pass to the `onBlur` callback.
---@field onChange? UICallback Invoked on text change.
---@field onChangeArgs? table Arguments for `onChange`.
---@field onChangeTarget? any The first argument to pass to the `onChange` callback.
---@field onCommand? UICallback Invoked when enter is pressed while focused.
---@field onCommandArgs? table Arguments for `onCommand`.
---@field onCommandTarget? any The first argument to pass to the `onCommand` callback.
---@field onFocus? UICallback Invoked when focus is gained.
---@field onFocusArgs? table Arguments for `onFocus`.
---@field onFocusTarget? any The first argument to pass to the `onFocus` callback.
---@field onResize? UICallback Invoked when the entry is resized.
---@field onResizeArgs? table Arguments for `onResize`.
---@field onResizeTarget? any The first argument to pass to the `onResize` callback.
---@field onKey? Callback.TextEntry.Key Invoked when a special key is pressed in the entry.
---@field onKeyArgs? table Arguments for `onKey`.
---@field onKeyTarget? any The first argument to pass to the `onKey` callback.
---@field onOtherKey? Callback.TextEntry.Key Invoked when a key tab or escape is pressed in the entry.
---@field onOtherKeyArgs? table Arguments for `onOtherKey`.
---@field onOtherKeyTarget? any The first argument to pass to the `onOtherKey` callback.
---@field onPressDown? UICallback Invoked when the down key is pressed in the entry.
---@field onPressDownArgs? table Arguments for `onPressDown`.
---@field onPressDownTarget? any The first argument to pass to the `onPressDown` callback.
---@field onPressUp? UICallback Invoked when the up key is pressed in the entry.
---@field onPressUpArgs? table Arguments for `onPressUp`.
---@field onPressUpTarget? any The first argument to pass to the `onPressUp` callback.
---@field validate? Callback.TextEntry.Validate Invoked for validation.
---@field validateArgs? table Arguments for `validate`.
---@field validateTarget? any The first argument to pass to the `validate` callback.
---@field target? any The default first argument to use for callbacks when a target is unspecified.

---@class InitArgs.TextEntry : Args.TextEntry, InitArgs.Shared


---@class TextEntry.Callbacks
---@field change? CallbackInfo Invoked on text change.
---@field focus? CallbackInfo Invoked when focus is gained.
---@field blur? CallbackInfo Invoked when focus is lost.
---@field key? CallbackInfo Invoked when a key is pressed in the entry.
---@field validate? CallbackInfo Invoked for validation.
---@field command? CallbackInfo Invoked when enter is pressed while focused.
---@field resize? CallbackInfo Invoked when the entry is resized.
---@field otherKey? CallbackInfo Invoked when tab or escape is pressed in the entry.
---@field up? CallbackInfo Invoked when the up key is pressed in the entry.
---@field down? CallbackInfo Invoked when the down key is pressed in the entry.

---@class TextEntry.Init
---@field text string The initial text of the entry.
---@field maxLines integer The maximum lines in the entry.
---@field editable boolean If `false`, the text entry will not be editable.
---@field selectable boolean If `false`, the text in the entry will not be able to be selected.
---@field onlyNumbers boolean If `true`, the text entry will only accept numbers as input.
---@field forceUppercase boolean If `true`, text in the entry will be forced into uppercase.
---@field masked boolean If `true`, characters typed into the entry will display as `*`.
---@field hasFrame? boolean If `true`, a frame will be added to the entry.
---@field placeholderText? string The text to display when the input is empty.
---@field placeholderColor? ColorTableRGBA<number> The color to use for placeholder text.
---@field scrollWidth? number A value to set for the scroll width.
---@field scrollHeight? number A value to set for the scroll height.
---@field xScroll? number A value to set for the X scroll position.
---@field yScroll? number A value to set for the Y scroll position.


---@alias Callback.TextEntry.Key fun(target: any?, key: integer, ...: any)

---@alias Callback.TextEntry.Validate fun(target: any?, text: string, ...: any): boolean?


--#endregion
