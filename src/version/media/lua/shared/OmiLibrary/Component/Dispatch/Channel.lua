---A channel for exchanging requests between server and client.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local json = require 'OmiLibrary/Module/JSON'

local IS_CLIENT = isClient()
local IS_SERVER = isServer()

local ENCODE_ARGS_FAIL = 'Failed to encode arguments for %s: %s'

---@class Channel : Class
---@field protected _name string The command name for the channel.
---@field protected _dispatcher Dispatcher The dispatcher that contains the channel.
---@field protected _allowDead boolean Whether the channel allows requests to be sent while the player character is dead.
---@field protected _requireAdmin boolean Whether the channel requires clients to have admin for sending requests.
---@field protected _canLogArgs boolean Whether requests made on the channel should include their arguments in logs.
---@field protected _callbacks Channel.Callbacks The callbacks of the channel.
local Channel = core.class('Channel')


---Sends a request on the channel to all players.
---@param args table? Arguments to send with the request.
---@param source Request? The source of the request, if this is a reply.
---@return boolean success
---@return string? error
function Channel:broadcast(args, source)
    return self._dispatcher:broadcast(self, args, source)
end

---Returns whether requests on the channel should log their arguments.
---@return boolean
function Channel:canLogArgs()
    return self._canLogArgs
end

---Gets the dispatcher that controls this channel.
---@return Dispatcher
function Channel:getDispatcher()
    return self._dispatcher
end

---Returns the name of the channel.
---@return string
function Channel:getName()
    return self._name
end

---Returns the module of the channel.
---@return string
function Channel:getModule()
    return self._dispatcher:getModule()
end

---Returns the module and name of the channel.
---@return string module
---@return string name
function Channel:getModuleAndName()
    return self._dispatcher:getModule(), self._name
end

---Returns whether requests can be made for dead players.
---@return boolean
function Channel:isAllowDead()
    return self._allowDead
end

---Returns whether clients require admin to send commands on the channel.
---@return boolean
function Channel:isRequireAdmin()
    return self._requireAdmin
end

---Invoked when a request is received on the client.
---@param req ServerRequest
function Channel:onClientReceive(req)
    if self._callbacks.onReceive then
        self._callbacks.onReceive(req, req.args)
    end

    if self._callbacks.onClientReceive then
        self._callbacks.onClientReceive(req, req.args)
    end
end

---Invoked when a request is about to be sent on the client.
---@param req ClientRequest
function Channel:onClientSend(req)
    if self._callbacks.onSend then
        self._callbacks.onSend(req, req.args)
    end

    if self._callbacks.onSingleplayerSend and req:isSingleplayer() then
        self._callbacks.onSingleplayerSend(req, req.args)
    elseif self._callbacks.onClientSend then
        self._callbacks.onClientSend(req, req.args)
    end
end

---Invoked when a request is received on the server.
---@param req ClientRequest
function Channel:onServerReceive(req)
    if self._callbacks.onReceive then
        self._callbacks.onReceive(req, req.args)
    end

    if self._callbacks.onServerReceive then
        self._callbacks.onServerReceive(req, req.args)
    end
end

---Invoked when a request is about to be sent on the server.
---@param req ServerRequest
function Channel:onServerSend(req)
    if self._callbacks.onSend then
        self._callbacks.onSend(req, req.args)
    end

    if self._callbacks.onSingleplayerSend and req:isSingleplayer() then
        self._callbacks.onSingleplayerSend(req, req.args)
    elseif self._callbacks.onServerSend then
        self._callbacks.onServerSend(req, req.args)
    end
end

---Sets a function to be called when a request from the server is received on the client.
---@param callback dispatch.Callback.OnClientReceive?
---@return Channel
function Channel:setOnClientReceive(callback)
    self._callbacks.onClientReceive = callback
    return self
end

---Sets a function to be called when a request is about to be sent on the client.
---@param callback dispatch.Callback.OnClientSend?
---@return Channel
function Channel:setOnClientSend(callback)
    self._callbacks.onClientSend = callback
    return self
end

---Sets a function to be called for validating an outgoing request on the client.
---@param callback dispatch.Callback.OnValidate?
---@return Channel
function Channel:setOnClientValidate(callback)
    self._callbacks.onClientValidate = callback
    return self
end

---Sets a function to be called when a request is received.
---@param callback dispatch.Callback.OnReceive?
---@return Channel
function Channel:setOnReceive(callback)
    self._callbacks.onReceive = callback
    return self
end

---Sets a function to be called when a request is about to be sent.
---This can be used to transform the request or send it directly.
---@param callback dispatch.Callback.OnSend?
---@return Channel
function Channel:setOnSend(callback)
    self._callbacks.onSend = callback
    return self
end

---Sets a function to be called when a request from the client is received on the server.
---@param callback dispatch.Callback.OnServerReceive?
---@return Channel
function Channel:setOnServerReceive(callback)
    self._callbacks.onServerReceive = callback
    return self
end

---Sets a function to be called when a request is about to be sent on the server.
---@param callback dispatch.Callback.OnServerSend?
---@return Channel
function Channel:setOnServerSend(callback)
    self._callbacks.onServerSend = callback
    return self
end

---Sets a function to be called for validating an incoming request on the server.
---@param callback dispatch.Callback.OnValidate?
---@return Channel
function Channel:setOnServerValidate(callback)
    self._callbacks.onServerValidate = callback
    return self
end

---Sets a function to be called when a request is about to be sent in singleplayer.
---This can be used to transform the request or send it directly.
---
---If the singleplayer callback is called, the server- or client-specific callback will not be called.
---@param callback dispatch.Callback.OnSend?
---@return Channel
function Channel:setOnSingleplayerSend(callback)
    self._callbacks.onSingleplayerSend = callback
    return self
end

---Sets a function to be called to encode request arguments as a string for logging.
---This is only used if a more specific callback is not given.
---@param callback dispatch.Callback.OnStringifyArgs?
---@return Channel
function Channel:setOnStringifyArgs(callback)
    self._callbacks.onStringifyArgs = callback
    return self
end

---Sets a function to be called to encode client to server request arguments as a string for logging.
---@param callback dispatch.Callback.OnStringifyClientArgs?
---@return Channel
function Channel:setOnStringifyClientArgs(callback)
    self._callbacks.onStringifyClientArgs = callback
    return self
end

---Sets a function to be called to encode server to client request arguments as a string for logging.
---@param callback dispatch.Callback.OnStringifyServerArgs?
---@return Channel
function Channel:setOnStringifyServerArgs(callback)
    self._callbacks.onStringifyServerArgs = callback
    return self
end

---Sets a function to be called for validating an outgoing request on the client or an incoming request on the server.
---@param callback dispatch.Callback.OnValidate?
---@return Channel
function Channel:setOnValidate(callback)
    self._callbacks.onValidate = callback
    return self
end

---Converts the arguments into a string representation for logs.
---@param req Request
---@return string
function Channel:stringifyArgs(req)
    if not self._canLogArgs then
        return '{...}'
    end

    local args = req.args
    local stringifyCallback
    if req:isFromServer() then
        stringifyCallback = self._callbacks.onStringifyServerArgs
    else
        stringifyCallback = self._callbacks.onStringifyClientArgs
    end

    stringifyCallback = stringifyCallback or self._callbacks.onStringifyArgs
    if stringifyCallback then
        local encoded = stringifyCallback(args, req)
        if encoded then
            if core.trim(encoded) == '' then
                return '{...}'
            end

            return encoded
        end
    end

    local encoded, err = json.tryEncode(args)
    if err then
        self._dispatcher:log(ENCODE_ARGS_FAIL, self, err)
    end

    return encoded or '{...}'
end

---Sends a request on the channel to a player.
---@param player IsoPlayer The player to send the request to.
---@param args table? Arguments to send with the request.
---@param source Request? The source of the request, if this is a reply.
---@return boolean success
---@return string? error
function Channel:toPlayer(player, args, source)
    return self._dispatcher:toPlayer(self, player, args, source)
end

---Sends a request on the channel to a player if given. Otherwise, broadcasts to all clients.
---@param player IsoPlayer? The player to send the request to.
---@param args table? Arguments to send with the request.
---@param source Request? The source of the request, if this is a reply.
---@return boolean success
---@return string? error
function Channel:toPlayerOrBroadcast(player, args, source)
    if player then
        return self:toPlayer(player, args, source)
    else
        return self:broadcast(args, source)
    end
end

---Sends a request on the channel to the server.
---@param args table? Arguments to send with the request.
---@param source Request? The source of the request, if this is a reply.
---@return boolean success
---@return string? error
function Channel:toServer(args, source)
    return self._dispatcher:toServer(self, args, source)
end

---Validates an outgoing request on the client.
---@param req ClientRequest
---@return boolean success
---@return string? error
function Channel:validateOnClient(req)
    if self._callbacks.onValidate then
        local success, err = self._callbacks.onValidate(req, req.args)
        if not success then
            return success, err
        end
    end

    if self._callbacks.onClientValidate then
        return self._callbacks.onClientValidate(req, req.args)
    end

    return true
end

---Validates an incoming request on the server.
---@param req ClientRequest
---@return boolean success
---@return string? error
function Channel:validateOnServer(req)
    if self._callbacks.onValidate then
        local success, err = self._callbacks.onValidate(req, req.args)
        if not success then
            return success, err
        end
    end

    if self._callbacks.onServerValidate then
        return self._callbacks.onServerValidate(req, req.args)
    end

    return true
end


---Adds the triggers from the given list to the channel.
---@param triggers Trigger[]?
---@protected
function Channel:_addTriggers(triggers)
    if not triggers then
        return
    end

    for i = 1, #triggers do
        self._dispatcher:addTrigger(self, triggers[i])
    end
end


---Converts the channel to a string representation.
---@return string
---@protected
function Channel:__tostring()
    return 'Channel<' .. self._name .. '>'
end


---Creates a new channel.
---@param options Args.Channel
---@return Channel
function Channel:new(options)
    local this = core.new(self)

    this._name = options.name
    this._dispatcher = options.dispatcher
    this._allowDead = options.allowDead or false
    this._requireAdmin = options.requireAdmin or false
    this._canLogArgs = options.canLogArgs ~= false

    this._callbacks = {}

    this:setOnSend(options.onSend)
    this:setOnReceive(options.onReceive)
    this:setOnValidate(options.onValidate)
    this:setOnClientSend(options.onClientSend)
    this:setOnClientReceive(options.onClientReceive)
    this:setOnClientValidate(options.onClientValidate)
    this:setOnServerSend(options.onServerSend)
    this:setOnServerReceive(options.onServerReceive)
    this:setOnServerValidate(options.onServerValidate)
    this:setOnSingleplayerSend(options.onSingleplayerSend)
    this:setOnStringifyArgs(options.onStringifyArgs)
    this:setOnStringifyClientArgs(options.onStringifyClientArgs)
    this:setOnStringifyServerArgs(options.onStringifyServerArgs)

    this:_addTriggers(options.triggers)

    if IS_CLIENT then
        this:_addTriggers(options.clientTriggers)
    end

    if IS_SERVER then
        this:_addTriggers(options.serverTriggers)
    end

    return this
end


return Channel

--#region Type Definitions

---@class Args.Channel.Partial : Channel.Callbacks
---@field allowDead? boolean Whether the channel allows requests to be sent while the player character is dead. Defaults to `false`.
---@field requireAdmin? boolean Whether the channel requires clients to have admin for sending requests. Defaults to `false`.
---@field canLogArgs? boolean Whether requests made on the channel should include their arguments in logs. Defaults to `true`.
---@field triggers? Trigger[] Conditions that will automatically send a request when triggered. On the server, triggers send a broadcast.
---@field clientTriggers? Trigger[] Conditions that will automatically send a request to the server when triggered.
---@field serverTriggers? Trigger[] Conditions that will automatically send a broadcast to all clients when triggered.

---@class Args.Channel : Args.Channel.Partial
---@field name string The command name for the channel.
---@field dispatcher Dispatcher The dispatcher that handles the channel.


---@class Channel.Callbacks
---@field onClientReceive? dispatch.Callback.OnClientReceive Called when a request from the server is received on the client.
---@field onClientSend? dispatch.Callback.OnClientSend Called when a request is about to be sent on the client.
---@field onClientValidate? dispatch.Callback.OnValidate Called to validate an outgoing request on the client.
---@field onStringifyArgs? dispatch.Callback.OnStringifyArgs Called to encode request arguments as a string for logging. A return value of `nil` indicates that the default JSON encoding should be used. This is only used if a more specific callback is not given.
---@field onStringifyClientArgs? dispatch.Callback.OnStringifyClientArgs Called to encode client to server request arguments as a string for logging. A return value of `nil` indicates that the default JSON encoding should be used.
---@field onStringifyServerArgs? dispatch.Callback.OnStringifyServerArgs Called to encode server to client request arguments as a string for logging. A return value of `nil` indicates that the default JSON encoding should be used.
---@field onReceive? dispatch.Callback.OnReceive Called when a request is received.
---@field onSend? dispatch.Callback.OnSend Called when a request is about to be sent.
---@field onServerReceive? dispatch.Callback.OnServerReceive Called when a request from the client is received on the server.
---@field onServerSend? dispatch.Callback.OnServerSend Called when a request is about to be sent on the server.
---@field onServerValidate? dispatch.Callback.OnValidate Called to validate an incoming request on the server.
---@field onSingleplayerSend? dispatch.Callback.OnSend Called when a request is about to be sent on singleplayer. If the singleplayer callback is called, the server- or client-specific callback will not be called.
---@field onValidate? dispatch.Callback.OnValidate Called to validate incoming requests on the server and outgoing requests on the client.

--#endregion
