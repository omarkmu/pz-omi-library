---A request made to the client or server for a topic.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'

local concat = table.concat
local isempty = table.isempty
local format = string.format
local getTimestampMs = getTimestampMs

local REQ_CANCELLED = 'Cancelled %s'
local REQ_SEND = 'Sent %s'
local REQ_SEND_FAIL = 'Cannot send %s: %s'
local REQ_REPLY_FAIL = 'Cannot send reply for %s: %s'


---@class Request : Class
---@field args table Arguments sent with the request.
---@field protected _topic Topic The topic of the request.
---@field protected _dispatcher Dispatcher The dispatcher that handles the request.
---@field protected _errors string[] Errors that occurred on the request.
---@field protected _isCancelled boolean Whether the request has been cancelled.
---@field protected _isIncoming boolean Whether the request is an incoming request.
---@field protected _isReply boolean Whether the request is a reply.
---@field protected _isSent boolean Whether the request has already been sent.
---@field protected _sendAttempts integer The number of times `send` has been called.
---@field protected _player? IsoPlayer The player associated with the request.
---@field protected _exchangeId string Unique identifier for the requests in a reply exchange.
local Request = core.class('Request')


---Checks that the incoming request can be accepted.
---@return boolean canReceive Whether the request can be received.
---@return string? reason The reason the request cannot be received.
function Request:canReceive()
    return true
end

---Checks that the outgoing request can be sent.
---@return boolean canSend Whether the request can be sent.
---@return string? reason The reason the request cannot be sent. If `canSend` is `false` and this is absent, the request was cancelled.
function Request:canSend()
    if self._isIncoming then
        return false, 'Request is incoming'
    elseif self._isSent then
        return false, 'Request has already been sent'
    elseif self._isCancelled then
        return false
    end

    return true
end

---Responds to the request on the same topic with a broadcast to all players.
---@param args table? Arguments to send with the response.
---@return boolean success Whether the broadcast was successfully sent.
---@return string? error The error that occurred.
function Request:broadcast(args)
    return self._topic:broadcast(args, self)
end

---Responds to the request on the given topic with a broadcast to all players.
---@param topic Topic The topic to broadcast.
---@param args table? Arguments to send with the response.
---@return boolean success Whether the broadcast was successfully sent.
---@return string? error The error that occurred.
function Request:broadcastOn(topic, args)
    return topic:broadcast(args, self)
end

---Marks the request as cancelled, preventing it from sending.
function Request:cancel()
    self._isCancelled = true
    self:_log(REQ_CANCELLED, self)
end

---Returns a list of errors that occurred while trying to send a request.
---@return string[]
function Request:getErrors()
    return self._errors
end

---Gets the exchange ID for the request.
---@return string
function Request:getExchangeId()
    return self._exchangeId
end

---Returns the last error that occurred while trying to send a request.
---@return string?
function Request:getLastError()
    return self._errors[#self._errors]
end

---Returns the player associated with the request, or `nil` if there is none.
---@return IsoPlayer?
function Request:getPlayer()
    return self._player
end

---Gets the number of times `send` has been called.
---@return integer
function Request:getSendAttempts()
    return self._sendAttempts
end

---Returns the topic associated with the request.
---@return Topic
function Request:getTopic()
    return self._topic
end

---Returns whether the request has attempted sending already.
---@return boolean
function Request:hasTriedToSend()
    return self._sendAttempts > 0
end

---Returns whether the request was cancelled.
---@return boolean
function Request:isCancelled()
    return self._isCancelled
end

---Returns whether the request is a client request.
---@return boolean
---@return_cast self ClientRequest
function Request:isFromClient()
    return false
end

---Returns whether the request is a server request.
---@return boolean
---@return_cast self ServerRequest
function Request:isFromServer()
    return false
end

---Returns whether the request is an incoming request.
---@return boolean
function Request:isIncoming()
    return self._isIncoming
end

---Returns whether the request is a reply.
---@return boolean
function Request:isReply()
    return self._isReply
end

---Returns whether the request has already been sent.
---@return boolean
function Request:isSent()
    return self._isSent
end

---Responds to the request on the same topic.
---@param args table? Arguments to send with the response.
---@return boolean success Whether the reply was successfully sent.
---@return string? error The error that occurred.
function Request:reply(args)
    return self:replyWith(self._topic, args)
end

---Responds to the request with the given topic.
---@param topic Topic The topic to reply on.
---@param args table? Arguments to send with the response.
---@return boolean success Whether the reply was successfully sent.
---@return string? error The error that occurred.
function Request:replyWith(topic, args)
    args = args or {}

    -- server → client → server
    if self:isFromServer() then
        return topic:toServer(args, self)
    end

    -- client → server → client
    local player = self._player
    if not player then
        local err = 'No target player'

        self._errors[#self._errors + 1] = err
        self:_log(REQ_REPLY_FAIL, self, err)
        return false, err
    end

    return topic:toPlayer(player, args, self)
end

---Sends the request.
---@param args table? Arguments to send with the request. Replaces the original arguments if given.
---@return boolean success Whether the request was successfully sent.
---@return string? error The error that occurred.
function Request:send(args)
    args = args or self.args
    self.args = args
    self._sendAttempts = self._sendAttempts + 1

    local canSend, err = self:canSend()
    if not canSend then
        if err then
            self._errors[#self._errors + 1] = err
            self:_log(REQ_SEND_FAIL, self, err)
        end

        return false, err or 'Request is cancelled'
    end

    args = core.copy(args)
    args['$__EXID'] = self._exchangeId
    if self._isReply then
        args['$__REPLY'] = true
    end

    local module, command = self._topic:getModuleAndName()

    -- server → client
    if self:isFromServer() then
        local player = self._player
        if player then
            sendServerCommand(player, module, command, args)
        else
            sendServerCommand(module, command, args)
        end

        self._isSent = true
        self:_log(REQ_SEND, self)
        return true
    end

    -- client → server
    sendClientCommand(module, command, args)

    self._isSent = true
    self:_log(REQ_SEND, self)
    return true
end


---Logs a message to the dispatcher logger.
---@param message string
---@param ...any
---@protected
function Request:_log(message, ...)
    self._dispatcher:log(message, ...)
end

---Converts the request to a string representation.
---@return string
---@protected
function Request:__tostring()
    local id = self._exchangeId
    local dash = id:find('-')
    if dash then
        id = id:sub(1, dash - 1)
    end

    local result = {
        self:isFromServer() and 'ServerRequest' or 'ClientRequest',
        '<',
        self._topic:getName(),
        ', exchangeId=',
        id,
    }

    if self._player then
        result[#result + 1] = ', player='
        result[#result + 1] = self._player:getUsername()
    end

    if not isempty(self.args) then
        result[#result + 1] = ', '
        result[#result + 1] = self._topic:stringifyArgs(self)
    end

    result[#result + 1] = '>'
    return concat(result)
end


---Creates a new Request.
---@param args Args.Request
---@return Request
---@protected
function Request:new(args)
    local this = core.new(self)

    this.args = core.copy(args.args or {})

    this._errors = {}
    this._topic = args.topic
    this._player = args.player
    this._dispatcher = this._topic:getDispatcher()
    this._sendAttempts = 0
    this._isCancelled = false
    this._isReply = args.isReply or false
    this._isSent = args.isSent or false
    this._isIncoming = args.isIncoming or false

    if args.exchangeId then
        this._exchangeId = args.exchangeId
    else
        this._exchangeId = format('%08x-%x', core.randInt(1, 0xFFFFFFFF), getTimestampMs())
    end

    return this
end


return Request

--#region Type Definitions

---@class Args.Request
---@field topic Topic The topic of the request.
---@field args? table Arguments sent with the request.
---@field isIncoming? boolean If `true`, the request is an incoming request.
---@field isReply? boolean If `true`, the request is a reply.
---@field isSent? boolean If `true`, the request has already been sent.
---@field player? IsoPlayer The player associated with the request.
---@field exchangeId? string The ID for the request exchange.

--#endregion
