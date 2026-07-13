---Module for dispatching and receiving commands.
---@namespace omi

local Channel = require 'OmiLibrary/Component/Dispatch/Channel'
local Trigger = require 'OmiLibrary/Component/Dispatch/Trigger'
local Request = require 'OmiLibrary/Component/Dispatch/Request'
local Dispatcher = require 'OmiLibrary/Component/Dispatch/Dispatcher'
local ClientRequest = require 'OmiLibrary/Component/Dispatch/ClientRequest'
local ServerRequest = require 'OmiLibrary/Component/Dispatch/ServerRequest'


---@class dispatch
---@overload fun(options: Args.Dispatcher): Dispatcher
local dispatch = {}
dispatch.Dispatcher = Dispatcher
dispatch.Channel = Channel
dispatch.Trigger = Trigger
dispatch.Request = Request
dispatch.ClientRequest = ClientRequest
dispatch.ServerRequest = ServerRequest


---Creates a new dispatcher.
---@param options Args.Dispatcher
---@return Dispatcher
function dispatch.new(options)
    return Dispatcher:new(options)
end


setmetatable(dispatch, { __call = function(self, ...) return self.new(...) end })
return dispatch

--#region Type Definitions

---@alias dispatch.Callback.OnSend fun(req: Request, args: table)
---@alias dispatch.Callback.OnClientSend fun(req: ClientRequest, args: table)
---@alias dispatch.Callback.OnServerSend fun(req: ServerRequest, args: table)

---@alias dispatch.Callback.OnReceive fun(req: Request, args: table)
---@alias dispatch.Callback.OnClientReceive fun(req: ServerRequest, args: table)
---@alias dispatch.Callback.OnServerReceive fun(req: ClientRequest, args: table)

---@alias dispatch.Callback.OnValidate fun(req: ClientRequest, args: table): boolean, string?

---@alias dispatch.Callback.OnStringifyArgs fun(args: table, req: Request): string?
---@alias dispatch.Callback.OnStringifyClientArgs fun(args: table, req: ClientRequest): string?
---@alias dispatch.Callback.OnStringifyServerArgs fun(args: table, req: ServerRequest): string?

--#endregion
