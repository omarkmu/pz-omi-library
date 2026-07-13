---Dummy chat message object.
---@namespace omi

local core = require 'OmiLibrary'

---@class(partial) chat
local chat = require 'OmiLibrary/Module/Core/Chat'

local format = string.format
local concat = table.concat
local getText = getText
local getHourMinute = getHourMinute
local ISChat = ISChat
local ID_NOT_SET = -29048394 -- unset ID constant from `ChatBase`
local serverRef ---@type Server?


---@class MimicMessage : Class
---@field protected _text string The text of the message.
---@field protected _scramble boolean Whether the message is marked as scrambled.
---@field protected _overHeadSpeech boolean Whether the message appears overhead.
---@field protected _showInChat boolean Whether the message should be added to the chat.
---@field protected _fromDiscord boolean Whether the message is marked as coming from Discord.
---@field protected _richText boolean Whether the message is rich text. If `true`, rich text escaping will be skipped when getting the message text.
---@field protected _serverAlert boolean Whether the message is a server alert.
---@field protected _radioChannel number The radio channel the message was sent over.
---@field protected _local boolean Whether the message is local-only.
---@field protected _shouldAttractZombies boolean Whether the message should attract zombies.
---@field protected _serverAuthor boolean Whether the message author is the server.
---@field protected _showAuthor boolean Whether the message author should be shown in chat.
---@field protected _datetime LocalDateTime The time that the message was created.
---@field protected _author string The author of the message.
---@field protected _textColor Color The color that the message should use in chat.
---@field protected _customTag string Custom data associated with the message.
---@field protected _customColor boolean Whether a custom color has been set on the message.
---@field protected _chatType ChatTypeString The chat type of the chat the message was sent on.
---@field protected _chatID integer The identifier of the chat.
---@field protected _titleID string The ID of a translation for the chat tag.
---@field protected _recipientName? string The name of the recipient of a whisper message.
local MimicMessage = core.class('MimicMessage')

---Dummy chat message object.
chat.MimicMessage = MimicMessage


local buildMessageText ---@type function?
local doChatIntegration = chat.isOmiChatActive()

local defaultTitleIDs = {
    general = 'UI_chat_general_chat_title_id',
    whisper = 'UI_chat_private_chat_title_id',
    say = 'UI_chat_local_chat_title_id',
    shout = 'UI_chat_local_chat_title_id',
    faction = 'UI_chat_faction_chat_title_id',
    safehouse = 'UI_chat_safehouse_chat_title_id',
    radio = 'UI_chat_radio_chat_title_id',
    admin = 'UI_chat_admin_chat_title_id',
    server = 'UI_chat_server_chat_title_id',
}

---Creates a new LocalDateTime object set to the current time.
---@return LocalDateTime
local function dtNow()
    -- avert your eyes lest you witness the horrors
    -- as far as I can tell, this is the only way to get LocalDateTime.now()
    if serverRef then
        serverRef:setLastOnlineNow()
        return serverRef:getLastOnline()
    end

    serverRef = Server.new()
    return serverRef:getLastOnline()
end


---Clones the message.
---@return MimicMessage
function MimicMessage:clone()
    return MimicMessage:new {
        text = self._text,
        scramble = self._scramble,
        overHeadSpeech = self._overHeadSpeech,
        showInChat = self._showInChat,
        fromDiscord = self._fromDiscord,
        richText = self._richText,
        serverAlert = self._serverAlert,
        radioChannel = self._radioChannel,
        isLocal = self._local,
        shouldAttractZombies = self._shouldAttractZombies,
        serverAuthor = self._serverAuthor,
        showAuthor = self._showAuthor,
        datetime = self._datetime,
        author = self._author,
        textColor = Color.new(self._textColor),
        customTag = self._customTag,
        customColor = self._customColor,
        chatType = self._chatType,
        chatID = self._chatID,
        titleID = self._titleID,
        recipientName = self._recipientName,
    }
end

---Returns the author of the message.
---@return string
function MimicMessage:getAuthor()
    return self._author
end

---Not implemented.
---Included for completeness of the `ChatMessage` interface.
---@deprecated Not implemented.
function MimicMessage:getChat()
    error('not implemented')
end

---Returns the chat ID of the message.
---@return integer
function MimicMessage:getChatID()
    return self._chatID
end

---Returns the chat type of the message.
---@return ChatTypeString
function MimicMessage:getChatType()
    return self._chatType
end

---Returns the custom tag of the message.
---@return string
function MimicMessage:getCustomTag()
    return self._customTag
end

---Returns the time at which the message was sent.
---@return LocalDateTime
function MimicMessage:getDatetime()
    return self._datetime
end

---Returns a string representing the datetime of the message.
---@return string
function MimicMessage:getDatetimeStr()
    -- the vanilla implementation returns the time when *retrieving* this,
    -- which may be inaccurate. this returns a proper timestamp.
    -- does not seem worth matching the bug

    local str = tostring(self._datetime)
    return str:match('%d+:%d+') or ''
end

---Returns the message prefix.
---@return string
function MimicMessage:getPrefix()
    local instance = ISChat.instance
    if not instance then
        return ''
    end

    local isServer = self._chatType == 'server'
    local color = self._textColor
    local result = {
        core.color.toRichText({
            r = color:getRed(),
            g = color:getGreen(),
            b = color:getBlue(),
        }),
        '<SIZE:',
        instance.chatFont or 'medium',
        '> ',
    }

    if instance.showTimestamp and not isServer then
        result[#result + 1] = '['

        -- inaccurate time like vanilla for consistency
        result[#result + 1] = getHourMinute()

        result[#result + 1] = ']'
    end

    local addColon = not isServer
    local titleID = self:getTitleID()

    if instance.showTitle then
        addColon = true
        result[#result + 1] = '['
        result[#result + 1] = getText(titleID)
        result[#result + 1] = ']'
    end

    if not self:isServerAuthor() and self:isShowAuthor() then
        addColon = true
        local recipName = self:getRecipientName()
        result[#result + 1] = '['
        result[#result + 1] = recipName and 'to ' or ''
        result[#result + 1] = recipName or self:getAuthor()
        result[#result + 1] = ']'
    end

    if addColon then
        result[#result + 1] = ': '
    end

    return concat(result)
end

---Returns the radio channel on which the message was sent.
---@return number
function MimicMessage:getRadioChannel()
    return self._radioChannel
end

---Returns the username of the private message recipient.
---@return string?
function MimicMessage:getRecipientName()
    return self._recipientName
end

---Returns the message text.
---@return string
function MimicMessage:getText()
    return self._text
end

---Returns the message text color.
---@return Color
function MimicMessage:getTextColor()
    return self._textColor
end

---Returns the formatted message text.
---@return string
function MimicMessage:getTextWithPrefix()
    if doChatIntegration and not buildMessageText then
        local OmiChat = chat.getOmiChat() --[[@as any]]
        if OmiChat then
            buildMessageText = OmiChat.messages.getTextWithPrefix
        else
            doChatIntegration = false
        end
    end

    if buildMessageText then
        return buildMessageText(self)
    end

    return self:getTextWithPrefixBase()
end

---Base implementation of `getTextWithPrefix`.
---This returns the equivalent of what `getTextWithPrefix` returns for `ChatMessage`.
---@return string
function MimicMessage:getTextWithPrefixBase()
    return self:getPrefix() .. ' ' .. self:getTextWithReplacedParentheses()
end

---Returns the message text escaped for rich text.
---@return string
function MimicMessage:getTextWithReplacedParentheses()
    if self:isRichText() then
        return self._text
    end

    return core.escapeRichText(self._text)
end

---Returns the title ID of the message.
---@return string
function MimicMessage:getTitleID()
    return self._titleID
end

---Returns whether the message has a custom color.
---@return boolean
function MimicMessage:isCustomColor()
    return self._customColor
end

---Returns whether the message is from Discord.
---@return boolean
function MimicMessage:isFromDiscord()
    return self._fromDiscord
end

---Returns whether the message is local.
---@return boolean
function MimicMessage:isLocal()
    return self._local
end

---Returns whether the message should display overhead.
---@return boolean
function MimicMessage:isOverHeadSpeech()
    return self._overHeadSpeech
end

---Returns `true` if the message content should be treated as rich text.
---@return boolean
function MimicMessage:isRichText()
    return self._richText
end

---Returns whether the message content is scrambled.
---@return boolean
function MimicMessage:isScramble()
    return self._scramble
end

---Returns whether the message is a server alert.
---@return boolean
function MimicMessage:isServerAlert()
    return self._serverAlert
end

---Returns whether the message was authored by the server.
---@return boolean
function MimicMessage:isServerAuthor()
    return self._serverAuthor
end

---Returns whether the message should attract zombies.
---@return boolean
function MimicMessage:isShouldAttractZombies()
    return self._shouldAttractZombies
end

---Returns whether the message should show its author.
---@return boolean
function MimicMessage:isShowAuthor()
    return self._showAuthor
end

---Returns whether the message should show in chat.
---@return boolean
function MimicMessage:isShowInChat()
    return self._showInChat
end

---Sets the message as being from Discord.
function MimicMessage:makeFromDiscord()
    self:setFromDiscord(true)
end

---Sets the message author.
---@param author string
function MimicMessage:setAuthor(author)
    self._author = author
end

---Sets the custom tag of the message.
---@param customTag string
function MimicMessage:setCustomTag(customTag)
    self._customTag = customTag
end

---Sets the datetime of the message.
---@param datetime LocalDateTime
function MimicMessage:setDatetime(datetime)
    self._datetime = datetime
end

---Sets the ID of the associated chat for the message.
---@param chatID integer
function MimicMessage:setChatID(chatID)
    self._chatID = chatID
end

---Sets the chat type of the message.
---@param chatType ChatTypeString
function MimicMessage:setChatType(chatType)
    self._chatType = chatType
end

---Sets whether the message is from Discord.
---@param fromDiscord boolean
function MimicMessage:setFromDiscord(fromDiscord)
    self._fromDiscord = fromDiscord
end

---Sets whether the message content should be treated as rich text.
---@param richText boolean
function MimicMessage:setIsRichText(richText)
    self._richText = richText
end

---Sets whether the message is local.
---@param isLocal boolean
function MimicMessage:setLocal(isLocal)
    self._local = isLocal
end

---Sets whether the message should display overhead.
---@param overHeadSpeech boolean
function MimicMessage:setOverHeadSpeech(overHeadSpeech)
    self._overHeadSpeech = overHeadSpeech
end

---Sets the radio channel of the message.
---@param radioChannel number
function MimicMessage:setRadioChannel(radioChannel)
    self._radioChannel = radioChannel
end

---Sets the username of the private message recipient.
---@param recipientName string?
function MimicMessage:setRecipientName(recipientName)
    self._recipientName = recipientName
end

---Sets the text of the message and marks it as scrambled.
---@param text string
function MimicMessage:setScrambledText(text)
    self._scramble = true
    self._text = text
end

---Sets whether this message is a server alert.
---@param serverAlert boolean
function MimicMessage:setServerAlert(serverAlert)
    self._serverAlert = serverAlert
end

---Sets whether this message was authored by the server.
---@param serverAuthor boolean
function MimicMessage:setServerAuthor(serverAuthor)
    self._serverAuthor = serverAuthor
end

---Sets whether this message should attract zombies.
---@param shouldAttractZombies boolean
function MimicMessage:setShouldAttractZombies(shouldAttractZombies)
    self._shouldAttractZombies = shouldAttractZombies
end

---Sets whether this message should show in chat.
---@param showInChat boolean
function MimicMessage:setShowInChat(showInChat)
    self._showInChat = showInChat
end

---Sets the text of this message.
---@param text string
function MimicMessage:setText(text)
    self._text = text
end

---Sets the text color of this message.
---@param textColor Color
function MimicMessage:setTextColor(textColor)
    self._customColor = true
    self._textColor = textColor
end

---Sets the title ID of the message.
---@param titleID string
function MimicMessage:setTitleID(titleID)
    self._titleID = titleID
end


---Converts the message to a debug string.
---@return string
---@protected
function MimicMessage:__tostring()
    return format('MimicMessage{author=\'%s\', text=\'%s\'}', tostring(self._author), tostring(self._text))
end


---Creates a new mimic message.
---@param args Args.MimicMessage?
---@return MimicMessage
function MimicMessage:new(args)
    local this = core.new(self)

    args = args or {} --[[@as Args.MimicMessage]]

    this._text = args.text or ''
    this._chatType = args.chatType or 'say'
    this._author = args.author or ''
    this._customTag = args.customTag or ''
    this._titleID = args.titleID or defaultTitleIDs[this._chatType] or ''
    this._scramble = args.scramble or false
    this._overHeadSpeech = args.overHeadSpeech ~= false
    this._showInChat = args.showInChat ~= false
    this._fromDiscord = args.fromDiscord or false
    this._richText = args.richText or false
    this._serverAlert = args.serverAlert or false
    this._radioChannel = args.radioChannel or -1
    this._chatID = args.chatID or ID_NOT_SET
    this._local = args.isLocal or false
    this._shouldAttractZombies = args.shouldAttractZombies or false
    this._serverAuthor = core.default(args.serverAuthor, this._chatType == 'server')
    this._showAuthor = core.default(args.showAuthor, this._chatType ~= 'server')
    this._datetime = args.datetime or dtNow()
    this._textColor = args.textColor or Color.new(255, 255, 255)
    this._customColor = args.customColor or false

    return this
end


return MimicMessage

--#region Type Definitions

---@class Args.MimicMessage
---@field text string The text of the message.
---@field scramble? boolean Whether the message is marked as scrambled.
---@field overHeadSpeech? boolean Whether the message appears overhead. Defaults to `true`.
---@field showInChat? boolean Whether the message should be added to the chat. Defaults to `true`.
---@field fromDiscord? boolean Whether the message is marked as coming from Discord.
---@field richText? boolean Whether the message is rich text. If `true`, rich text escaping will be skipped when getting the message text.
---@field serverAlert? boolean Whether the message is a server alert.
---@field radioChannel? number The radio channel the message was sent over.
---@field isLocal? boolean Whether the message is local-only.
---@field shouldAttractZombies? boolean Whether the message should attract zombies.
---@field serverAuthor? boolean Whether the message author is the server.
---@field showAuthor? boolean Whether the message author should be shown in chat.
---@field datetime? LocalDateTime The time that the message was created.
---@field author? string The author of the message.
---@field textColor? Color The color that the message should use in chat.
---@field customTag? string Custom data associated with the message.
---@field customColor? boolean Whether a custom color has been set on the message.
---@field chatType? ChatTypeString The chat type of the chat the message was sent on.
---@field chatID? integer The identifier of the chat.
---@field titleID? string The ID of a translation for the chat tag.
---@field recipientName? string The name of the recipient of a whisper message.

--#endregion
