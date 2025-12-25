---Library functionality specific to the client.
---@namespace omi

---@class client : shared
local OmiLibrary = require 'OmiLibrary'


---Contains components and utilities related to the UI.
OmiLibrary.ui = require 'OmiLibrary/Module/UI'

---Contains components and utilities related to the chat.
OmiLibrary.chat = require 'OmiLibrary/Module/Chat'


return OmiLibrary
