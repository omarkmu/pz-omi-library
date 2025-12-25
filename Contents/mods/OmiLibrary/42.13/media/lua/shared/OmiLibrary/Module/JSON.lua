---Contains utilities for encoding and decoding JSON values.
---@namespace omi

---@class json
local json = {}

---Component for encoding types as JSON strings.
json.Encoder = require 'OmiLibrary/Component/JSON/Encoder'

---Component for decoding JSON strings.
json.Decoder = require 'OmiLibrary/Component/JSON/Decoder'


local encoder = json.Encoder:new()
local decoder = json.Decoder:new()


---Decodes a value from JSON.
---Throws an error on failure.
---@param str string
---@return json.JSONType
function json.decode(str)
    return decoder:decode(str)
end

---Encodes a value as JSON.
---Throws an error on failure.
---@param value json.JSONType
---@param options Args.JSONEncoder?
---@return string
function json.encode(value, options)
    return encoder:encode(value, options or {})
end

---Attempts to decode a value from JSON.
---@param str string
---@return boolean success
---@return json.JSONType resultOrError
function json.tryDecode(str)
    return decoder:tryDecode(str)
end

---Attempts to encode a value as JSON.
---@param value json.JSONType
---@param options Args.JSONEncoder?
---@return string? result
---@return string? error
function json.tryEncode(value, options)
    return encoder:tryEncode(value, options or {})
end


return json

--#region Type Definitions

---@alias json.JSONType table | string | number | boolean | nil

--#endregion
