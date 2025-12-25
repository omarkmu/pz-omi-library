---Client API functionality related to the chat.
---@namespace omi

local core = require 'OmiLibrary'

---@class(partial) chat
---@field private _hasOmiChat boolean? Flag for whether the OmiChat mod is active.
local Chat = {}


---Adds a mimic message to the chat.
---@param message MimicMessage The message to add.
---@param tabID integer? The 1-indexed ID of the chat tab to send the message on. Defaults to the current chat tab.
function Chat.addMessage(message, tabID)
    if not ISChat.instance then
        return
    end

    tabID = tabID or ISChat.instance.currentTabID
    ISChat.addLineInChat(message --[[@as ChatMessage]], tabID - 1)
end

---Adds a server message to chat that displays only for the local user.
---@param text string The rich text content of the message.
---@param serverAlert boolean? Whether the message should be treated as a server alert.
---@param tabID integer? The 1-indexed ID of the chat tab to send the message on. Defaults to the current chat tab.
function Chat.addInfoMessage(text, serverAlert, tabID)
    local message = Chat.MimicMessage:new {
        text = text,
        serverAlert = serverAlert,
        chatType = 'server',
        author = 'Server',
        serverAuthor = true,
        showAuthor = false,
        richText = true,
    }

    Chat.addMessage(message, tabID)
end

---Returns the OmiChat client API, if available.
---@diagnostic disable-next-line: type-not-found
---@return omichat.api.client?
function Chat.getOmiChat()
    if Chat.isOmiChatActive() then
        ---@diagnostic disable-next-line: return-type-mismatch
        return require 'OmiChat/Client'
    end
end

---Returns a flag for whether the OmiChat mod is active.
---@return boolean
function Chat.isOmiChatActive()
    if Chat._hasOmiChat ~= nil then
        return Chat._hasOmiChat
    end

    Chat._hasOmiChat = core.isModActive('OmiChat')
    return Chat._hasOmiChat
end


return Chat

--#region Type Definitions

---@alias ChatTypeString
---| 'general'
---| 'whisper'
---| 'say'
---| 'shout'
---| 'faction'
---| 'safehouse'
---| 'radio'
---| 'admin'
---| 'server'

--#endregion
