---UI element for a dialog box.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/UI/Core'
local Panel = require 'OmiLibrary/Component/UI/Panel'

local max = math.max
local getText = core.l10n.getText
local ISMouseDrag = ISMouseDrag ---@type any
local textManager = getTextManager()


---@class Dialog : Panel, BaseUI
---@field moveWithMouse boolean Whether the dialog can be moved by dragging it.
---@field backgroundColor ColorTableRGBA<number> The background color of the dialog.
---@field borderColor ColorTableRGBA<number> The border color of the dialog.
---@field background boolean Whether the background and border should be rendered.
---@field chatText? RichTextPanel The rich text panel for the dialog.
---@field protected init Dialog.Init Information used only during initialization.
---@field protected callbacks Dialog.Callbacks Callbacks for the dialog.
---@field protected text? string The text of the dialog.
---@field protected richText boolean If `true`, the dialog will be treated as a rich text.
---@field protected textFont UIFont The font to use for the dialog text.
---@field protected btnFont UIFont The font to use for buttons.
---@field protected yesBtn? ISButton The 'Yes' button.
---@field protected noBtn? ISButton The 'No' button.
---@field protected okBtn? ISButton The 'Ok' button.
---@field protected cancelBtn? ISButton The 'Cancel' button.
---@field protected buttons ISButton[] The buttons of the dialog.
---@field protected includeTitlebar boolean Whether to render a title bar.
---@field protected titlebarTex Texture The texture to use for the title bar.
---@field protected btnContainer ISUIElement Container for buttons.
---@field protected minBtnW number Minimum width to fit buttons.
---@field protected minBtnH number Minimum height to fit buttons.
---@field protected autoUpdateSize boolean Whether the minimum size to fit the content should be maintained.
---@field protected lastTextH number The last calculated text height.
---@field protected __base Panel The base class.
local Dialog = Panel:derive('OmiDialog')


---Calculates the ideal size of the dialog.
---@return number
---@return number
function Dialog:calcSize()
    local padW, padH = self:_getPadding()
    local minW, minH = self:_calcMinSize()
    return max(self.width, minW + padW), max(self.height, minH + padH)
end

---Calculates the width and height of the text.
---@return number
---@return number
function Dialog:calcTextSize()
    if self.richText and self.chatText then
        local height = self.chatText:getScrollHeight()
        self.lastTextH = height

        return 50, height
    end

    local text = self.text or ''
    local textW = 0
    local lines = text:split('\n')
    for i = 1, #lines do
        textW = max(textW, textManager:MeasureStringX(self.textFont, lines[i]))
    end

    local fontH = textManager:getFontHeight(self.textFont)
    local textH = fontH * #lines

    self.lastTextH = textH
    return textW, textH
end

---Sets the X and Y position of the dialog so that it's centered on screen.
function Dialog:centerOnScreen()
    local x, y = UI.getScreenCenter(self.width, self.height, self.playerNum)
    self:setX(x)
    self:setY(y)
end

---Returns the height of dialog buttons.
---@return number
function Dialog:getButtonHeight()
    return max(25, textManager:getFontHeight(self.btnFont) + 6)
end

---Returns a list of the current buttons on the dialog.
---@return ISButton[]
function Dialog:getButtons()
    return self.buttons
end

---Returns the height of the title bar.
---@return number
function Dialog:titleBarHeight()
    if not self.includeTitlebar then
        return 0
    end

    return 16
end

---Initializes the dialog.
function Dialog:initialise()
    Panel.initialise(self)

    self:_initialiseChildren()
    self:setRichText(self.richText)
    self:_updateSize(true)
end

---Returns `true` if the dialog is a rich text dialog.
---@return boolean
function Dialog:isRichText()
    return self.richText
end

---Called at the beginning of each render.
function Dialog:prerender()
    Panel.prerender(self)

    if self.background then
        local bgColor = self.backgroundColor
        local bdColor = self.borderColor

        self:drawRectStatic(0, 0, self.width, self.height, bgColor.a, bgColor.r, bgColor.g, bgColor.b)
        self:drawRectBorderStatic(0, 0, self.width, self.height, bdColor.a, bdColor.r, bdColor.g, bdColor.b)
    end

    if self.includeTitlebar then
        local th = self:titleBarHeight()
        self:drawTextureScaled(self.titlebarTex, 2, 1, self.width - 4, th - 2, 1, 1, 1, 1)
    end

    if not self.richText and not self.chatText and self.text then
        self:drawTextCentre(self.text, self.width * 0.5, self:_getTextY(), 1, 1, 1, 1, self.textFont)
    end

    local joyData = JoypadState.players[self.playerNum + 1]
    if joyData and joyData.focus == self then
        self:drawRectBorder(0, 0, self:getWidth(), self:getHeight(), 0.4, 0.2, 1, 1)
        self:drawRectBorder(1, 1, self:getWidth() - 2, self:getHeight() - 2, 0.4, 0.2, 1, 1)
    end
end

---Sets the height of the dialog to the minimum height to fit its content.
function Dialog:setHeightToContents()
    local _, height = self:_calcMinSize()
    self:setHeight(height)
    self:ignoreHeightChange()
    self:updateButtons()
end

---Sets the callback for clicking a dialog button.
---@param target any?
---@param callback Callback.Dialog.Click?
---@param ...any
function Dialog:setOnClick(target, callback, ...)
    self.callbacks.click = core.callback(target, callback, ...)
end

---Sets the callback for resize.
---@param target any?
---@param callback Callback.Dialog.Resize?
---@param ...any
function Dialog:setOnResize(target, callback, ...)
    self.callbacks.resize = core.callback(target, callback, ...)
end

---Sets whether the dialog is a rich text dialog.
---@param isRichText boolean
function Dialog:setRichText(isRichText)
    self.richText = isRichText

    if not isRichText and self.chatText then
        self:removeChild(self.chatText)
        self.chatText = nil
    elseif isRichText and not self.chatText then
        self.chatText = UI.richTextPanel {
            parent = self,
            x = 2,
            y = self:_getTextY(),
            w = self.width - 4,
            h = max(50, self.height - self:getButtonHeight() - 10),
            marginLeft = 20,
            marginRight = 20,
            addVerticalScrollbar = true,
            background = false,
            clip = true,
            autosetheight = false,
            text = self.text,
            font = self.textFont,
        }
    end
end

---Called when a dialog button is clicked.
---@param button ISButton
function Dialog:onClick(button)
    core.callback.invoke(self.callbacks.click, self:_getClickArgs(button))
    self:destroy()
end

---Called when joypad focus is gained.
---@param joypadData table
function Dialog:onGainJoypadFocus(joypadData)
    Panel.onGainJoypadFocus(self, joypadData)

    local buttons = self:getButtons()
    for i = 1, #buttons do
        local btn = buttons[i]
        if i == 1 then
            self:setISButtonForA(btn)
        elseif i == 2 then
            self:setISButtonForB(btn)
        elseif i == 3 then
            self:setISButtonForX(btn)
        else
            self:setISButtonForY(btn)
            break
        end
    end
end

---Called when joypad focus is lost.
---@param joypadData table
function Dialog:onLoseJoypadFocus(joypadData)
    Panel.onLoseJoypadFocus(self, joypadData)

    local buttons = self:getButtons()
    for i = 1, #buttons do
        buttons[i]:clearJoypadButton()
    end
end

---Called when the mouse is pressed within the dialog.
---@param x number
---@param y number
---@diagnostic disable-next-line: unused
function Dialog:onMouseDown(x, y)
    if not self.moveWithMouse or not self:getIsVisible() then
        return
    end

    self.moving = true
    self:bringToTop()
end

---Called when the mouse is moved within the dialog.
---@param dx number
---@param dy number
function Dialog:onMouseMove(dx, dy)
    if not self.moveWithMouse then
        return
    end

    self.mouseOver = true
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

---Called when the mouse is moved outside of the dialog.
---@param dx number
---@param dy number
function Dialog:onMouseMoveOutside(dx, dy)
    if not self.moveWithMouse then
        return
    end

    self.mouseOver = false
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

---Called when the mouse is released within the dialog.
---@param x number
---@param y number
function Dialog:onMouseUp(x, y)
    if not self.moveWithMouse or not self:getIsVisible() then
        return
    end

    self.moving = false
    if ISMouseDrag.tabPanel then
        ISMouseDrag.tabPanel:onMouseUp(x, y)
    end

    ISMouseDrag.dragView = nil
end

---Called when the mouse is released outside of the dialog.
---@param x number
---@param y number
---@diagnostic disable-next-line: unused
function Dialog:onMouseUpOutside(x, y)
    if not self.moveWithMouse or not self:getIsVisible() then
        return
    end

    self.moving = false
    ISMouseDrag.dragView = nil
end

---Called when the dialog is resized.
function Dialog:onResize()
    ISUIElement.onResize(self)
    self:_updateSize()
    core.callback.invoke(self.callbacks.resize, self)
end

---Called every 100ms.
function Dialog:update()
    Panel.update(self)

    if self.chatText then
        self:_updateSize()
    end
end

---Updates the dialog buttons.
function Dialog:updateButtons()
    local container = self.btnContainer
    container:setX(0)
    container:setWidth(self.width)
    local buttons = self:getButtons()
    if #buttons == 0 then
        return
    end

    local btnRows = self:_getButtonRows()
    local height = #btnRows * self:getButtonHeight() + (#btnRows - 1) * 10
    container:setHeight(height)
    container:setY(self.height - height - 10)

    local y = 0
    local maxWidth = 0.0
    local center = container.width * 0.5
    for i = 1, #btnRows do
        local row = btnRows[i]

        local btn1 = row[1]
        local btn1Width = btn1.width
        btn1:setY(y)

        local btn2 = row[2]
        local btn3 = row[3]
        if #row == 1 then
            btn1:setX(center - btn1Width * 0.5)
            maxWidth = max(maxWidth, btn1Width)
        elseif #row == 2 then
            btn1:setX(center - btn1Width - 5)
            btn2:setX(center + 5)
            btn2:setY(y)
            maxWidth = max(maxWidth, btn1Width + btn2.width + 10)
        elseif #row == 3 then
            local btn2Width = btn2.width
            btn2:setX(center - btn2Width * 0.5)
            btn1:setX(btn2:getX() - btn1Width - 10)
            btn3:setX(btn2:getRight() + 10)
            btn2:setY(y)
            btn3:setY(y)
            maxWidth = max(maxWidth, btn1Width + btn2Width + btn3.width + 20)
        end

        y = y + btn1.height + 10
    end

    self.minBtnW = maxWidth
    self.minBtnH = height
end


---Adds a single dialog button.
---@param text string Button text.
---@param internal string Button internal id.
---@return ISButton
---@protected
function Dialog:_addButton(text, internal)
    return UI.button {
        parent = self.btnContainer,
        w = 100,
        h = self:getButtonHeight(),
        text = text,
        internal = internal,
        anchorTop = false,
        anchorBottom = false,
        anchorLeft = false,
        anchorRight = false,
        borderColor = { r = 1, g = 1, b = 1, a = 0.1 },
        target = self,
        onClick = self.onClick,
    }
end

---Creates the dialog's buttons based on a dialog type.
---@param type DialogType
---@protected
function Dialog:_addButtons(type)
    if type == 'YesNo' or type == 'YesNoCancel' then
        self.yesBtn = self:_addButton(self.init.yesText, 'YES')
        self.noBtn = self:_addButton(self.init.noText, 'NO')
        self.yesBtn:enableAcceptColor()
        self.noBtn:enableCancelColor()
    else
        self.okBtn = self:_addButton(self.init.okText, 'OK')
        self.okBtn:enableAcceptColor()
    end

    if type == 'YesNoCancel' or type == 'OKCancel' then
        self.cancelBtn = self:_addButton(self.init.cancelText, 'CANCEL')
        self.cancelBtn:enableCancelColor()
    end

    local buttons = self.buttons
    buttons[#buttons + 1] = self.okBtn
    buttons[#buttons + 1] = self.yesBtn
    buttons[#buttons + 1] = self.noBtn
    buttons[#buttons + 1] = self.cancelBtn

    self:updateButtons()
end

---Calculates the minimum size of the dialog.
---@return number
---@return number
---@protected
function Dialog:_calcMinSize()
    local textW, textH = self:calcTextSize()
    local btnW, btnH = self.minBtnW, self.minBtnH

    return max(textW, btnW), textH + btnH
end

---Gets the row layout for buttons.
---@return ISButton[][]
---@protected
function Dialog:_getButtonRows()
    local buttons = self.buttons

    if #buttons <= 3 then
        return { buttons }
    elseif #buttons == 4 then
        return {
            { buttons[1], buttons[2] },
            { buttons[3], buttons[4] },
        }
    end

    local rows = {}
    for i = 1, #buttons, 3 do
        rows[#rows + 1] = {
            buttons[i],
            buttons[i + 1],
            buttons[i + 2],
        }
    end

    return rows
end

---Gets arguments to pass to a click callback.
---@param button ISButton
---@return Args.Dialog.Click
---@protected
function Dialog:_getClickArgs(button)
    return {
        dialog = self,
        button = button,
        internal = button.internal,
    }
end

---Returns the width and height padding of the dialog.
---@return number
---@return number
---@protected
function Dialog:_getPadding()
    return 20, 50 + self:titleBarHeight()
end

---Gets the Y position of the text.
---@return number
---@protected
function Dialog:_getTextY()
    local offset = self.richText and 2 or 20
    return self:titleBarHeight() + offset
end

---Creates the children of the dialog.
---@protected
function Dialog:_initialiseChildren()
    local btnH = self:getButtonHeight()
    self.btnContainer = ISUIElement:new(0, self.height - btnH - 10, self.width, btnH + 10)
    self.btnContainer.anchorTop = false

    self:addChild(self.btnContainer)
    self:_addButtons(self.init.dialogType)
end

---Updates dialog controls.
---@protected
function Dialog:_updateControls()
    self:updateButtons()
end

---Updates the dialog size based on the minimum size, if the option is enabled.
---@param forceUpdate boolean?
---@protected
function Dialog:_updateSize(forceUpdate)
    if not forceUpdate and not self.autoUpdateSize then
        return
    end

    self:updateButtons()
    local width, height = self:calcSize()
    self:setSize(width, height)

    if self.chatText then
        local oldW = self.chatText.width
        local oldH = self.chatText.height
        self.chatText:setWidth(width - 4)
        self.chatText:setHeight(max(50, height - self:getButtonHeight() - 10))

        local w = self.chatText.width
        local h = self.chatText.height
        if w ~= oldW or h ~= oldH then
            self.chatText:paginate()
        end
    end

    self:_updateControls()
end


---Creates a new dialog box.
---@param args Args.Dialog
---@return Dialog
function Dialog:new(args)
    args = core.copy(args)
    if not args.w and not args.h then
        args.w = 250
    end

    local this = UI.new(self, Panel.new, args)
    this._clearFocusOnDestroy = true
    this.doOriginalPrerender = false

    this.init = {
        yesText = args.yesText or getText('@ui.btn-yes'),
        noText = args.noText or getText('@ui.btn-no'),
        okText = args.okText or getText('@ui.btn-ok'),
        cancelText = args.cancelText or getText('@ui.btn-cancel'),
        dialogType = args.type or 'OK',
    }

    this.text = args.text
    this.textFont = args.font or UIFont.Small
    this.btnFont = args.btnFont or UIFont.Small
    this.autoUpdateSize = args.autoUpdateSize ~= false
    this.includeTitlebar = args.includeTitlebar or false
    this.moveWithMouse = args.moveWithMouse ~= false
    this.backgroundColor = core.color.defaultRGBA(args.backgroundColor, 0, 0, 0, 0.8)
    this.borderColor = core.color.defaultRGBA(args.borderColor, 0.4, 0.4, 0.4, 1)
    this.richText = args.richText or false

    local defaultTarget = args.target or (args.targetSelf and this or nil)
    this.callbacks = {}
    this:setOnClick(args.onClickTarget or defaultTarget, args.onClick, unpack(args.onClickArgs or {}))
    this:setOnResize(args.onResizeTarget or args.target, args.onResize, unpack(args.onResizeArgs or {}))

    this.minBtnW = 0
    this.minBtnH = 0
    this.lastTextH = 0
    this.titlebarTex = getTexture('media/ui/Panel_TitleBar.png')
    this.buttons = {}

    return this
end


return Dialog

--#region Type Definitions

---@class Args.Dialog : Args.Panel
---@field font? UIFont The font to use for the dialog text.
---@field btnFont? UIFont The font to use for buttons.
---@field type? DialogType The type of dialog to create.
---@field text? string The text of the dialog.
---@field okText? string Text for the 'Ok' button.
---@field cancelText? string Text for the 'Cancel' button.
---@field yesText? string Text for the 'Yes' button.
---@field noText? string Text for the 'No' button.
---@field moveWithMouse? boolean Whether the dialog can be moved by dragging it.
---@field autoUpdateSize? boolean Whether the minimum size to fit the content should be maintained.
---@field includeTitlebar? boolean Whether to render a title bar.
---@field backgroundColor? ColorTableRGBA<number> The color to use for the background.
---@field borderColor? ColorTableRGBA<number> The color to use for the border.
---@field richText? boolean If `true`, the dialog will be treated as a rich text.
---@field onClick? Callback.Dialog.Click Invoked when a dialog button is clicked.
---@field onClickArgs? table Arguments for `onClick`.
---@field onClickTarget? any The first argument to pass to the `onClick` callback.
---@field onResize? Callback.Dialog.Resize Invoked when the dialog is resized.
---@field onResizeArgs? table Arguments for `onResize`.
---@field onResizeTarget? table The first argument to pass to the `onResize` callback.
---@field target? any The default first argument to use for callbacks when a target is unspecified.
---@field targetSelf? boolean Flag for whether the default first argument for callbacks should be the created instance.

---@class Args.Dialog.Click
---@field button ISButton The button that was clicked.
---@field internal? string The internal identifier of the button.
---@field dialog Dialog The dialog.

---@class InitArgs.Dialog : Args.Dialog, InitArgs.Shared
---@field setHeightToContents? boolean If `true`, the dialog will have its height set to the minimum height to fit its content.


---@class Dialog.Callbacks
---@field click? CallbackInfo Invoked when a dialog button is clicked.
---@field resize? CallbackInfo Invoked when the dialog is resized.

---@class Dialog.Init
---@field yesText string Text for the 'Yes' button.
---@field noText string Text for the 'No' button.
---@field okText string Text for the 'Ok' button.
---@field cancelText string Text for the 'Cancel' button.
---@field dialogType DialogType Dialog type.


---@alias Callback.Dialog.Click fun(target: any?, args: Args.Dialog.Click, ...: any)

---@alias Callback.Dialog.Resize fun(target: any?, dialog: Dialog, ...: any)

---@alias DialogType
---| 'OK'
---| 'OKCancel'
---| 'YesNo'
---| 'YesNoCancel'

---@alias DialogEntryType
---| 'Text'
---| 'Color'

---@alias InitArgs.AnyDialog
---| InitArgs.Dialog
---| InitArgs.TextDialog
---| InitArgs.ColorDialog

--#endregion
