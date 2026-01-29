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

---Reads JSON from a file.
---@param optionsOrFilename Args.ReadJSON | string
---@return json.JSONType result
---@return string? error
function json.read(optionsOrFilename)
    if type(optionsOrFilename) == 'string' then
        optionsOrFilename = { filename = optionsOrFilename }
    end

    local options = optionsOrFilename --[[@as Args.ReadJSON]]
    local file = options.reader
    if not file then
        local filename = tostring(options.filename)
        pcall(function()
            file = getFileReader(filename, options.create ~= false)
        end)

        if not file then
            return nil, 'could not open file ' .. filename
        end
    end

    local content = {}
    while file:ready() do
        content[#content + 1] = file:readLine()
    end

    file:close()

    local encoded = table.concat(content):trim()
    if #encoded == 0 then
        return nil, 'file is empty'
    end

    local success, decoded = json.tryDecode(encoded)
    if not success then
        return nil, decoded --[[@as string]]
    end

    return decoded
end

---Reads a JSON object from a file.
---@param optionsOrFilename Args.ReadJSON | string
---@return table? result
---@return string? error
function json.readObject(optionsOrFilename)
    local decoded, err = json.read(optionsOrFilename)
    if err then
        if err == 'file is empty' then
            return {}
        end

        return nil, err
    end

    if type(decoded) ~= 'table' then
        return nil, 'invalid file content'
    end

    return decoded
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

---@class Args.ReadJSON
---@field filename? string The filename to read. This assumes the file is in the Lua cache directory.
---@field reader? BufferedReader The reader to use. If present, `filename` will be ignored.
---@field create? boolean Flag for whether the file should be created if not found. Defaults to `true`.

--#endregion
