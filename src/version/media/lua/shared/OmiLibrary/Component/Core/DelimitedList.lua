---Helper for creating lists from delimited strings.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'


---@class DelimitedList : Class
---@field protected _cached string The cached source string.
---@field protected _delimiter string The delimiter to use for splitting.
---@field protected _table? table The table to read the source from.
---@field protected _key? string The table key to read the source from.
---@field protected _list string[] The list created from the source string.
local DelimitedList = core.class('DelimitedList')


---Updates the delimited list by comparing with the underlying string.
---If the string is the same, this has no effect.
---@param str string?
---@return string[] list
function DelimitedList:update(str)
    if not str and self._table and self._key then
        str = self._table[self._key]
    elseif not str then
        str = ''
    end

    str = tostring(str):trim()
    if str == self._cached then
        return self._list
    end

    self._cached = str
    return core.split(str --[[@as string]], self._delimiter, self._list)
end

---Returns the underlying list.
---@return string[]
function DelimitedList:list()
    if self._table and self._key then
        -- if it's in a table, auto-update
        self:update()
    end

    return self._list
end

---Sets the delimiter of the list.
---@param delimiter string
function DelimitedList:setDelimiter(delimiter)
    if delimiter == self._delimiter then
        return
    end

    self._delimiter = delimiter

    local str = self._cached ---@type string?
    self._cached = ''

    if self._table and self._key then
        str = nil
    end

    self:update(str)
end


---Creates a new delimited list.
---@param options Args.DelimitedList?
---@return DelimitedList
function DelimitedList:new(options)
    local this = core.new(self)
    options = options or {}

    this._cached = ''
    this._list = {}
    this._delimiter = options.delimiter or ';'

    if options.table then
        this._table = options.table
        this._key = options.source
    elseif options.source then
        this:update(options.source)
    end

    return this
end


return DelimitedList

--#region DelimitedList

---@class Args.DelimitedList
---@field source? string The initial source string. If a table is given, this will be interpreted as the source key to use.
---@field table? table The source table to use to check for the source string.
---@field delimiter? string The delimiter. Defaults to `;`.

--#endregion
