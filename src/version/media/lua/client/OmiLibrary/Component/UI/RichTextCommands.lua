---Commands for the rich text panel.
---@namespace omi
---@diagnostic disable: access-invisible

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/Core/UI'

local max = math.max
local getTextManager = getTextManager
local getTexture = getTexture
local gameCore = getCore()
local textManager = getTextManager()
local uiScale = UI.getScale()


---Container for rich text commands.
---@class RichTextCommands
local RichTextCommands = {}


---Sets the text color to the bad highlight color.
---@param panel RichTextPanel
function RichTextCommands.BHC(panel)
    panel.rgb[panel.currentLine] = core.color.copy(core.color.bad01)
end

---Adds a large line break to the rich text content.
---@param args Args.RichTextCommand
---@return number, number, number
function RichTextCommands.BR(_, args)
    return 0, args.y + args.lineHeight * 2, 0
end

---Adds a button to the rich text content.
---@param panel RichTextPanel
---@param args Args.RichTextCommand
function RichTextCommands.BUTTON(panel, args)
    local btn = panel:_createButton(args, 'BUTTON')
    if btn then
        return panel:_addButton(btn, args.lineImageHeight, args.lineHeight, false)
    end
end

---Adds a centered button to the rich text content.
---@param panel RichTextPanel
---@param args Args.RichTextCommand
function RichTextCommands.BUTTONCENTRE(panel, args)
    local btn = panel:_createButton(args, 'BUTTONCENTRE')
    if btn then
        return panel:_addButton(btn, args.lineImageHeight, args.lineHeight, true)
    end
end

---Centers the text.
---@param panel RichTextPanel
function RichTextCommands.CENTRE(panel)
    panel.orient[panel.currentLine] = 'centre'
end

---Sets the text color to the good highlight color.
---@param panel RichTextPanel
function RichTextCommands.GHC(panel)
    panel.rgb[panel.currentLine] = core.color.copy(core.color.good01)
end

---Ends a hover element.
---@param panel RichTextPanel
function RichTextCommands.ENDHOVER(panel)
    local hover = panel.hovers[#panel.hovers]
    if hover and hover.stop == -1 then
        hover.stop = panel.currentLine
    end
end

---Ends a strikethrough element.
---@param panel RichTextPanel
function RichTextCommands.ENDSTRIKE(panel)
    local strike = panel.strikethroughs[#panel.strikethroughs]
    if strike and strike.stop == -1 then
        strike.stop = panel.currentLine
    end
end

---Ends an underline element.
---@param panel RichTextPanel
function RichTextCommands.ENDUNDERLINE(panel)
    local underline = panel.underlines[#panel.underlines]
    if underline and underline.stop == -1 then
        underline.stop = panel.currentLine
    end
end

---Sets the text color to green.
---@param panel RichTextPanel
function RichTextCommands.GREEN(panel)
    panel.rgb[panel.currentLine] = {
        r = 0,
        g = 1,
        b = 0,
    }

    panel.rgbCurrent = panel.rgb[panel.currentLine]
end

---Sets the text style to H1.
---@param panel RichTextPanel
function RichTextCommands.H1(panel)
    panel.orient[panel.currentLine] = 'centre'
    panel.rgb[panel.currentLine] = {
        r = panel.h1Color.r,
        g = panel.h1Color.g,
        b = panel.h1Color.b,
    }

    panel:setFont(UIFont.Large)
    panel.fonts[panel.currentLine] = panel.font
end

---Sets the text style to H2.
---@param panel RichTextPanel
function RichTextCommands.H2(panel)
    panel.orient[panel.currentLine] = 'left'
    panel.rgb[panel.currentLine] = {
        r = panel.h2Color.r,
        g = panel.h2Color.g,
        b = panel.h2Color.b,
    }

    panel:setFont(UIFont.Medium)
    panel.fonts[panel.currentLine] = panel.font
end

---Adds hover text.
---@param panel RichTextPanel
---@param args Args.RichTextCommand
function RichTextCommands.HOVER(panel, args)
    local opts = args.options

    -- end the last hover if present
    local lastHover = panel.hovers[#panel.hovers]
    if lastHover and lastHover.stop == -1 then
        lastHover.stop = panel.currentLine
    end

    ---@type RichTextPanel.Hover
    local hover = {
        start = panel.currentLine,
        stop = -1,
        imageIndices = {},
        videoIndices = {},
    }

    local text = opts.text or opts[0]
    if text then
        text = text:trim()
        if #text == 0 then
            text = nil
        end
    end

    local url = opts.url and opts.url:trim()
    if url and #url == 0 then
        url = nil
    end

    local underline
    if opts.underline then
        underline = opts.underline ~= 'false'
    end

    local onEnter, onEnterArgs = panel:_parseAttrCallback(opts.onEnter)
    local onLeave, onLeaveArgs = panel:_parseAttrCallback(opts.onLeave)
    local onClick, onClickArgs = panel:_parseAttrCallback(opts.onClick)
    local onRightClick, onRightClickArgs = panel:_parseAttrCallback(opts.onRightClick)

    hover.text = text
    hover.url = url
    hover.underline = underline
    hover.item = opts.item and core.tointeger(opts.item)
    hover.rgb = panel:_parseAttrColor(opts.color)
    hover.onClick = onClick
    hover.onClickArgs = onClickArgs
    hover.onRightClick = onRightClick
    hover.onRightClickArgs = onRightClickArgs
    hover.onEnter = onEnter
    hover.onEnterArgs = onEnterArgs
    hover.onLeave = onLeave
    hover.onLeaveArgs = onLeaveArgs
    panel.hovers[#panel.hovers + 1] = hover
end

---Adds an image to the rich text content.
---@param panel RichTextPanel
---@param args Args.RichTextCommand
---@return number?, number?, number?
function RichTextCommands.IMAGE(panel, args)
    local opts = args.options
    local image = opts[1] or ''
    local w = tonumber(opts[2] or '') or 0
    local h = tonumber(opts[3] or '') or w

    local texture = getTexture(image)
    if not texture then
        if panel.log then
            panel.log.warn('Unknown image used in <IMAGE> command: `%s`', image)
        end

        return
    end

    return panel:_addImage(texture, args.x, args.y, w, h, args.lineImageHeight, args.lineHeight, false)
end

---Adds a centered image to the rich text content.
---@param panel RichTextPanel
---@param args Args.RichTextCommand
---@return number?, number?, number?
function RichTextCommands.IMAGECENTRE(panel, args)
    local options = args.options
    local image = options[1] or ''
    local w = tonumber(options[2] or '') or 0
    local h = tonumber(options[3] or '') or w

    local texture = getTexture(image)
    if not texture then
        if panel.log then
            panel.log.warn('Unknown image used in <IMAGECENTRE> command: `%s`', image)
        end

        return
    end

    return panel:_addImage(texture, args.x, args.y, w, h, args.lineImageHeight, args.lineHeight, true)
end

---Sets the indentation of the text.
---@param panel RichTextPanel
---@param args Args.RichTextCommand
function RichTextCommands.INDENT(panel, args)
    panel.indent = tonumber(args.options[1]) or 0
end

---Adds an image of a joypad control to the rich text content.
---@param panel RichTextPanel
---@param args Args.RichTextCommand
---@return number?, number?, number?
function RichTextCommands.JOYPAD(panel, args)
    local options = args.options
    local image = options[1] or ''
    local w = tonumber(options[2] or '') or 0
    local h = tonumber(options[3] or '') or w

    local texture = getTexture(image)
    if not texture then
        if panel.log then
            panel.log.warn('Unknown control name used in <JOYPAD> command: `%s`', image)
        end

        return
    end

    return panel:_addImage(texture, args.x, args.y, w, h, args.lineImageHeight, args.lineHeight, false)
end

---Left-aligns the text.
---@param panel RichTextPanel
function RichTextCommands.LEFT(panel)
    panel.orient[panel.currentLine] = 'left'
end

---Adds a line break to the rich text content.
---@param args Args.RichTextCommand
---@return number, number, number
function RichTextCommands.LINE(_, args)
    return 0, args.y + args.lineHeight, 0
end

---Adds a link to the rich text content.
---This is a shortcut for a combination of other commands.
---@param panel RichTextPanel
---@param args Args.RichTextCommand
function RichTextCommands.LINK(panel, args)
    local opts = args.options
    local url = opts.url or opts[0]
    if not url then
        if panel.log then
            panel.log.warn('<LINK> command requires a URL')
        end

        return
    end

    local urlNoHttp = url:gsub('^https?://', '')
    local text = opts.text
    if not text then
        text = urlNoHttp:gsub('%?.+$', '')
    end

    if text ~= url and text ~= urlNoHttp then
        opts.alt = opts.alt or url
    end

    local color
    local colorStr = opts.color and opts.color:trim()
    if not colorStr then
        color = panel.defaultLinkColor
    elseif colorStr ~= 'false' then
        color = panel:_parseAttrColor(opts.color)
    end

    -- underline for links unless explicitly false
    local underline = opts.underline == 'false' and 'false' or ''

    -- add initial commands
    local argsCopy = core.copy(args)
    if color then
        argsCopy.options = {
            color.r,
            color.g,
            color.b,
        }

        RichTextCommands.PUSHRGB(panel, argsCopy)
    end

    argsCopy.options = {
        url = url,
        text = opts.alt,
        color = opts.hoverColor,
        underline = underline,
    }

    RichTextCommands.HOVER(panel, argsCopy)

    -- ensure no gaps
    local curLine = panel.currentLine
    local x, y, lineImageHeight = args.x, args.y, args.lineImageHeight
    if not panel.lines[curLine] then
        panel.lines[curLine] = ''
        panel.lineX[curLine] = x
        panel.lineY[curLine] = y
    end

    -- add text
    curLine = curLine + 1
    panel.currentLine = curLine
    panel.lines[curLine] = ''
    panel.lineX[curLine] = x
    panel.lineY[curLine] = y

    x, y, lineImageHeight, curLine = panel:_addText(text, x, y, lineImageHeight, panel.currentLine, args.maxLineWidth)

    -- add terminating commands
    curLine = curLine + 1
    panel.currentLine = curLine
    panel.lines[curLine] = ''
    panel.lineX[curLine] = x
    panel.lineY[curLine] = y
    RichTextCommands.ENDHOVER(panel)
    RichTextCommands.POPRGB(panel)

    return x, y, lineImageHeight
end

---Sets the text color to orange.
---@param panel RichTextPanel
function RichTextCommands.ORANGE(panel)
    panel.rgb[panel.currentLine] = {
        r = 0.9,
        g = 0.3,
        b = 0,
    }

    panel.rgbCurrent = panel.rgb[panel.currentLine]
end

---Sets the text color to the popped color on the stack.
---@param panel RichTextPanel
function RichTextCommands.POPRGB(panel)
    if #panel.rgbStack > 0 then
        panel.rgbCurrent = panel.rgbStack[#panel.rgbStack]
        panel.rgbStack[#panel.rgbStack] = nil
        panel.rgb[panel.currentLine] = panel.rgbCurrent
    end
end

---Sets the text color to the bad highlight color and pushes the current color onto a stack.
---@param panel RichTextPanel
function RichTextCommands.PUSHBHC(panel)
    panel:_pushColor(core.color.copy(core.color.bad01))
end

---Sets the text color to the good highlight color and pushes the current color onto a stack.
---@param panel RichTextPanel
function RichTextCommands.PUSHGHC(panel)
    panel:_pushColor(core.color.copy(core.color.good01))
end

---Sets the text color and pushes the current color onto a stack.
---@param panel RichTextPanel
---@param args Args.RichTextCommand
function RichTextCommands.PUSHRGB(panel, args)
    local options = args.options
    panel:_pushColor({
        r = tonumber(options[1]) or 1,
        g = tonumber(options[2]) or 1,
        b = tonumber(options[3]) or 1,
    })
end

---Sets the text color to red.
---@param panel RichTextPanel
function RichTextCommands.RED(panel)
    panel.rgb[panel.currentLine] = {
        r = 1,
        g = 0,
        b = 0,
    }

    panel.rgbCurrent = panel.rgb[panel.currentLine]
end

---Resets the text color.
---@param panel RichTextPanel
function RichTextCommands.RESETRGB(panel)
    panel.rgb[panel.currentLine] = {
        r = panel.defaultTextColor.r,
        g = panel.defaultTextColor.g,
        b = panel.defaultTextColor.b,
    }

    panel.rgbCurrent = panel.rgb[panel.currentLine]
end

---Sets the text color.
---@param panel RichTextPanel
---@param args Args.RichTextCommand
function RichTextCommands.RGB(panel, args)
    local options = args.options
    panel.rgb[panel.currentLine] = {
        r = tonumber(options[1]) or 1,
        g = tonumber(options[2]) or 1,
        b = tonumber(options[3]) or 1,
    }

    panel.rgbCurrent = panel.rgb[panel.currentLine]
end

---Right-aligns the text.
---@param panel RichTextPanel
function RichTextCommands.RIGHT(panel)
    panel.orient[panel.currentLine] = 'right'
end

---Sets the X position of the text.
---@param args Args.RichTextCommand
---@return number, number, number
function RichTextCommands.SETX(_, args)
    return tonumber(args.options[1]) or 0, args.y, args.lineImageHeight
end

---Sets the size of the text.
---@param panel RichTextPanel
---@param args Args.RichTextCommand
function RichTextCommands.SIZE(panel, args)
    local size = args.options[1]
    if size == 'small' then
        panel:setFont(UIFont.NewSmall)
    elseif size == 'medium' then
        panel:setFont(UIFont.Medium)
    elseif size == 'large' then
        panel:setFont(UIFont.Large)
    else
        return
    end

    panel.fonts[panel.currentLine] = panel.font
end

---Adds a space to the rich text content.
---@param panel RichTextPanel
---@param args Args.RichTextCommand
---@return number?, number?, number?
function RichTextCommands.SPACE(panel, args)
    if args.x <= 0 then
        return
    end

    local x = args.x
    if panel.useContextSpacing then
        local lastChar = panel.lastChar or ''
        local font = textManager:getFontFromEnum(panel.font)
        local fontDelta = panel.font == UIFont.NewSmall and 0 or uiScale

        local delta
        if lastChar ~= '' then
            local lastWidth = font:getWidth(lastChar)
            local combinedWidth = font:getWidth(lastChar .. ' ')
            delta = max(0, combinedWidth - lastWidth)
        else
            delta = font:getWidth(' ')
        end

        x = x + delta + fontDelta
    else
        x = x + textManager:MeasureStringX(panel.font, ' ') + 2
    end

    return x, args.y, args.lineImageHeight
end

---Adds a strikethrough.
---@param panel RichTextPanel
function RichTextCommands.STRIKE(panel)
    local current = panel.strikethroughs[#panel.strikethroughs]
    if current and current.stop == -1 then
        return
    end

    ---@type RichTextPanel.RangeElement
    local strike = {
        start = panel.currentLine,
        stop = -1,
    }

    panel.strikethroughs[#panel.strikethroughs + 1] = strike
end

---Sets the text style to regular text.
---@param panel RichTextPanel
function RichTextCommands.TEXT(panel)
    panel.orient[panel.currentLine] = 'left'
    panel.rgb[panel.currentLine] = {
        r = panel.regularTextColor.r,
        g = panel.regularTextColor.g,
        b = panel.regularTextColor.b,
    }

    panel:setFont(panel.defaultFont)
    panel.fonts[panel.currentLine] = panel.font
end

---Adds an underline.
---@param panel RichTextPanel
function RichTextCommands.UNDERLINE(panel)
    local current = panel.underlines[#panel.underlines]
    if current and current.stop == -1 then
        return
    end

    ---@type RichTextPanel.RangeElement
    local underline = {
        start = panel.currentLine,
        stop = -1,
    }

    panel.underlines[#panel.underlines + 1] = underline
end

---Adds a centered video to the rich text content.
---@param panel RichTextPanel
---@param args Args.RichTextCommand
---@return number, number, number
function RichTextCommands.VIDEOCENTRE(panel, args)
    local x = args.x
    local y = args.y
    local lineHeight = args.lineHeight
    local lineImageHeight = args.lineImageHeight

    local options = args.options
    local name = options[1] or ''
    local w = core.tointeger(options[2] or '') or 0
    local h = core.tointeger(options[3] or '') or w
    local w2 = core.tointeger(options[4] or '') or 384
    local h2 = core.tointeger(options[5] or '') or 216
    local image = 'media/videos/' .. name .. '.png'

    local halfHeight
    local silent = false

    local canDoVideoEffects = gameCore:getOptionDoVideoEffects()

    local video = canDoVideoEffects and getVideo(name, w, h)
    if canDoVideoEffects and not video then
        if panel.log then
            panel.log.warn('Unknown video used in rich text command: `%s`', name)
        end

        -- use fallback image, but don't log another warning if it's not present
        silent = true
    end

    local hover = panel.hovers[#panel.hovers]
    if video then
        panel.videos[panel.videoCount] = video
        if hover and hover.stop == -1 then
            hover.videoIndices[#hover.videoIndices + 1] = panel.videoCount
        end

        w = w2
        h = h2
        if x + w >= panel.width - panel.marginLeft + panel.marginRight then
            x = 0
            y = y + lineHeight
        end

        halfHeight = h * 0.5
        if lineImageHeight < halfHeight + 8 then
            lineImageHeight = halfHeight + 16
        end

        local mx = (panel.width - panel.marginLeft - panel.marginRight) * 0.5
        panel.videoX[panel.videoCount] = mx - w * 0.5
        panel.videoY[panel.videoCount] = y
        panel.videoW[panel.videoCount] = w
        panel.videoH[panel.videoCount] = h
        panel.videoCount = panel.videoCount + 1
    else
        local texture = getTexture(image)
        if not texture then
            if not silent and panel.log then
                panel.log.warn('Video with missing fallback image used in rich text command: `%s`', name)
            end

            return x, y, lineImageHeight
        end

        panel.images[panel.imageCount] = texture
        if hover and hover.stop == -1 then
            hover.imageIndices[#hover.imageIndices + 1] = panel.imageCount
        end

        w = panel.images[panel.imageCount]:getWidth()
        h = panel.images[panel.imageCount]:getHeight()

        if x + w >= panel.width - panel.marginLeft + panel.marginRight then
            x = 0
            y = y + lineHeight
        end

        halfHeight = h * 0.5
        if lineImageHeight < halfHeight + 8 then
            lineImageHeight = halfHeight + 16
        end

        local mx = (panel.width - panel.marginLeft - panel.marginRight) * 0.5
        panel.imageX[panel.imageCount] = mx - w * 0.5
        panel.imageY[panel.imageCount] = y
        panel.imageW[panel.imageCount] = w
        panel.imageH[panel.imageCount] = h
        panel.imageCount = panel.imageCount + 1
    end

    x = x + w + 7

    for i = 1, #panel.lines do
        if panel.lineY[i] == y then
            panel.lineY[i] = panel.lineY[i] + halfHeight
        end
    end

    y = y + halfHeight
    return x, y, lineImageHeight
end


RichTextCommands['/HOVER'] = RichTextCommands.ENDHOVER
RichTextCommands['/STRIKE'] = RichTextCommands.ENDSTRIKE
RichTextCommands['/UNDERLINE'] = RichTextCommands.ENDUNDERLINE

return RichTextCommands

--#region Type Definitions

---@class Args.RichTextCommand
---@field x number The current X position.
---@field y number The current Y position.
---@field lineImageHeight number The maximum height of any image on the current line.
---@field lineHeight number The current line height.
---@field maxLineWidth number The maximum width of a line.
---@field options table Options passed to the command.
---For attribute commands, this is a key-value table with `_` containing the raw string.
---Otherwise, numerical indices are used and index `0` contains the raw string.

--#endregion
