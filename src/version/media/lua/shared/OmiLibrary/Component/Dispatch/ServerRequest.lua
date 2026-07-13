---A request sent from the server to the client.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local Request = require 'OmiLibrary/Component/Dispatch/Request'

---@class ServerRequest : Request
local ServerRequest = Request:derive('ServerRequest')


---Returns whether the request is a server request.
---@return boolean
function ServerRequest:isFromServer()
    return true
end


---Creates a new request to be sent from the server to the client.
---@param args Args.Request
---@return ServerRequest
function ServerRequest:new(args)
    return core.new(self, Request.new, args)
end


return ServerRequest
