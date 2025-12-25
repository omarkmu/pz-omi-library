---UI element for a rich text panel.
---Based on the vanilla ISRichTextPanel.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/UI/Core'
local Panel = require 'OmiLibrary/Component/UI/Panel'

local max = math.max
local min = math.min
local concat = table.concat
local getKeyName = getKeyName
local getTimestampMs = getTimestampMs
local getTextManager = getTextManager

local gameCore = getCore()
local textManager = getTextManager()
local attributeParser = UI.AttributeParser:new()


---@class RichTextPanel : Panel
---@field autosetheight boolean If `false`, the panel won't automatically set its height based on the content.
---@field autoRemoveItems boolean? Flag for whether unused cached items will be removed from the panel on paginate.
---@field clip boolean If `false`, the panel won't set a stencil rect for its content.
---@field clipPrerender? boolean If `true`, the stencil rect will be applied during prerender.
---@field contentTransparency number The content transparency value for rich text items.
---@field defaultFont UIFont The default font to use before changes from rich text commands.
---@field defaultTextColor ColorTable<number> The default text color of the panel.
---@field defaultLinkColor ColorTable<number> The default text color to use for links.
---@field h1Color ColorTable<number> The text color to use for the H1 style.
---@field h2Color ColorTable<number> The text color to use for the H2 style.
---@field regularTextColor ColorTable<number> The text color to use for the regular text style.
---@field drawMargins boolean Whether to draw margins for the panel.
---@field imagePad number The left padding to add to images.
---@field buttonPad number The left padding to add to buttons.
---@field marginTop number The top margin of the panel.
---@field marginBottom number The bottom margin of the panel.
---@field marginLeft number The left margin of the panel.
---@field marginRight number The right margin of the panel.
---@field maxLines integer The maximum number of lines in the rich text content.
---@field text string The rich text content of the panel.
---@field useContextSpacing boolean If `true`, the panel will use context-based spacing.
---@field indent number The current indentation of the rich text panel.
---@field imageCount integer The current index to add a new image element to.
---@field videoCount integer The current index to add a new video element to.
---@field font UIFont The current font.
---@field fonts table<integer, UIFont> The font to use for a given line.
---@field buttons table<integer, Button> Buttons to includes
---@field images table<integer, Texture> Images to draw.
---@field imageX table<integer, number> X positions for images.
---@field imageY table<integer, number> Y positions for images.
---@field imageW table<integer, number> W positions for images.
---@field imageH table<integer, number> H positions for images.
---@field videos table<integer, VideoTexture> Videos to draw.
---@field videoX table<integer, number> X positions for videos.
---@field videoY table<integer, number> Y positions for videos.
---@field videoW table<integer, number> W positions for videos.
---@field videoH table<integer, number> H positions for videos.
---@field lines table<integer, string> Lines of text to display.
---@field lineX table<integer, number> X positions for lines.
---@field lineY table<integer, number> Y positions for lines.
---@field rgb table<integer, ColorTable<number>> Colors to use for lines.
---@field rgbCurrent ColorTable<number> The current RGB text color value.
---@field rgbStack ColorTable<number>[] The current stack of text colors.
---@field orient table<integer, string> The text orientation to use for  a given line.
---@field keybinds table<string, string> Associates keybind names to key names.
---@field r number The current red value of the text color.
---@field g number The current green value of the text color.
---@field b number The current blue value of the text color.
---@field lastChar string The last character added to a line during pagination.
---@field maxLineWidth number? The maximum width of a line.
---@field protected callbacks RichTextPanel.Callbacks Container for callbacks.
---@field protected keyColorCommand string The command to use for the key color.
---@field protected hovers table<integer, RichTextPanel.Hover> Information about hover text and actions.
---@field protected computedHovers RichTextPanel.ComputedHover[] Computed hovers with bounds for faster checking.
---@field protected strikethroughs table<integer, RichTextPanel.RangeElement> Information about strikethroughs.
---@field protected underlines table<integer, RichTextPanel.RangeElement> Information about underlines.
---@field protected currentHover? RichTextPanel.ComputedHover Information about the currently hovered area.
---@field protected items table<integer, RichTextPanel.CachedItem> Associates item IDs to items that can be used in hovers.
---@field protected mouseLeftWasDown? boolean Flag for whether the left mouse button was pressed over the current hover.
---@field protected mouseRightWasDown? boolean Flag for whether the right mouse button was pressed over the current hover.
---@field protected hoverTooltip? Tooltip | TooltipInv The tooltip for the current hover.
---@field protected fontHgt number The height of the current font.
---@field protected angelCodeFont AngelCodeFont The font object for the current font.
---@field protected log? Logger Logger to use to log errors.
---@field protected __base Panel The base class.
local RichTextPanel = Panel:derive('OmiRichTextPanel')
RichTextPanel.Command = require 'OmiLibrary/Component/UI/RichTextCommands'

---Set of commands that support attribute arguments.
---@protected
RichTextPanel.AttributeCommands = {
    HOVER = true,
    LINK = true,
    BUTTON = true,
    BUTTONCENTRE = true,
}


---Determines the end position of a command.
---@param text string The command text to search.
---@param startPos integer The position to start looking in the text.
---@return integer?
function RichTextPanel.findCommandEnd(text, startPos)
    local nextBracket = text:find('>', startPos)
    if not nextBracket then
        -- unterminated command
        return
    end

    local name, nameEnd = RichTextPanel.findCommandName(text, startPos, nextBracket)
    if not name or not nameEnd then
        return
    end

    if not RichTextPanel.AttributeCommands[name] or text:sub(nameEnd, nameEnd) == ':' then
        -- command end is always next bracket in basic commands
        return nextBracket
    end

    -- attribute command → scan to ignore brackets within quotes
    local inDoubleQuote = false
    local inSingleQuote = false
    local i = nameEnd + 1
    while i <= #text do
        local c = text:sub(i, i)

        if c == '\\' then -- ignore escaped quotes
            local nextC = text:sub(i + 1, i + 1)
            if (inDoubleQuote and nextC == '"') or (inSingleQuote and nextC == '\'') then
                i = i + 1
            end
        elseif not inSingleQuote and c == '"' then
            inDoubleQuote = not inDoubleQuote
        elseif not inDoubleQuote and c == '\'' then
            inSingleQuote = not inSingleQuote
        elseif not inDoubleQuote and not inSingleQuote and c == '>' then
            return i
        end

        i = i + 1
    end
end

---Determines the name of a command.
---Returns `nil` if unable to find a name or the command is invalid.
---@param text string
---@param startPos integer
---@param endPos integer?
---@return string? name The command name.
---@return integer? afterName The position of the next character after the name.
function RichTextPanel.findCommandName(text, startPos, endPos)
    endPos = endPos or text:find('>', startPos)
    if not endPos then
        return
    end

    local nextSpace = text:find(' ', startPos)
    local nextColon = text:find(':', startPos)

    local nameEnd = nextSpace or nextColon or endPos
    if nextSpace and nextColon then
        nameEnd = min(nextSpace, nextColon)
    end

    nameEnd = nameEnd < endPos and nameEnd or endPos
    local name = text:sub(startPos, nameEnd - 1)

    -- not an attribute command → disallow space within angle brackets
    if not RichTextPanel.AttributeCommands[name] and nextSpace and nextSpace < endPos then
        return
    end

    return name, nameEnd
end


---Called when a rich text button is clicked.
---@param _button Button
---@param action string?
---@param args table?
function RichTextPanel:onButtonClick(_button, action, args)
    local onAction = self.callbacks.onAction
    if not onAction or not action then
        return
    end

    core.callback.invoke(onAction, action, 'click', unpack(args or {}))
end

---Called when the left mouse button is pressed while over the element.
function RichTextPanel:onMouseDown()
    self.mouseLeftWasDown = self.currentHover ~= nil
end

---Called when the mouse moves while over the element.
---Checks whether the mouse is within a hover area.
function RichTextPanel:onMouseMove()
    local oldHover = self.currentHover
    self.currentHover = nil
    if #self.computedHovers == 0 then
        return
    end

    local found = false
    local x = self:getMouseX()
    local y = self:getMouseY()

    for i = 1, #self.computedHovers do
        local hover = self.computedHovers[i]

        for j = 1, #hover.bounds do
            local bounds = hover.bounds[j]

            if x >= bounds.x1 and x <= bounds.x2 and y >= bounds.y1 and y <= bounds.y2 then
                found = true
                break
            end
        end

        if found then
            self.currentHover = hover
            break
        end
    end

    local hover = self.currentHover
    local onAction = self.callbacks.onAction
    if not onAction or hover == oldHover then
        return
    end

    local onLeave = oldHover and oldHover.onLeave
    if oldHover and onLeave then
        core.callback.invoke(onAction, onLeave, 'hoverLeave', unpack(oldHover.onLeaveArgs or {}))
    end

    local onEnter = hover and hover.onEnter
    if hover and onEnter then
        core.callback.invoke(onAction, onEnter, 'hoverEnter', unpack(hover.onEnterArgs or {}))
    end
end

---Called when the mouse moves while outside the element.
function RichTextPanel:onMouseMoveOutside()
    local oldHover = self.currentHover
    self.currentHover = nil

    local onAction = self.callbacks.onAction
    if not onAction or not oldHover or not oldHover.onLeave then
        return
    end

    core.callback.invoke(onAction, oldHover.onLeave, 'hoverLeave', unpack(oldHover.onLeaveArgs or {}))
end

---Called when the left mouse button is released over the element.
---Triggers a hover action.
function RichTextPanel:onMouseUp()
    if not self.mouseLeftWasDown then
        return
    end

    self.mouseLeftWasDown = false
    local hover = self.currentHover
    if not hover then
        return
    end

    if hover.url then
        core.openUrl(hover.url, true)
    end

    local name = hover.onClick
    local onAction = self.callbacks.onAction
    if name and onAction then
        core.callback.invoke(onAction, name, 'click', unpack(hover.onClickArgs or {}))
    end
end

---Called when the panel resizes.
function RichTextPanel:onResize()
    self.textDirty = true
    Panel.onResize(self)
    self:updateScrollbars()

    if self.vscroll then
        self.vscroll:setHeight(self.height)
    end
end

---Called when the right mouse button is pressed while over the element.
function RichTextPanel:onRightMouseDown()
    self.mouseRightWasDown = self.currentHover ~= nil
end

---Called when the right mouse button is released over the element.
---Triggers a hover action.
function RichTextPanel:onRightMouseUp()
    if not self.mouseRightWasDown then
        return
    end

    self.mouseRightWasDown = false
    local hover = self.currentHover
    local onAction = self.callbacks.onAction
    if not hover or not onAction then
        return
    end

    local name = hover.onRightClick
    if name then
        core.callback.invoke(onAction, name, 'rightClick', unpack(hover.onRightClickArgs or {}))
    end
end

---Processes the text in the rich text panel.
function RichTextPanel:paginate()
    self:resetState()

    local text = (self:replaceKeyNames(self.text) .. ' '):gsub('\n', ' <LINE> ')
    if self.maxLines > 0 then
        local textLines = text:split('<LINE>')
        local start = max(1, #textLines - self.maxLines + 1)
        local lines = { unpack(textLines, start) }

        local parts = { ' ' }
        for i = 1, #lines do
            parts[#parts + 1] = lines[i]
            parts[#parts + 1] = ' <LINE> '
        end

        text = concat(parts)
    end

    local x = 0.0
    local y = 0.0
    local ptr = 1
    local curLine = 1
    local lineImageHeight = 0.0
    local maxLineWidth = self.maxLineWidth or (self.width - self.marginRight - self.marginLeft)

    while ptr <= #text do
        local specialPos = text:find('[< ]', ptr)
        if not specialPos then
            break
        end

        local commandEndPos ---@type integer?
        if text:sub(specialPos, specialPos) == '<' then
            commandEndPos = RichTextPanel.findCommandEnd(text, specialPos + 1)

            -- no command end → treat as text and find next space
            if not commandEndPos then
                specialPos = text:find(' ', ptr)

                if not specialPos then
                    break
                end
            end
        end

        if commandEndPos then
            -- handle text before command
            local current = text:sub(ptr, specialPos - 1):trim()
            if current ~= '' then
                x, y, lineImageHeight, curLine = self:_addText(
                    current,
                    x,
                    y,
                    lineImageHeight,
                    curLine,
                    maxLineWidth
                )
            end

            -- handle command
            if not self.lines[curLine] then
                self.lines[curLine] = ''
                self.lineX[curLine] = x
                self.lineY[curLine] = y
            end

            curLine = curLine + 1

            local lineHeight = max(10, lineImageHeight, textManager:getFontFromEnum(self.font):getLineHeight())
            local command = text:sub(specialPos + 1, commandEndPos - 1)

            self.currentLine = curLine
            local oldY = y
            x, y, lineImageHeight = self:processCommand(command, x, y, lineImageHeight, lineHeight)

            if y ~= oldY then
                self.lastChar = ''
            end

            curLine = self.currentLine
            ptr = commandEndPos + 1
        else
            -- add text up to and including the special character
            local current = text:sub(ptr, specialPos):trim()
            x, y, lineImageHeight, curLine = self:_addText(current, x, y, lineImageHeight, curLine, maxLineWidth)

            ptr = specialPos + 1
        end
    end

    local lineHeight = textManager:getFontFromEnum(self.font):getLineHeight()
    text = text:sub(ptr):trim()
    if text ~= '' then
        self.lines[curLine] = core.replaceEntities(text)
        if x == 0 and self.lines[curLine] ~= '' then
            x = self.indent
        end

        self.lineX[curLine] = x
        self.lineY[curLine] = y
        y = y + lineHeight
    elseif self.lines[curLine] and self.lines[curLine] ~= '' then
        y = y + max(lineHeight, lineImageHeight)
    end

    local referencedItemSet = {}
    if #self.hovers > 0 then
        self:_computeHoverBounds(referencedItemSet)
    end

    if self.autoRemoveItems then
        local now = getTimestampMs()
        for id, cacheItem in pairs(self.items) do
            -- only auto-remove items that have existed for at least 5 seconds
            if not referencedItemSet[id] and not cacheItem.noAutoRemove and (now - cacheItem.created) > 5000 then
                if self.log then
                    self.log.debug('Removing unused item %d from panel', id)
                end

                self.items[id] = nil
            end
        end
    end

    local height = self.marginTop + y + self.marginBottom
    if self.autosetheight then
        self:setHeight(height)
    end

    self:setScrollHeight(height)
end

---Processes a rich text command.
---@param command string
---@param x number
---@param y number
---@param lineImageHeight number
---@param lineHeight number
---@return number
---@return number
---@return number
function RichTextPanel:processCommand(command, x, y, lineImageHeight, lineHeight)
    local name, args = self:_parseCommand(command)
    if not name or not self.Command[name] then
        return x, y, lineImageHeight
    end

    ---@type Args.RichTextCommand
    local commandArgs = {
        x = x,
        y = y,
        lineImageHeight = lineImageHeight,
        lineHeight = lineHeight,
        maxLineWidth = self.maxLineWidth or (self.width - self.marginRight - self.marginLeft),
        options = args or {},
    }

    local rX, rY, rH = self.Command[name](self, commandArgs)
    if rX and rY and rH then
        return rX, rY, rH
    end

    return x, y, lineImageHeight
end

---Registers an item that can be used in `HOVER` commands.
---@param item InventoryItem The item to register.
---@param noAutoRemove boolean? Flag for whether auto-removal should be disallowed for the item. Defaults to `false`.
function RichTextPanel:registerItem(item, noAutoRemove)
    local id = item:getID()
    self.items[id] = {
        item = item,
        created = getTimestampMs(),
        noAutoRemove = noAutoRemove or false,
    }
end

---Removes a cached item from the panel.
---@param item InventoryItem The item to remove.
function RichTextPanel:removeItem(item)
    self.items[item:getID()] = nil
end

---Removes a cached item from the panel.
---@param id integer
function RichTextPanel:removeItemById(id)
    self.items[id] = nil
end

---Renders the rich text content.
function RichTextPanel:render()
    self:setFont(self.defaultFont)
    self.r = self.defaultTextColor.r
    self.g = self.defaultTextColor.g
    self.b = self.defaultTextColor.b
    local a = self.contentTransparency

    if not self.lines then
        return
    end

    if self.keybinds and not self.textDirty then
        for binding, text in pairs(self.keybinds) do
            if getKeyName(gameCore:getKey(binding)) ~= text then
                self.textDirty = true
                break
            end
        end
    end

    if self.textDirty then
        self:paginate()
    end

    for i = 1, #self.images do
        local texture = self.images[i]
        self:drawTextureScaled(
            texture,
            self.imageX[i] + self.marginLeft,
            self.imageY[i] + self.marginTop,
            self.imageW[i],
            self.imageH[i],
            a, 1, 1, 1
        )
    end

    for i = 1, #self.videos do
        local video = self.videos[i]
        video:RenderFrame()
        self:drawTextureScaled(
            video,
            self.videoX[i] + self.marginLeft,
            self.videoY[i] + self.marginTop,
            self.videoW[i],
            self.videoH[i],
            a, 1, 1, 1
        )
    end

    local hover = self.currentHover
    local hoverStart = hover and hover.start or -1
    local hoverStop = hover and hover.stop or -1
    local hoverRgb = hover and hover.rgb

    local orient = 'left'
    local yScroll = self:getYScroll()

    local i = 1
    while i <= #self.lines do
        local line = self.lines[i]

        if self.lineY[i] + self.marginTop + yScroll >= self.height then
            break
        end

        if self.rgb[i] then
            self.r = self.rgb[i].r
            self.g = self.rgb[i].g
            self.b = self.rgb[i].b
        end

        if self.orient[i] then
            orient = self.orient[i]
        end

        if self.fonts[i] then
            self:setFont(self.fonts[i])
        end

        if self.marginTop + yScroll + self.lineY[i] + self.fontHgt > 0 and line ~= '' then
            local r, g, b = self.r, self.g, self.b
            local doUnderline = self:_isInUnderline(i)
            if hoverStart <= i and hoverStop > i then
                doUnderline = hover and hover.underline or doUnderline
                if hoverRgb then
                    r = hoverRgb.r
                    g = hoverRgb.g
                    b = hoverRgb.b
                end
            end

            if orient == 'centre' then
                local lineLength = 0
                local lineY = self.lineY[i]

                local i2 = i
                while (i2 <= #self.lines) and (self.lineY[i2] == lineY) do
                    local font = self.fonts[i2] or self.font
                    lineLength = lineLength + textManager:MeasureStringX(font, self.lines[i2])
                    i2 = i2 + 1
                end

                local lineX = self.marginLeft + (self.width - self.marginLeft - self.marginRight - lineLength) / 2
                while (i <= #self.lines) and (self.lineY[i] == lineY) do
                    if self.rgb[i] then
                        self.r = self.rgb[i].r
                        self.g = self.rgb[i].g
                        self.b = self.rgb[i].b
                    end

                    r = self.r
                    g = self.g
                    b = self.b
                    doUnderline = self:_isInUnderline(i)
                    if hoverStart <= i and hoverStop > i then
                        doUnderline = hover and hover.underline or doUnderline
                        if hoverRgb then
                            r = hoverRgb.r
                            g = hoverRgb.g
                            b = hoverRgb.b
                        end
                    end

                    if self.orient[i] then
                        orient = self.orient[i]
                    end

                    if self.fonts[i] then
                        self:setFont(self.fonts[i])
                    end

                    local lineCentre = self.lines[i]
                    local x = lineX + self.lineX[i]
                    local y = self.lineY[i] + self.marginTop
                    self:drawText(
                        lineCentre,
                        x, y,
                        r, g, b, a,
                        self.font
                    )

                    local w, h
                    if self:_isInStrikethrough(i) then
                        w = textManager:MeasureStringX(self.font, lineCentre)
                        h = textManager:MeasureStringY(self.font, lineCentre)

                        self:drawRect(x, y + h * 0.5, w, 1, a, r, g, b)
                    end

                    if doUnderline then
                        w = w or textManager:MeasureStringX(self.font, lineCentre)
                        h = h or textManager:MeasureStringY(self.font, lineCentre)

                        self:drawRect(x, y + h, w, 1, a, r, g, b)
                    end

                    i = i + 1
                end

                i = i - 1
            elseif orient == 'right' then
                local x = self.lineX[i] + self.marginLeft
                local y = self.lineY[i] + self.marginTop
                self:drawTextRight(
                    line,
                    x, y,
                    r, g, b, a,
                    self.font
                )

                local w, h
                if self:_isInStrikethrough(i) then
                    w = w or textManager:MeasureStringX(self.font, line)
                    h = h or textManager:MeasureStringY(self.font, line)

                    self:drawRect(x - w, y + h * 0.5, w, 1, a, r, g, b)
                end

                if doUnderline then
                    w = w or textManager:MeasureStringX(self.font, line)
                    h = h or textManager:MeasureStringY(self.font, line)

                    self:drawRect(x - w, y + h, w, 1, a, r, g, b)
                end
            else
                local x = self.lineX[i] + self.marginLeft
                local y = self.lineY[i] + self.marginTop
                self:drawText(
                    line,
                    x, y,
                    r, g, b, a,
                    self.font
                )

                local w, h
                if self:_isInStrikethrough(i) then
                    w = w or textManager:MeasureStringX(self.font, line)
                    h = h or textManager:MeasureStringY(self.font, line)

                    self:drawRect(x, y + h * 0.5, w, 1, a, r, g, b)
                end

                if doUnderline then
                    w = w or textManager:MeasureStringX(self.font, line)
                    h = h or textManager:MeasureStringY(self.font, line)

                    self:drawRect(x, y + h, w, 1, a, r, g, b)
                end
            end
        end

        i = i + 1
    end

    if self.drawMargins then
        self:drawRectBorder(0, 0, self.width, self:getScrollHeight(), 0.5, 1, 1, 1)
        self:drawRect(self.marginLeft, 0, 1, self:getScrollHeight(), 1, 1, 1, 1)
        self:drawRect(self.width - self.marginRight, 0, 1, self:getScrollHeight(), 1, 1, 1, 1)
        self:drawRect(0, self.marginTop, self.width, 1, 1, 1, 1, 1)
        self:drawRect(0, self:getScrollHeight() - self.marginBottom, self.width, 1, 1, 1, 1, 1)
    end
end

---Replaces a single keybind command with text for the key name.
---@param text string
---@param offset integer?
---@return string
---@return integer?
function RichTextPanel:replaceKeyName(text, offset)
    local p1, p2 = text:find('<KEY:', offset or 1)
    if not p1 or not p2 then
        return text
    end

    local p3, p4 = text:find('>', p2 + 1)
    if not p3 or not p4 then
        return text
    end

    local binding = text:sub(p2 + 1, p3 - 1):gsub('&nbsp;', ' ')
    local textBefore = text:sub(1, p1 - 1)
    local textAfter = text:sub(p4 + 1)

    local keyName = getKeyName(gameCore:getKey(binding))
    local newText = self.keyColorCommand .. keyName .. ' <POPRGB> '

    self.keybinds[binding] = keyName

    return textBefore .. newText .. textAfter, p1 + #newText
end

---Replaces key commands in text with their key names.
---@param text string
---@return string
function RichTextPanel:replaceKeyNames(text)
    local offset = 1 ---@type integer?
    while true do
        text, offset = self:replaceKeyName(text, offset)
        if not offset then
            break
        end
    end

    return text
end

---Resets the state of the rich text panel.
function RichTextPanel:resetState()
    self.textDirty = false
    self.currentHover = nil
    self:setFont(self.defaultFont)

    self.indent = 0
    self.imageCount = 1
    self.videoCount = 1

    if self.buttons then
        for i = 1, #self.buttons do
            self.buttons[i]:destroy()
        end
    end

    self.fonts = {}
    self.buttons = {}
    self.images = {}
    self.imageX = {}
    self.imageY = {}
    self.imageW = {}
    self.imageH = {}
    self.videos = {}
    self.videoX = {}
    self.videoY = {}
    self.videoW = {}
    self.videoH = {}

    self.lines = {}
    self.lineX = {}
    self.lineY = {}

    self.rgb = {}
    self.rgbStack = {}
    self.rgbCurrent = core.color.copy(self.defaultTextColor)

    self.orient = {}
    self.keybinds = {}
    self.hovers = {}
    self.strikethroughs = {}
    self.underlines = {}
    self.computedHovers = {}
end

---Sets the current content transparency of the panel.
---@param alpha number
function RichTextPanel:setContentTransparency(alpha)
    self.contentTransparency = alpha
end

---Sets the font and associated fields to match.
---@param font UIFont
function RichTextPanel:setFont(font)
    self.font = font
    self.angelCodeFont = textManager:getFontFromEnum(font)
    self.fontHgt = self.angelCodeFont:getLineHeight()
end

---Sets the color to use for keybind display.
---@param color ColorTable<integer>
function RichTextPanel:setKeyColor(color)
    local text = core.color.toRichText(color, true)
    if not text then
        return
    end

    self.keyColorCommand = text
end

---Sets the margins of the panel.
---@param left number
---@param top number
---@param right number
---@param bottom number
function RichTextPanel:setMargins(left, top, right, bottom)
    self.marginLeft = left
    self.marginTop = top
    self.marginRight = right
    self.marginBottom = bottom
end

---Sets the callback used to handle rich text actions.
---@param target any?
---@param callback Callback.RichTextPanel.OnAction?
---@param ...any
function RichTextPanel:setOnAction(target, callback, ...)
    self.callbacks.onAction = core.callback(target, callback, ...)
end

---Sets the callback called before the panel updates tooltips.
---@param target any?
---@param callback UICallback?
---@param ...any
function RichTextPanel:setOnUpdate(target, callback, ...)
    self.callbacks.onUpdate = core.callback(target, callback, ...)
end

---Sets the rich text of the panel.
---@param text string
function RichTextPanel:setText(text)
    text = text or ''
    self.textDirty = self.text ~= text
    self.text = text
end

---Called every 100ms. Updates the tooltip for the current hover.
function RichTextPanel:update()
    core.callback.invoke(self.callbacks.onUpdate)

    local hover = self.currentHover
    local itemId = hover and hover.item
    local text = hover and hover.text
    local item = itemId and self.items[itemId] and self.items[itemId].item
    if not text and not item then
        if self.hoverTooltip then
            self.hoverTooltip:setVisible(false)
            self.hoverTooltip:removeFromUIManager()
        end

        return
    end

    if self.hoverTooltip then
        local isMismatch = (item and self.hoverTooltip.Type ~= 'ISToolTipInv')
            or (text and self.hoverTooltip.Type ~= 'ISToolTip')

        if isMismatch then
            self.hoverTooltip:setVisible(false)
            self.hoverTooltip:removeFromUIManager()
            self.hoverTooltip = nil
        end
    end

    if not self.hoverTooltip then
        if item then
            self.hoverTooltip = UI.tooltipInv {
                owner = self,
                item = item,
                alwaysOnTop = true,
            }
        else
            self.hoverTooltip = UI.tooltip {
                owner = self,
                text = text,
                alwaysOnTop = true,
            }
        end
    elseif not self.hoverTooltip:isReallyVisible() then
        self.hoverTooltip:addToUIManager()
        self.hoverTooltip:setVisible(true)
    end

    if item then
        self.hoverTooltip.item = item
    elseif text then
        self.hoverTooltip.description = text
    end
end


---Adds a button to the rich text panel.
---@param btn Button
---@param lineImageHeight number
---@param lineHeight number
---@param center boolean
---@return number x
---@return number y
---@return number lineImageHeight
---@protected
function RichTextPanel:_addButton(btn, lineImageHeight, lineHeight, center)
    local x, y = btn:getX(), btn:getY()
    local w, h = btn:getWidth(), btn:getHeight()
    local halfHeight = h / 2

    if x + w >= self.width - self.marginLeft + self.marginRight then
        x = 0
        y = y + lineHeight
    end

    if lineImageHeight < h then
        lineImageHeight = h + 8
    end

    if center then
        local mx = (self.width - self.marginLeft - self.marginRight) / 2

        for i = 1, #self.lines do
            if self.lineY[i] == y then
                self.lineY[i] = self.lineY[i] + halfHeight
            end
        end

        btn:setX(mx)
        y = y + halfHeight
        btn:setY(y + (lineHeight - lineImageHeight) * 0.5 + self.marginTop)
    else
        btn:setX(x + self.marginLeft + self.buttonPad)
        btn:setY(y + self.marginTop)
    end

    x = x + w + self.buttonPad * 2

    self:addChild(btn)
    self.buttons[#self.buttons + 1] = btn

    local hover = self.hovers[#self.hovers]
    if hover and hover.stop == -1 then
        btn.tooltip = btn.tooltip or hover.text
    end

    return x, y, lineImageHeight
end

---Adds a hover to the computed list and gets the next hover to use for hover bounds calculation.
---This does not add the hover if no hover bounds were calculated.
---@param hover RichTextPanel.Hover The hover to add.
---@param ptr integer The current index in the `hovers` table.
---@param bounds RichTextPanel.Bounds[] The list of bounds to add to the computed hover.
---@param referencedItems SetTable<integer> A set to add referenced item IDs to.
---@return RichTextPanel.Hover? hover The next hover to use.
---@return integer ptr The new index in the `hovers` table.
---@protected
function RichTextPanel:_addComputedHover(hover, ptr, bounds, referencedItems)
    for i = 1, #hover.imageIndices do
        local idx = hover.imageIndices[i]
        local x = self.imageX[idx]
        local y = self.imageY[idx]
        local w = self.imageW[idx]
        local h = self.imageH[idx]

        if x and y and w and h then
            x = x + self.marginLeft
            y = y + self.marginTop
            bounds[#bounds + 1] = {
                x1 = x,
                y1 = y,
                x2 = x + w,
                y2 = y + h,
            }
        end
    end

    for i = 1, #hover.videoIndices do
        local idx = hover.videoIndices[i]
        local x = self.videoX[idx]
        local y = self.videoY[idx]
        local w = self.videoW[idx]
        local h = self.videoH[idx]

        if x and y and w and h then
            x = x + self.marginLeft
            y = y + self.marginTop
            bounds[#bounds + 1] = {
                x1 = x,
                y1 = y,
                x2 = x + w,
                y2 = y + h,
            }
        end
    end

    if #bounds > 0 then
        local copy = core.copy(hover) --[[@as RichTextPanel.ComputedHover]]
        copy.bounds = bounds
        self.computedHovers[#self.computedHovers + 1] = copy

        if copy.item then
            referencedItems[copy.item] = true
        end
    end

    ptr = ptr + 1
    hover = self.hovers[ptr]

    return hover, ptr
end

---Adds a line of text to the rich text panel.
---@param text string
---@param x number
---@param y number
---@param lineImageHeight number
---@param curLine integer
---@param maxLineWidth number
---@return number x
---@return number y
---@return number lineImageHeight
---@return integer curLine
---@protected
function RichTextPanel:_addText(text, x, y, lineImageHeight, curLine, maxLineWidth)
    local chunkText = self.lines[curLine] or ''
    local chunkX = self.lineX[curLine] or x

    text = core.replaceEntities(text:trim())
    if chunkText == '' then
        chunkText = text
    elseif text ~= '' then
        chunkText = chunkText .. ' ' .. text
    end

    local font = textManager:getFontFromEnum(self.font)
    local pixLen = font:getWidth(chunkText)
    if chunkX + pixLen > maxLineWidth then
        if self.lines[curLine] and self.lines[curLine] ~= '' then
            curLine = curLine + 1
        end

        x = 0
        y = y + max(lineImageHeight, font:getLineHeight())
        self.lastChar = ''
        lineImageHeight = 0
        self.lines[curLine] = text
        if self.lines[curLine] ~= '' then
            x = self.indent
        end

        self.lineX[curLine] = x
        self.lineY[curLine] = y
        x = x + font:getWidth(self.lines[curLine])
    else
        if not self.lines[curLine] then
            self.lineX[curLine] = x
            self.lineY[curLine] = y
        end

        self.lines[curLine] = chunkText:trim()
        if self.lineX[curLine] == 0 and self.lines[curLine] ~= '' then
            self.lineX[curLine] = self.indent
        end

        x = self.lineX[curLine] + pixLen
    end

    local line = self.lines[curLine]
    if line ~= '' then
        self.lastChar = line:sub(#line)
    end

    return x, y, lineImageHeight, curLine
end

---Adds an image to the rich text panel.
---@param texture Texture
---@param x number
---@param y number
---@param w number
---@param h number
---@param lineImageHeight number
---@param lineHeight number
---@param center boolean
---@return number x
---@return number y
---@return number lineImageHeight
---@protected
function RichTextPanel:_addImage(texture, x, y, w, h, lineImageHeight, lineHeight, center)
    self.images[self.imageCount] = texture

    local hover = self.hovers[#self.hovers]
    if hover and hover.stop == -1 then
        hover.imageIndices[#hover.imageIndices + 1] = self.imageCount
    end

    if w == 0 then
        w = texture:getWidth()
        h = texture:getHeight()
    end

    if x + w >= self.width - self.marginLeft + self.marginRight then
        x = 0
        y = y + lineHeight
    end

    if center and lineImageHeight < h / 2 + 8 then
        lineImageHeight = h / 2 + 16
    elseif not center and lineImageHeight < h then
        lineImageHeight = h
    end

    self.imageY[self.imageCount] = y + (lineHeight - lineImageHeight) * 0.5
    self.imageW[self.imageCount] = w
    self.imageH[self.imageCount] = h

    if center then
        local mx = (self.width - self.marginLeft - self.marginRight) / 2
        self.imageX[self.imageCount] = mx - (w / 2)

        for i = 1, #self.lines do
            if self.lineY[i] == y then
                self.lineY[i] = self.lineY[i] + (h / 2)
            end
        end

        y = y + h / 2
    else
        self.imageX[self.imageCount] = x + self.imagePad
    end

    self.imageCount = self.imageCount + 1
    x = x + w + self.imagePad * 2

    return x, y, lineImageHeight
end

---Creates a button from rich text arguments.
---@param args Args.RichTextCommand
---@param commandName string
function RichTextPanel:_createButton(args, commandName)
    local opts = args.options
    local text = opts.text or opts[1]
    local image = opts.image and getTexture(opts.image)
    if not text and not image then
        if self.log then
            self.log.warn('<%s> command requires text or image', commandName)
        end

        return
    end

    local imageOnly = image and not text
    local w = tonumber(opts.width or opts[3])
    if not w and imageOnly then
        w = image:getWidth() + 4
    end

    local h = tonumber(opts.height or opts[4])
    if not h then
        if imageOnly then
            h = image:getHeight() + 4
        else
            h = textManager:getFontHeight(self.font) + 4
        end
    end

    local onClick, onClickArgs = self:_parseAttrCallback(opts.onClick or opts[2])
    return UI.button {
        text = text,
        image = image,
        font = self.font,
        x = args.x,
        y = args.y,
        w = w,
        h = h,
        tooltip = opts.tooltip,
        onClick = self.onButtonClick,
        onClickTarget = self,
        onClickArgs = { onClick, onClickArgs },
        borderColor = self:_parseAttrColor(opts.borderColor),
        textureColor = self:_parseAttrColor(opts.textureColor),
        textColor = self:_parseAttrColor(opts.textColor),
        backgroundColor = self:_parseAttrColor(opts.color),
        backgroundColorMouseOver = self:_parseAttrColor(opts.colorMouseOver),
    }
end

---Pre-computes the mouse position boundaries for hovers.
---@param items SetTable<integer> A set to add referenced item IDs to.
---@protected
function RichTextPanel:_computeHoverBounds(items)
    self.computedHovers = {}

    local hover = self.hovers[1] ---@type RichTextPanel.Hover?
    if not hover or not self.lines then
        return
    end

    local hoverPtr = 1
    local bounds = {} ---@type RichTextPanel.Bounds[]
    self:setFont(self.defaultFont)

    local i = 1
    local orient = 'left'
    while i <= #self.lines do
        if self.orient[i] then
            orient = self.orient[i]
        end

        if self.fonts[i] then
            self:setFont(self.fonts[i])
        end

        if i == hover.stop then
            hover, hoverPtr = self:_addComputedHover(hover, hoverPtr, bounds, items)
            if not hover then
                return
            end

            bounds = {}
        end

        local inHover = hover.start <= i
        if orient == 'centre' then
            local lineLength = 0
            local lineY = self.lineY[i]

            local i2 = i
            while (i2 <= #self.lines) and (self.lineY[i2] == lineY) do
                local font = self.fonts[i2] or self.font
                lineLength = lineLength + textManager:MeasureStringX(font, self.lines[i2])
                i2 = i2 + 1
            end

            local lineX = self.marginLeft + (self.width - self.marginLeft - self.marginRight - lineLength) / 2
            while (i <= #self.lines) and (self.lineY[i] == lineY) do
                if self.orient[i] then
                    orient = self.orient[i]
                end

                if self.fonts[i] then
                    self:setFont(self.fonts[i])
                end

                if i == hover.stop then
                    hover, hoverPtr = self:_addComputedHover(hover, hoverPtr, bounds, items)
                    if not hover then
                        return
                    end

                    bounds = {}
                end

                inHover = hover.start <= i
                if inHover then
                    local text = self.lines[i]
                    local x1 = lineX + self.lineX[i]
                    local y1 = self.lineY[i] + self.marginTop

                    bounds[#bounds + 1] = {
                        x1 = x1,
                        y1 = y1,
                        x2 = x1 + self.angelCodeFont:getWidth(text),
                        y2 = y1 + self.angelCodeFont:getHeight(text),
                    }
                end

                i = i + 1
            end

            i = i - 1
        elseif inHover and orient == 'right' then
            local text = self.lines[i]
            local x2 = self.lineX[i] + self.marginLeft
            local y1 = self.lineY[i] + self.marginTop

            bounds[#bounds + 1] = {
                x1 = x2 - self.angelCodeFont:getWidth(text),
                y1 = y1,
                x2 = x2,
                y2 = y1 + self.angelCodeFont:getHeight(text),
            }
        elseif inHover then
            local text = self.lines[i]
            local x1 = self.lineX[i] + self.marginLeft
            local y1 = self.lineY[i] + self.marginTop

            bounds[#bounds + 1] = {
                x1 = x1,
                y1 = y1,
                x2 = x1 + self.angelCodeFont:getWidth(text),
                y2 = y1 + self.angelCodeFont:getHeight(text),
            }
        end

        i = i + 1
    end

    if hover and #bounds > 0 then
        self:_addComputedHover(hover, hoverPtr, bounds, items)
    end
end

---Returns whether a line is within a range element.
---@param line integer
---@param elements table<integer, RichTextPanel.RangeElement>
---@return boolean
---@protected
function RichTextPanel:_isInRangeElement(line, elements)
    for i = 1, #elements do
        local el = elements[i]
        if line >= el.start and (el.stop == -1 or line < el.stop) then
            return true
        end
    end

    return false
end

---Returns whether a line is within a strikethrough.
---@param line integer
---@return boolean
---@protected
function RichTextPanel:_isInStrikethrough(line)
    return self:_isInRangeElement(line, self.strikethroughs)
end

---Returns whether a line is within an underline.
---@param line integer
---@return boolean
---@protected
function RichTextPanel:_isInUnderline(line)
    return self:_isInRangeElement(line, self.underlines)
end

---Separates command text into a command name and arguments.
---@param command string
---@return string?
---@return table?
---@protected
function RichTextPanel:_parseCommand(command)
    -- no-arg command
    if self.Command[command] then
        return command, { [0] = '' }
    end

    local name, nameEnd = RichTextPanel.findCommandName(command, 1, #command + 1)
    if not name or not nameEnd then
        return
    end

    -- not an attribute command → args are just everything after colon, split by comma
    -- attribute command → read as regular command if a colon follows the name
    if not self.AttributeCommands[name] or command:sub(nameEnd, nameEnd) == ':' then
        local colon = command:find(':') or 0
        local rawArgs = command:sub(colon + 1):trim()
        local args = core.split(rawArgs)
        args[0] = rawArgs

        return name, args
    end

    -- read attributes
    local rawAttributes = command:sub(nameEnd):trim()
    local attributes = attributeParser:parse(rawAttributes)

    local args = { _ = rawAttributes }
    for i = 1, #attributes do
        local attr = attributes[i]
        args[attr.key] = attr.value
    end

    return name, args
end

---Parses a callback attribute into a name and an argument list.
---@param text string
---@return string?
---@return table?
---@protected
function RichTextPanel:_parseAttrCallback(text)
    if not text then
        return
    end

    local paren = text:find('%(')
    if not paren then
        return text
    end

    local rParen = text:find('%)', paren) or (#text + 1)
    local name = text:sub(1, paren - 1)
    local args = core.split(text:sub(paren + 1, rParen - 1))
    return name, args
end

---Parses a color attribute into a color table.
---@param text string
---@return ColorTable<number>?
---@protected
function RichTextPanel:_parseAttrColor(text)
    if not text then
        return
    end

    if text:sub(1, 1) == '#' then
        local colorTable = core.color.fromString(text)
        if not colorTable then
            return
        end

        return core.color.integerToDecimal(colorTable)
    end

    local parts = core.split(text)
    return {
        r = tonumber(parts[1]) or 1,
        g = tonumber(parts[2]) or 1,
        b = tonumber(parts[3]) or 1,
    }
end

---Pushes the current color to the stack and sets the current color to the given color.
---@param color ColorTable<number>
---@protected
function RichTextPanel:_pushColor(color)
    self.rgbStack[#self.rgbStack + 1] = self.rgbCurrent
    self.rgb[self.currentLine] = color
    self.rgbCurrent = self.rgb[self.currentLine]
end


---Creates a new rich text panel.
---@param args Args.RichTextPanel
---@return RichTextPanel
function RichTextPanel:new(args)
    local this = UI.new(self, Panel.new, args)
    this:_setScrollArgs(args, { handleScrolling = true, scrollMultiplier = 18 })

    this.items = {}
    this.log = args.logger
    this.autoRemoveItems = args.autoRemoveItems ~= false
    this.autosetheight = args.autosetheight ~= false
    this.clip = args.clip ~= false
    this.clipPrerender = args.clipPrerender or false
    this.contentTransparency = args.contentTransparency or 1
    this.defaultFont = args.font or UIFont.NewSmall
    this.drawMargins = args.drawMargins or false
    this.useContextSpacing = args.useContextSpacing ~= false

    this.imagePad = args.imagePad or 5
    this.buttonPad = args.buttonPad or 5
    this.marginTop = args.marginTop or 10
    this.marginBottom = args.marginBottom or 10
    this.marginLeft = args.marginLeft or 20
    this.marginRight = args.marginRight or 10
    this.maxLines = args.maxLines or 0

    this.text = args.text or ''
    this.keyColorCommand = ' <PUSHRGB:0,0.635,0.91> '
    this.defaultTextColor = core.color.default(args.textColor, 1, 1, 1)
    this.h1Color = core.color.default(args.h1Color, 1, 1, 1)
    this.h2Color = core.color.default(args.h2Color, 0.8, 0.8, 0.8)
    this.regularTextColor = core.color.default(args.regularTextColor, 0.7, 0.7, 0.7)
    this.defaultLinkColor = core.color.default(args.linkColor, 0.6, 0.75, 1)

    this.r = this.defaultTextColor.r
    this.g = this.defaultTextColor.g
    this.b = this.defaultTextColor.b

    this:setOnAction(args.onActionTarget or args.target, args.onAction, unpack(args.onActionArgs or {}))
    this:setOnUpdate(args.onUpdateTarget or args.target, args.onUpdate, unpack(args.onUpdateArgs or {}))

    this:resetState()
    this.textDirty = true

    return this
end


return RichTextPanel

--#region Type Definitions

---@class Args.RichTextPanel : Args.Panel
---@field autosetheight? boolean If `false`, the panel won't automatically set its height based on the content.
---@field autoRemoveItems boolean? Flag for whether unused cached items will be removed from the panel on paginate. Defaults to `true`.
---@field drawMargins? boolean Whether to draw margins for the panel.
---@field clipPrerender? boolean If `true`, the stencil rect will be applied during prerender. Defaults to `false`.
---@field contentTransparency? number The content transparency value for rich text items.
---@field imagePad? number The left padding to add to images.
---@field buttonPad? number The left padding to add to buttons.
---@field font? UIFont The default font to use before changes from rich text commands.
---@field marginTop? number The top margin of the panel.
---@field marginBottom? number The bottom margin of the panel.
---@field marginLeft? number The left margin of the panel.
---@field marginRight? number The right margin of the panel.
---@field maxLines? integer The maximum number of lines in the rich text content.
---@field text? string The rich text content of the panel.
---@field textColor? ColorTable<number> The default text color of the panel.
---@field linkColor? ColorTable<number> The default color to use for links.
---@field h1Color? ColorTable<number> The text color to use for the H1 style.
---@field h2Color? ColorTable<number> The text color to use for the H2 style.
---@field regularTextColor? ColorTable<number> The text color to use for the regular text style.
---@field useContextSpacing? boolean If `true`, the panel will use context-based spacing. Defaults to `true`.
---@field handleScrolling? boolean If `true`, the panel will scroll its contents when the mouse is scrolled. Defaults to `true`.
---@field scrollMultiplier? number A multiplier to apply to the scroll delta. Defaults to `18`.
---@field logger? Logger Logger to use to log errors.
---@field onAction? Callback.RichTextPanel.OnAction Callback used to handle rich text actions.
---@field onActionArgs? table Arguments for `onAction`.
---@field onActionTarget? any The first argument to pass to the `onAction` callback.
---@field onUpdate? UICallback Callback called before the panel updates tooltips.
---@field onUpdateArgs? table Arguments for `onUpdate`.
---@field onUpdateTarget? any The first argument to pass to the `onUpdate` callback.

---@class InitArgs.RichTextPanel : Args.RichTextPanel, InitArgs.Shared


---@class RichTextPanel.Callbacks
---@field onAction? CallbackInfo Callback used to handle rich text actions.
---@field onUpdate? CallbackInfo Callback called before the panel updates tooltips.

---@class RichTextPanel.RangeElement
---@field start integer The line in the `lines` array at which the element starts.
---@field stop integer The line in the `lines` array after the line at which the element ends.

---@class RichTextPanel.Hover : RichTextPanel.RangeElement
---@field imageIndices integer[] The indexes of images in the `images` array which fall within the hover.
---@field videoIndices integer[] The indexes of videos in the `videos` array which fall within the hover.
---@field text? string The text that should display on hover.
---@field url? string The URL to open when the hover is clicked.
---@field underline? boolean Flag for whether the hover should display an underline when hovered.
---@field onClick? string An action to execute when the hover area is clicked.
---@field onClickArgs? table Arguments for the `onClick` action.
---@field onRightClick? string An action to execute when the hover area is right clicked.
---@field onRightClickArgs? table Arguments for the `onRightClick` action.
---@field onEnter? string An action to execute when the mouse enters the hover area.
---@field onEnterArgs? table Arguments for the `onEnter` action.
---@field onLeave? string An action to execute when the mouse exit the hover area.
---@field onLeaveArgs? table Arguments for the `onLeave` action.
---@field rgb? ColorTable<number> The color to use for the text when hovered.
---@field item? integer An item ID to use for the hover.

---@class RichTextPanel.ComputedHover : RichTextPanel.Hover
---@field bounds RichTextPanel.Bounds[] The computed hover bounds.

---@class RichTextPanel.Bounds
---@field x1 number The X position of the top left corner.
---@field y1 number The Y position of the top left corner.
---@field x2 number The X position of the bottom right corner.
---@field y2 number The Y position of the bottom right corner.

---@class RichTextPanel.CachedItem
---@field item InventoryItem The item object.
---@field created integer The timestamp of the creation of the cache entry.
---@field noAutoRemove boolean Flag for whether auto-removal should be disallowed for the item.


---@alias RichTextActionType
---| 'click'
---| 'rightClick'
---| 'hoverEnter'
---| 'hoverLeave'

---@alias Callback.RichTextPanel.OnAction fun(target?: any, name: string, action: RichTextActionType, ...: string)

--#endregion
