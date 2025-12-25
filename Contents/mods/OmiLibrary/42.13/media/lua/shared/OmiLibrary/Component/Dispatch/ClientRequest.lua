---A request sent from the client to the server.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local Request = require 'OmiLibrary/Component/Dispatch/Request'

---@class ClientRequest : Request
---@field protected _player IsoPlayer The player associated with the request.
local ClientRequest = Request:derive('ClientRequest')


---Checks that the incoming request can be accepted.
---@return boolean canReceive Whether the request can be received.
---@return string? reason The reason the request cannot be received.
function ClientRequest:canReceive()
    local topic = self._topic
    local player = self._player

    if topic:isRequireAdmin() and (not player or not player:isAccessLevel('Admin')) then
        return false, 'Insufficient permissions'
    end

    local success, err = topic:validateOnServer(self)
    if not success then
        return false, err or 'Validation failed'
    end

    return Request.canReceive(self)
end

---Checks that the outgoing request can be sent.
---@return boolean canSend Whether the request can be sent.
---@return string? reason The reason the request cannot be sent. If `canSend` is `false` and this is absent, the request was cancelled.
function ClientRequest:canSend()
    local topic = self._topic
    local player = self._player

    if topic:isRequireAdmin() and (not player or not player:isAccessLevel('Admin')) then
        return false, 'Insufficient permissions'
    end

    if not topic:isAllowDead() then
        if not player or player:isDead() then
            return false, 'Player character is dead'
        end
    end

    local success, err = topic:validateOnClient(self)
    if not success then
        return false, err or 'Validation failed'
    end

    return Request.canSend(self)
end

---Returns the player associated with the request.
---@return IsoPlayer
function ClientRequest:getPlayer()
    return self._player
end

---Returns whether the request is a client request.
---@return boolean
function ClientRequest:isFromClient()
    return true
end


---Creates a new request to be sent from client to the server.
---@param args Args.ClientRequest
---@return ClientRequest
function ClientRequest:new(args)
    assert(args.player ~= nil, 'ClientRequest is missing player')
    return core.new(self, Request.new, args)
end


return ClientRequest

--#region Type Definitions

---@class Args.ClientRequest : Args.Request
---@field player IsoPlayer The player associated with the request.

--#endregion
