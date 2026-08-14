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

---Reads JSON from a file.
---@param optionsOrFilename Args.ReadJSON | string
---@return boolean success
---@return json.JSONType resultOrError
function json.tryRead(optionsOrFilename)
    if type(optionsOrFilename) == 'string' then
        optionsOrFilename = { filename = optionsOrFilename }
    end

    local options = optionsOrFilename --[[@as Args.ReadJSON]]
    local file = options.reader
    if not file then
        local filename = options.filename
        if not filename then
            return false, 'no reader or filename given'
        end

        if options.modId then
            file = getModFileReader(options.modId, filename, options.create or false)
        else
            file = getFileReader(filename, options.create or false)
        end

        if not file then
            return false, 'could not open file ' .. filename
        end
    end

    local content = {}
    while file:ready() do
        content[#content + 1] = file:readLine()
    end

    file:close()

    local encoded = table.concat(content):trim()
    if #encoded == 0 then
        return false, 'file is empty'
    end

    return json.tryDecode(encoded)
end

---Reads a JSON object from a file.
---@param optionsOrFilename Args.ReadJSON | string
---@return table? result
---@return string? error
function json.tryReadObject(optionsOrFilename)
    local success, result = json.tryRead(optionsOrFilename)
    if not success then
        if result == 'file is empty' then
            return {}
        end

        return nil, result --[[@as string]]
    end

    if type(result) ~= 'table' then
        return nil, 'invalid file content'
    end

    return result
end


return json

--#region Type Definitions

---@alias json.JSONType table | string | number | boolean | nil

---@class Args.ReadJSON
---@field filename? string The filename to read. This assumes the file is in the Lua cache directory unless `modId` is given.
---@field modId? string The ID of the mod to read from.
---@field reader? BufferedReader The reader to use. If present, `filename` will be ignored.
---@field create? boolean Flag for whether the file should be created if not found. Defaults to `false`.

--#endregion
