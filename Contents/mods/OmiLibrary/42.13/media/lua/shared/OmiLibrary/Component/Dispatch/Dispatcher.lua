---Handles sending, receiving, and managing commands.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local Topic = require 'OmiLibrary/Component/Dispatch/Topic'
local Trigger = require 'OmiLibrary/Component/Dispatch/Trigger'
local ClientRequest = require 'OmiLibrary/Component/Dispatch/ClientRequest'
local ServerRequest = require 'OmiLibrary/Component/Dispatch/ServerRequest'

local IS_CLIENT = isClient()
local IS_SERVER = isServer()

local REQ_RECEIVE = 'Received %s'
local REQ_RECEIVE_FAIL = 'Cannot receive %s: %s'
local TOPIC_ADD = '%s added to %s'
local TOPIC_UNKNOWN = 'Ignoring request with unknown topic %q'
local TRIGGER_ADD = '%s trigger added for %s'
local TRIGGER_ACTIVATE = '%s trigger activated for %s'
local TRIGGER_UNKNOWN = 'Ignoring unknown trigger %s for %s'


---@class Dispatcher : Class
---@field protected _module string The module identifier used for commands.
---@field protected _topics table<string, Topic> Map of commands to topics.
---@field protected _clientListener? function Listener function for receiving server commands.
---@field protected _serverListener? function Listener function for receiving client commands.
---@field protected _eventListeners table<string, function?> Map of listener names to listeners.
---@field protected _triggers table<Trigger.Type, table<Topic, table>> Associates triggers to tables containing per-topic trigger state.
---@field protected _log? Logger The logger to use.
local Dispatcher = core.class('Dispatcher')
Dispatcher.trigger = Trigger


---Adds a trigger to a topic.
---@param topic Topic
---@param trigger Trigger
function Dispatcher:addTrigger(topic, trigger)
    if topic:getDispatcher() ~= self then
        return
    end

    if trigger.type == Trigger.Type.Interval then
        self:_triggerOnInterval(topic, trigger.options)
    elseif trigger.type == Trigger.Type.PlayerDeath then
        self:_triggerOnPlayerDeath(topic, trigger.options)
    elseif trigger.type == Trigger.Type.PlayerJoined then
        self:_triggerOnPlayerJoined(topic)
    elseif trigger.type == Trigger.Type.EveryDay then
        self:_triggerOnEvent(topic, trigger.type, 'EveryDays')
    elseif trigger.type == Trigger.Type.EveryHour then
        self:_triggerOnEvent(topic, trigger.type, 'EveryHours')
    elseif trigger.type == Trigger.Type.EveryTenMinutes then
        self:_triggerOnEvent(topic, trigger.type, 'EveryTenMinutes')
    elseif trigger.type == Trigger.Type.EveryMinute then
        self:_triggerOnEvent(topic, trigger.type, 'EveryOneMinute')
    else
        self:log(TRIGGER_UNKNOWN, trigger.type, topic)
        return
    end

    self:log(TRIGGER_ADD, trigger.type, topic)
end

---Broadcasts a signal to all players. Can only be used on the server.
---@param topic Topic The topic of the request.
---@param args table? Arguments to send with the request.
---@param source Request? The source of the request, if this is a reply.
---@return boolean success
---@return string? error
function Dispatcher:broadcast(topic, args, source)
    if IS_CLIENT then
        error('Dispatcher.broadcast cannot be used on the client')
    end

    local req = ServerRequest:new {
        topic = topic,
        args = args,
        isReply = source ~= nil,
        exchangeId = source and source:getExchangeId(),
    }

    local attempts = req:getSendAttempts()
    topic:onServerSend(req)
    return self:_trySend(req, attempts)
end

---Connects the dispatcher to listen for commands.
---This is called by the constructor.
function Dispatcher:connect()
    -- using reversed checks so dispatch works in singleplayer
    -- client → server
    if not IS_CLIENT then
        if self._serverListener then
            Events.OnClientCommand.Remove(self._serverListener)
        end

        self._serverListener = function(module, command, player, args)
            self:_onReceive(false, module, command, args, player)
        end

        Events.OnClientCommand.Add(self._serverListener)
    end

    -- server → client
    if not IS_SERVER then
        if self._clientListener then
            Events.OnServerCommand.Remove(self._clientListener)
        end

        self._clientListener = core.bind(self._onReceive, self, true)
        Events.OnServerCommand.Add(self._clientListener)
    end
end

---Disconnects the dispatcher from command listeners.
function Dispatcher:disconnect()
    if self._serverListener then
        Events.OnClientCommand.Remove(self._serverListener)
        self._serverListener = nil
    end

    if self._clientListener then
        Events.OnServerCommand.Remove(self._clientListener)
        self._clientListener = nil
    end
end

---Returns the module name to use for the dispatcher.
---@return string
function Dispatcher:getModule()
    return self._module
end

---Returns the player to use for outgoing requests.
---@return IsoPlayer?
function Dispatcher:getRequestPlayer()
    return getSpecificPlayer(0)
end

---Returns an existing topic on the dispatcher.
---@param name string
---@return Topic?
function Dispatcher:getTopic(name)
    return self._topics[name]
end

---Logs a debug message to the logger, if present.
---@param message string The log message.
---@param ...any Arguments to pass to the logger.
function Dispatcher:log(message, ...)
    if not self._log then
        return
    end

    self._log.debug(message, ...)
end

---Sends a request to the server. Can only be used on the server.
---@param topic Topic The topic of request.
---@param player IsoPlayer The player to send the request to.
---@param args table? Arguments to send with the request.
---@param source Request? The source of the request, if this is a reply.
---@return boolean success
---@return string? error
function Dispatcher:toPlayer(topic, player, args, source)
    if IS_CLIENT then
        error('Dispatcher.toPlayer cannot be used on the client')
    end

    local req = ServerRequest:new {
        topic = topic,
        player = player,
        args = args,
        isReply = source ~= nil,
        exchangeId = source and source:getExchangeId(),
    }

    local attempts = req:getSendAttempts()
    topic:onServerSend(req)
    return self:_trySend(req, attempts)
end

---Sends a request to the server. Can only be used on the client.
---@param topic Topic The topic of the request.
---@param args table? Arguments to send with the request.
---@param source Request? The source of the request, if this is a reply.
---@return boolean success
---@return string? error
function Dispatcher:toServer(topic, args, source)
    if IS_SERVER then
        error('Dispatcher.toServer cannot be used on the server')
    end

    local player = self:getRequestPlayer()
    if not player then
        return false, 'Failed to get a player for sending the request'
    end

    local req = ClientRequest:new {
        topic = topic,
        args = args,
        player = player,
        isReply = source ~= nil,
        exchangeId = source and source:getExchangeId(),
    }

    local attempts = req:getSendAttempts()
    topic:onClientSend(req)
    return self:_trySend(req, attempts)
end

---Creates a new Topic for the dispatcher to handle.
---@param name string The unique name of the topic.
---@param options Args.Topic.Partial? Options for the topic.
---@return Topic
function Dispatcher:topic(name, options)
    options = core.copy(options)

    ---@cast options Args.Topic
    options.dispatcher = self
    options.name = name

    local topic = Topic:new(options)

    self._topics[name] = topic

    self:log(TOPIC_ADD, topic, self)
    return topic
end


---Called when an event the dispatcher is listening for is triggered.
---Used to forward to event triggers.
---@param triggerType Trigger.Type
---@param event string
---@protected
function Dispatcher:_onEvent(triggerType, event)
    ---@type table<Topic, TriggerOptions.Event>
    local state = self._triggers[triggerType]
    if not state then
        return
    end

    for topic, opts in pairs(state) do
        if opts.event == event then
            self:log(TRIGGER_ACTIVATE, triggerType, topic)

            local target = IS_SERVER and topic.broadcast or topic.toServer
            target(topic --[[@as any]])
        end
    end
end

---Called when on interval for a topic with an interval trigger.
---@param topic Topic
---@protected
function Dispatcher:_onInterval(topic)
    local state = self._triggers[Trigger.Type.Interval]
    if not state or not state[topic] then
        return
    end

    self:log(TRIGGER_ACTIVATE, Trigger.Type.Interval, topic)
    local target = IS_SERVER and topic.broadcast or topic.toServer
    target(topic --[[@as any]])
end

---Called when a player dies, if a topic with the PlayerDeath trigger exists.
---@param player IsoPlayer
---@protected
function Dispatcher:_onPlayerDeath(player)
    ---@type table<Topic, TriggerOptions.PlayerDeath>
    local state = self._triggers[Trigger.Type.PlayerDeath]
    if not state then
        return
    end

    local isPlayer1 = player:getPlayerNum() == 0
    for topic, opts in pairs(state) do
        if not opts.onlyPlayer1 or isPlayer1 then
            self:log(TRIGGER_ACTIVATE, Trigger.Type.PlayerDeath, topic)
            topic:toServer()
        end
    end
end

---Called every tick until a player object is available, if a topic with the PlayerJoined trigger exists.
---@protected
function Dispatcher:_onPlayerJoinedCheck()
    local state = self._triggers[Trigger.Type.PlayerJoined]
    if not state then
        return
    end

    if not getSpecificPlayer(0) then
        return
    end

    if self._eventListeners.OnTick then
        Events.OnTick.Remove(self._eventListeners.OnTick)
        self._eventListeners.OnTick = nil
    end

    for topic in pairs(state) do
        self:log(TRIGGER_ACTIVATE, Trigger.Type.PlayerJoined, topic)
        topic:toServer()
    end
end

---Called when receiving a client or server request.
---@param isFromServer boolean?
---@param module string
---@param command string
---@param args table?
---@param player IsoPlayer?
---@protected
function Dispatcher:_onReceive(isFromServer, module, command, args, player)
    if module ~= self._module then
        return
    end

    local topic = self._topics[command]
    if not topic then
        self:log(TOPIC_UNKNOWN, command)
        return
    end

    args = args or {}

    local exchangeId = args['$__EXID']
    args['$__EXID'] = nil

    local isReply = false
    if args['$__REPLY'] then
        args['$__REPLY'] = nil
        isReply = true
    end

    local req
    if isFromServer then
        req = ServerRequest:new {
            topic = topic,
            args = args,
            isIncoming = true,
            isReply = isReply,
            exchangeId = exchangeId,
        }
    else
        req = ClientRequest:new {
            topic = topic,
            args = args,
            player = player --[[@as IsoPlayer]],
            isIncoming = true,
            isReply = isReply,
            exchangeId = exchangeId,
        }
    end

    local canReceive, reason = req:canReceive()
    if not canReceive then
        if reason then
            self:log(REQ_RECEIVE_FAIL, req, reason)
        end

        return
    end

    self:log(REQ_RECEIVE, req)

    if isFromServer then
        topic:onClientReceive(req --[[@as ServerRequest]])
    else
        topic:onServerReceive(req --[[@as ClientRequest]])
    end
end

---Sets up an event trigger for a topic.
---@param topic Topic
---@param triggerType Trigger.Type
---@param event string
---@protected
function Dispatcher:_triggerOnEvent(topic, triggerType, event)
    self._triggers[triggerType] = self._triggers[triggerType] or {}

    ---@type table<Topic, TriggerOptions.Event>
    local state = self._triggers[triggerType]
    state[topic] = { event = event }

    if self._eventListeners[event] then
        return
    end

    local eventObj = Events[event]
    if eventObj then
        self._eventListeners[event] = core.bind(self._onEvent, self, triggerType, event)
        eventObj.Add(self._eventListeners[event])
    end
end

---Sets up an interval trigger for a topic.
---@param topic Topic
---@param opts TriggerOptions.Interval
---@protected
function Dispatcher:_triggerOnInterval(topic, opts)
    self._triggers[Trigger.Type.Interval] = self._triggers[Trigger.Type.Interval] or {}

    local state = self._triggers[Trigger.Type.Interval]

    -- clear existing interval if present
    local timer = state[topic] and state[topic].timer ---@type Timer?
    if timer then
        timer:cancel()
    end

    -- start new interval
    timer = core.setInterval(opts.interval, self._onInterval, self, topic)
    state[topic] = { timer = timer }
end

---Sets up a player death trigger for a topic.
---@param topic Topic
---@param opts TriggerOptions.PlayerDeath
---@protected
function Dispatcher:_triggerOnPlayerDeath(topic, opts)
    if IS_SERVER then
        -- no-op on server
        return
    end

    self._triggers[Trigger.Type.PlayerDeath] = self._triggers[Trigger.Type.PlayerDeath] or {}

    local state = self._triggers[Trigger.Type.PlayerDeath]
    state[topic] = opts

    if self._eventListeners.OnPlayerDeath then
        return
    end

    self._eventListeners.OnPlayerDeath = core.bind(self._onPlayerDeath, self)
    Events.OnPlayerDeath.Add(self._eventListeners.OnPlayerDeath)
end

---Sets up a player join trigger for a topic.
---@param topic Topic
---@protected
function Dispatcher:_triggerOnPlayerJoined(topic)
    if IS_SERVER then
        -- no-op on server
        return
    end

    self._triggers[Trigger.Type.PlayerJoined] = self._triggers[Trigger.Type.PlayerJoined] or {}

    local state = self._triggers[Trigger.Type.PlayerJoined]
    state[topic] = {}

    if self._eventListeners.OnTick then
        return
    end

    self._eventListeners.OnTick = core.bind(self._onPlayerJoinedCheck, self)
    Events.OnTick.Add(self._eventListeners.OnTick)
end

---Attempts to send a request.
---@param req Request
---@param prevAttempts integer
---@return boolean success
---@return string? err
---@protected
function Dispatcher:_trySend(req, prevAttempts)
    if req:isCancelled() then
        return false
    elseif req:getSendAttempts() > prevAttempts then
        if req:isSent() then
            return true
        end

        return false, req:getLastError()
    end

    return req:send()
end

---Converts the dispatcher to a string representation.
---@return string
---@protected
function Dispatcher:__tostring()
    return 'Dispatcher<' .. self._module .. '>'
end


---Creates a new dispatcher.
---@param options Args.Dispatcher
---@return Dispatcher
function Dispatcher:new(options)
    local this = core.new(self)

    this._topics = {}
    this._triggers = {}
    this._eventListeners = {}
    this._module = options.module
    this._log = options.logger

    this:connect()
    return this
end


return Dispatcher

--#region Type Definitions

---@class Args.Dispatcher
---@field module string The module identifier to use for commands.
---@field logger? Logger The logger to use for debug messages.

--#endregion
