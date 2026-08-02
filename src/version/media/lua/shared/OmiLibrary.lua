---Library functionality shared between the server and client.
---@namespace omi

local proxy = require 'OmiLibrary/Module/Proxy'
require 'OmiLibrary/Override/Core'

---@type core
local core = proxy(({ _core = true } --[[@as Args.Proxy]]))


---@class shared : core
local OmiLibrary = core

---Creates a proxy table for library utilities.
OmiLibrary.proxy = proxy


return OmiLibrary
