---Entry for color input with validation.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/Core/UI'
local TextEntry = require 'OmiLibrary/Component/UI/TextEntry'

local ReadError = core.color.ReadError
local ColorInfo = ColorInfo
local ISColorPicker = ISColorPicker
local ISColorPickerHSB = ISColorPickerHSB
local floor = math.floor
local setJoypadFocus = setJoypadFocus
local max = math.max
local getText = core.l10n.getText
local textManager = getTextManager()


---@class ColorEntry : TextEntry
---@field protected emptyColor ColorTable<integer> The color to use if the entry is blank.
---@field protected minValue integer The minimum RGB value of each color component.
---@field protected maxValue integer The maximum RGB value of each color component.
---@field protected currentColor ColorInfo The current color of the entry.
---@field protected colorBtn Button The button for opening the color picker.
---@field protected colorPicker ISColorPicker | ISColorPickerHSB The color picker component.
---@field protected hsb boolean Flag for whether the color entry uses an HSB color picker.
---@field protected __base TextEntry The base class.
local ColorEntry = TextEntry:derive('OmiColorEntry')


---Formats a color for the text entry.
---@param color ColorTable<integer>
---@return string
function ColorEntry:formatColor(color)
    return core.color.toRGBString(color)
end

---Formats a decimal color for the text entry.
---@param color ColorTable<number>
---@return string
function ColorEntry:formatDecimalColor(color)
    return self:formatColor(core.color.decimalToInteger(color))
end

---Gets the current color table, or `nil` if the color is not valid.
---@return ColorTable<integer>?
function ColorEntry:getColor()
    return (self:stringToColor(self:getInternalText()))
end

---Returns the color used when the entry is empty.
---@return ColorTable<integer>
function ColorEntry:getEmptyColor()
    return self.emptyColor
end

---Returns the maximum value of color components.
---@return integer
function ColorEntry:getMaxValue()
    return self.maxValue
end

---Returns the minimum value of color components.
---@return integer
function ColorEntry:getMinValue()
    return self.minValue
end

---Initializes the entry.
function ColorEntry:initialise()
    TextEntry.initialise(self)

    local fontHgt = textManager:getFontHeight(self.font)

    -- scale padding based on medium font
    local btnPadding = 5 * (fontHgt / textManager:getFontHeight(UIFont.Medium))

    local btnSize = fontHgt + 4
    local entryW = self.width - btnSize - btnPadding
    self.entry:setWidth(entryW)
    self.padRight = btnSize + btnPadding

    self.colorBtn = UI.button {
        parent = self,
        x = entryW + btnPadding,
        w = btnSize,
        h = btnSize,
        backgroundColor = { r = 1, g = 1, b = 1, a = 1 },
        target = self,
        onClick = self.onColorPicker,
    }

    if self.hsb then
        self.colorPicker = ISColorPickerHSB:new(0, 0, self.currentColor)
    else
        self.colorPicker = ISColorPicker:new(0, 0)
        self.colorPicker:setInitialColor(self.currentColor)
    end

    self.colorPicker.pickedTarget = self
    self.colorPicker.otherFct = true
    self.colorPicker.parent = self
    self.colorPicker.onMouseDownOutside = self._onColorPickerMouseDownOutside --[[@as function]]
    self.colorPicker.removeSelf = self._removeColorPicker
    self.colorPicker.setVisible = self._setColorPickerVisible --[[@as function]]

    self.colorPicker:initialise()
    self.colorPicker:addToUIManager()
    self.colorPicker:setVisible(false)

    self:removeOnDestroy(self.colorPicker)

    if not self.hsb and (self.minValue ~= 0 or self.maxValue ~= 255) then
        self:updateColorPickerColors()
    end

    self:updateColor()
end

---Handler for when the button to open the color picker is clicked.
---@param button ISButton
function ColorEntry:onColorPicker(button)
    self.colorPicker:setInitialColor(self.currentColor)
    self.colorPicker:setX(button:getAbsoluteX() + button:getWidth())
    self.colorPicker:setY(button:getAbsoluteY())
    self.colorPicker.pickedFunc = self.selectDecimalColor --[[@as function]]
    self.colorPicker:setVisible(true)
    self.colorPicker:addToUIManager()
    self.colorPicker:bringToTop()
    setJoypadFocus(self:getPlayerNum(), self.colorPicker)
end

---Called when the color entry text changes.
function ColorEntry:onTextChange()
    self:updateColor()
    TextEntry.onTextChange(self)
end

---Updates the current color of the entry, and updates the text to match.
---@param color ColorTable<integer> Color table with values in [0, 255].
function ColorEntry:selectColor(color)
    self:selectDecimalColor(core.color.integerToDecimal(color))
end

---Updates the current color of the entry, and updates the text to match.
---@param color ColorTable<number> Color table with values in [0, 1].
function ColorEntry:selectDecimalColor(color)
    color = core.color.clamp(color, self.minValue / 255, self.maxValue / 255)

    self.currentColor = ColorInfo.new(color.r, color.g, color.b, 1)
    self.colorBtn.backgroundColor = { r = color.r, g = color.g, b = color.b, a = 1 }

    if self.colorPicker and not self.colorPicker.joyfocus then
        self.colorPicker:setVisible(false)
    end

    self:setText(self:formatDecimalColor(color), true)
end

---Sets whether the entry is editable.
---@param editable boolean
function ColorEntry:setEditable(editable)
    TextEntry.setEditable(self, editable)
    self.colorBtn.enable = editable

    if not editable then
        self.colorPicker:setVisible(false)
    end
end

---Sets the color that is used when the input is empty.
---@param emptyColor ColorTable<integer>
function ColorEntry:setEmptyColor(emptyColor)
    self.emptyColor = emptyColor
    self:updateColor()
end

---Sets the maximum value of color components.
---@param val integer A number in the range [0, 255].
function ColorEntry:setMaxValue(val)
    self.maxValue = val
end

---Sets the minimum value of color components.
---@param val integer A number in the range [0, 255].
function ColorEntry:setMinValue(val)
    self.minValue = val
end

---Sets the current text of the entry.
---@param text string The text to set on the entry.
---@param notifyChanged boolean? Whether this should trigger onTextChange. Defaults to `true`.
function ColorEntry:setText(text, notifyChanged)
    TextEntry.setText(self, text, notifyChanged ~= false)
end

---Converts a string to a color table, returning an error message instead if parsing the string failed.
---@param text string A color string, in RGB or hex format.
---@return ColorTable<integer>? result
---@return string? error
function ColorEntry:stringToColor(text)
    local result, err = core.color.fromString(text, {
        minColorValue = self.minValue,
        maxColorValue = self.maxValue,
    })

    if result then
        return result
    end

    if err == ReadError.ABOVE_MAX then
        return nil, getText('@error.values-max', { max = self.maxValue })
    end

    if err == ReadError.BELOW_MIN then
        return nil, getText('@error.values-min', { min = self.minValue })
    end

    return nil, getText('@error.require-color')
end

---Updates the color picker button to match the color specified in the input.
function ColorEntry:updateColor()
    local text = self:getInternalText()

    local color
    if not self.requireValue and #core.trim(text) == 0 then
        color = self.emptyColor
    else
        color = self:stringToColor(text)
        if not color then
            return
        end
    end

    local r, g, b = color.r / 255, color.g / 255, color.b / 255
    self.currentColor = ColorInfo.new(r, g, b, 1)
    if self.colorBtn then
        self.colorBtn.backgroundColor = { r = r, g = g, b = b, a = 1 }
    end
end

---Updates the color picker's colors based on the set minimum and maximum values.
---This has no effect if using the HSB color picker.
function ColorEntry:updateColorPickerColors()
    if self.hsb then
        return
    end

    local columns = 18
    local rows = 12

    local colors = {}
    local minVal = self.minValue
    local maxVal = self.maxValue
    local delta = max(1, floor((maxVal - minVal) / 5))

    --#region modified code from ISColorPicker

    local i = 0
    local newColor = Color.new(1, 1, 1, 1)
    for red = minVal, maxVal, delta do
        for green = minVal, maxVal, delta do
            for blue = minVal, maxVal, delta do
                local col = i % columns
                local row = floor(i / columns) ---@type number
                if row % 2 == 0 then row = row / 2 else row = floor(row / 2) + 6 end

                newColor:set(red / 255, green / 255, blue / 255, 1)
                colors[col + row * columns + 1] = {
                    r = newColor:getRedFloat(),
                    g = newColor:getGreenFloat(),
                    b = newColor:getBlueFloat(),
                }

                i = i + 1
            end
        end
    end

    --#endregion

    if self.colorPicker then
        ---@cast self.colorPicker ISColorPicker
        self.colorPicker:setColors(colors, columns, rows)
    end
end

---Tests the validation function.
---@param text string?
---@return boolean valid
function ColorEntry:validate(text)
    if not text then
        text = self:getInternalText()
    end

    if not TextEntry.validate(self, text) then
        return false
    end

    if #core.trim(text) == 0 then
        return true
    end

    local result, error = self:stringToColor(text)
    if error then
        self:setValidateTooltipText(error)
    end

    return result ~= nil
end


---`getXPrompt` handler for the text entry.
---@param entry ISTextEntryBox
---@return string?
---@protected
---@diagnostic disable-next-line: unused
function ColorEntry._getEntryXPrompt(entry)
    return getText('OmiLibrary.prompt-color-picker')
end

---`removeSelf` handler for the color picker.
---@param colorPicker ISColorPicker
---@protected
function ColorEntry._removeColorPicker(colorPicker)
    colorPicker:setVisible(false)
end

---`onMouseDownOutside` handler for the color picker.
---Hides the provided color picker.
---@param colorPicker ISColorPicker
---@param x number
---@param y number
---@protected
function ColorEntry._onColorPickerMouseDownOutside(colorPicker, x, y)
    if x < 0 or y < 0 or x > colorPicker.width or y > colorPicker.height then
        colorPicker:setVisible(false)
    end

    return true
end

---`onJoypadDown` handler for the text entry.
---@param entry ISTextEntryBox
---@param button integer
---@param joypadData table
---@protected
function ColorEntry._onEntryJoypadDown(entry, button, joypadData)
    local parent = entry.parent ---@type ColorEntry?
    if not parent then
        return
    end

    if button == Joypad.XButton then
        parent:onColorPicker(parent.colorBtn)
    else
        TextEntry._onEntryJoypadDown(entry, button, joypadData)
    end
end

---`setVisible` handler for the color picker.
---@param colorPicker ISColorPicker
---@param visible boolean
---@protected
function ColorEntry._setColorPickerVisible(colorPicker, visible)
    ISPanelJoypad.setVisible(colorPicker, visible)

    if visible then
        return
    end

    local parent = colorPicker.parent ---@type ColorEntry?
    if parent then
        setJoypadFocus(parent:getPlayerNum(), parent:getInternalEntry())
    end
end


---Creates a new color entry box.
---@param args Args.ColorEntry
---@return ColorEntry
function ColorEntry:new(args)
    local this = UI.new(self, TextEntry.new, args)

    local defaultColor = args.defaultColor ---@type ColorTable<integer>?
    if defaultColor and not args.text then
        this.init.text = this:formatColor(defaultColor)
    end

    defaultColor = core.copy(core.color.default(defaultColor, 255, 255, 255))

    this.currentColor = ColorInfo.new(defaultColor.r / 255, defaultColor.g / 255, defaultColor.b / 255, 1)
    this.emptyColor = core.copy(args.emptyColor or defaultColor or { r = 255, g = 255, b = 255 })
    this.minValue = this.minValue or 0
    this.maxValue = this.maxValue or 255
    this.hsb = args.hsb or false

    return this
end


return ColorEntry

--#region Type Definitions

---@class Args.ColorEntry : Args.TextEntry
---@field minValue? integer The minimum RGB value of each color component.
---@field maxValue? integer The maximum RGB value of each color component.
---@field defaultColor? ColorTable<integer> The color to use in the color entry by default.
---@field emptyColor? ColorTable<integer> The color to use when the entry is empty.
---@field hsb? boolean Flag for whether the color entry uses an HSB color picker.


---@class InitArgs.ColorEntry : Args.ColorEntry, InitArgs.TextEntry, InitArgs.Shared

--#endregion
