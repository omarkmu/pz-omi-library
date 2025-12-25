---Core utility functions.
---@namespace omi

local ISO8859_ENTITIES = require 'OmiLibrary/Definition/ISO8859Entities'
local Scheduler = require 'OmiLibrary/Component/Core/Scheduler'


-- this is definitely excessive, but for utils why not optimize a bit
local type = type
local pairs = pairs
local pcall = pcall
local unpack = unpack
local rawget = rawget
local select = select
local wipe = table.wipe
local char = string.char
local floor = math.floor
local tonumber = tonumber
local isServer = isServer
local tostring = tostring
local concat = table.concat
local getmetatable = getmetatable
local setmetatable = setmetatable
local getOnlinePlayers = getOnlinePlayers
local getPlayerFromUsername = getPlayerFromUsername


---@class(partial) core
---@field private _activatedMods string[]? List of activated mod IDs.
---@field private _activatedModsQualified string[]? List of activated fully-qualified mod IDs (including workshop item IDs).
---@field private _activatedModsSet SetTable<string>? Set of activated mod IDs.
---@field private _activatedModsSetQualified SetTable<string>? Set of activated fully-qualified mod IDs (including workshop item IDs).
---@field private _activatedWorkshopItems SetTable<string>? Set of activated workshop item IDs.
---@field private _random Random? Shared `Random` instance.
local core = {}

---Shared scheduler instance used for timer functions.
---@private
core._scheduler = Scheduler:new()

---Alias for `tonumber`.
---This does not verify that the number is an integer;
---it is intended for coercing the type to integer.
core.tointeger = tonumber ---@as fun(e: any): integer?

---Contains functionality related to creating classes.
---When called as a function, creates a new class.
core.class = require 'OmiLibrary/Module/Class'

local URL_ALLOWLIST = {
    ['https://steamcommunity.com'] = true,
    ['https://projectzomboid.com'] = true,
    ['https://theindiestone.com'] = true,
    ['https://pzwiki.net'] = true,
}

local URL_ALLOWLIST_START = {}
for k in pairs(URL_ALLOWLIST) do
    URL_ALLOWLIST_START[#URL_ALLOWLIST_START + 1] = k .. '/'
end

---Returns whether the result of `func` is truthy for all values in `target`.
---@generic T
---@param predicate fun(element: T): any? Predicate function.
---@param target table<any, T> The table to check.
---@return boolean
function core.all(predicate, target)
    for _, v in pairs(target) do
        if not predicate(v) then
            return false
        end
    end

    return true
end

---Returns whether the result of `func` is truthy for any value in `target`.
---@generic T
---@param predicate fun(element: T): any? Predicate function.
---@param target table<any, T> The table to check.
---@return boolean
function core.any(predicate, target)
    for _, v in pairs(target) do
        if predicate(v) then
            return true
        end
    end

    return false
end

---Appends elements of the given lists to `t1`.
---@generic T, U
---@param t1 T[] The list to add elements to.
---@param ...U[] The lists from which elements should be added.
---@return (T + U)[] t1
function core.append(t1, ...)
    for i = 1, select('#', ...) do
        local t2 = select(i, ...)
        for j = 1, #t2 do
            t1[#t1 + 1] = t2[j]
        end
    end

    return t1
end

---Appends elements of the given lists to a shallow copy of `t1`.
---@generic T, U
---@param t1 T[]? The list to add elements to.
---@param ...U[] The lists from which elements should be added.
---@return (T + U)[] t1
function core.appendCopy(t1, ...)
    return core.append(core.copy(t1), ...)
end

---Appends the given elements to `t1`.
---@generic T, U
---@param t1 T[] The list to add elements to.
---@param ...U The values to append to `t1`.
---@return (T + U)[] t1
function core.appendElements(t1, ...)
    for i = 1, select('#', ...) do
        t1[#t1 + 1] = select(i, ...)
    end

    return t1
end

---Appends a subset of the members of `t2` to `t1`.
---@generic T, U
---@param t1 T[] The table to add elements to.
---@param t2 U[] The table from which elements should be added.
---@param i integer? The first index to append from in `t1`. Defaults to `1`.
---@param j integer? The last index to append from in `t2`. Defaults to `#t2`.
---@return (T + U)[] t1
function core.appendSlice(t1, t2, i, j)
    i = i or 1
    j = j or #t2
    for idx = i, j do
        t1[#t1 + 1] = t2[idx]
    end

    return t1
end

---Creates a new function given arguments that precede any provided arguments when `func` is called.
---@param func function
---@param ...any
---@return function
function core.bind(func, ...)
    local nArgs = select('#', ...)
    local boundArgs = { ... }

    return function(...)
        local args = { unpack(boundArgs, 1, nArgs) }
        local nNewArgs = select('#', ...)
        for i = 1, nNewArgs do
            args[nArgs + i] = select(i, ...)
        end

        return func(unpack(args, 1, nArgs + nNewArgs))
    end
end

---Clamps a value between a minimum and maximum.
---@generic T : number
---@param value T
---@param minimum T
---@param maximum T
---@return T
function core.clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    elseif value > maximum then
        return maximum
    end

    return value
end

---Converts table elements to strings and concatenates.
---@param target any[] A list of values.
---@param sep string? The separator to use between elements. Defaults to the empty string.
---@param i integer? The index at which concatenation should start. Defaults to `1`.
---@param j integer? The index at which concatenation should stop. Defaults to the length of `target`.
---@return string
function core.concat(target, sep, i, j)
    return concat(core.mapList(tostring, target), sep or '', i or 1, j or #target)
end

---Returns true if `text` contains `other`.
---@param text string
---@param other string?
---@return boolean
function core.contains(text, other)
    if not other then
        return false
    elseif #other == 0 then
        return true
    end

    return text:find(other, 1, true) ~= nil
end

---Returns a shallow copy of a table.
---@generic T : table | nil
---@param table T
---@return T - ?
function core.copy(table)
    local copy = {}

    table = table or {}
    for k, v in pairs(table) do
        copy[k] = v
    end

    return copy
end

---Returns a shallow copy of a list.
---@generic T : any[] | nil
---@param list T
---@return T - ?
function core.copyList(list)
    local copy = {}

    list = list or {}
    for i = 1, #list do
        copy[i] = list[i]
    end

    return copy
end

---Returns `value` if non-nil. Otherwise, returns `default`.
---@generic T, U
---@param value? T
---@param default U
---@return (T | U) - ?
function core.default(value, default)
    if value ~= nil then
        return value
    end

    return default
end

---Returns a deep copy of a table.
---@generic T : table | nil
---@param table T?
---@return T - ?
function core.deepcopy(table)
    return core._deepcopy(table or {}, {})
end

---Returns an entry table with the specified key and value.
---@generic K, V
---@param key K
---@param value V
---@return Entry<K, V>
function core.entry(key, value)
    return { key, value }
end

---Returns whether a string ends with another string.
---@param text string
---@param other string?
---@return boolean
function core.endsWith(text, other)
    if not other then
        return false
    elseif #other == 0 then
        return true
    end

    local len = #other
    return text:sub(-len) == other
end

---Returns text that's safe for use in a pattern.
---@param text string
---@return string
function core.escape(text)
    return (text:gsub('([[%]%+%-%*?().^$%%])', '%%%1'))
end

---Escapes a string for use in a rich text panel.
---@see RichTextPanel
---@see core.unescapeRichText
---@param text string
---@return string
function core.escapeRichText(text)
    return (text:gsub('<', '&lt;'):gsub('>', '&gt;'))
end

---Extends `t1` with members of the given tables.
---@generic T : table, U: table
---@param t1 T The table to add elements to.
---@param ...U The tables from which elements should be added.
---@return T + U t1
function core.extend(t1, ...)
    for i = 1, select('#', ...) do
        local t = select(i, ...)
        for k in pairs(t) do
            t1[k] = t[k]
        end
    end

    return t1
end

---Extends a shallow copy of `t1` with members of the given tables.
---@generic T : table, U: table
---@param t1 T? The table to copy and add elements to.
---@param ...U The tables from which elements should be added.
---@return (T + U) t1
function core.extendCopy(t1, ...)
    return core.extend(core.copy(t1), ...)
end

---Returns an table with only the values in `target` for which `predicate` is truthy.
---@generic T : table
---@param predicate fun(value: any, key: any): any? Predicate function.
---@param target T The table to filter.
---@return T
function core.filter(predicate, target)
    local filtered = {}
    for k, v in pairs(target) do
        if predicate(v, k) then
            filtered[k] = v
        end
    end

    return filtered
end

---Formats a message, stringifying arguments that are not numbers or strings.
---@param pattern string The string to format.
---@param ...any Format arguments.
---@return string
function core.format(pattern, ...)
    local args = {}
    local nArgs = select('#', ...)
    for i = 1, nArgs do
        local value = select(i, ...)
        local valueType = type(value)
        if valueType == 'number' or valueType == 'string' then
            args[i] = value
        else
            args[i] = tostring(value)
        end
    end

    if nArgs > 0 then
        pattern = pattern:format(unpack(args, 1, nArgs))
    end

    return pattern
end

---Returns a list of activated mod IDs, without the leading backslash.
---@return string[]
function core.getActivatedMods()
    if not core._activatedMods then
        core._getActivatedMods()
    end

    return core.copyList(core._activatedMods)
end

---Returns a set of activated mod IDs.
---@return SetTable<string>
function core.getActivatedModsSet()
    if not core._activatedModsSet then
        core._getActivatedMods()
    end

    return core.copy(core._activatedModsSet)
end

---Returns a list of activated mod IDs, each prefixed with a single backslash.
---@return string[]
function core.getActivatedModsQualified()
    if not core._activatedModsQualified then
        core._getActivatedMods()
    end

    return core.copyList(core._activatedModsQualified)
end

---Returns a set of activated mod IDs, each prefixed with a single backslash.
---@return SetTable<string>
function core.getActivatedModsQualifiedSet()
    if not core._activatedModsSetQualified then
        core._getActivatedMods()
    end

    return core.copy(core._activatedModsSetQualified)
end

---Returns a Field object given its name.
---@param obj any
---@param name string
---@return Field?
function core.getClassFieldByName(obj, name)
    for i = 0, getNumClassFields(obj) - 1 do
        local field = getClassField(obj, i)

        if tostring(field):match('([^%.]+)$') == name then
            return field
        end
    end
end

---Returns the value of a numeric character reference or character entity reference.
---If the value cannot be resolved, returns `nil`.
---@param entity string
---@return string?
function core.getEntityValue(entity)
    if entity:sub(1, 1) ~= '&' or entity:sub(#entity) ~= ';' then
        return
    end

    entity = entity:sub(2, #entity - 1)
    if entity:sub(1, 1) ~= '#' then
        return ISO8859_ENTITIES[entity]
    end

    local hex = entity:sub(2, 2) == 'x'
    local num = entity:sub(hex and 3 or 2)

    local value = tonumber(num, hex and 16 or 10)
    if not value then
        return
    end

    local success, chr = pcall(char, value)
    if not success then
        return
    end

    return chr
end

---Gets the line and column of an index in a string.
---@param str string The string to retrieve a line and column from.
---@param idx integer The string index.
---@return integer line
---@return integer column
function core.getLineAndColumn(str, idx)
    local line = 1
    local column = 1
    for i = 1, idx - 1 do
        column = column + 1
        if str:sub(i, i) == '\n' then
            line = line + 1
            column = 1
        end
    end

    return line, column
end

---Gets a player given their username.
---@param username string
---@return IsoPlayer?
function core.getPlayerByUsername(username)
    if not isServer() then
        return getPlayerFromUsername(username)
    end

    local onlinePlayers = getOnlinePlayers()
    for i = 0, onlinePlayers:size() - 1 do
        local player = onlinePlayers:get(i) --[[@as IsoPlayer]]
        if player:getUsername() == username then
            return player
        end
    end
end

---Returns whether a list contains an item by reference equality.
---@param list any[]
---@param item any
---@return boolean
function core.includes(list, item)
    for i = 1, #list do
        if list[i] == item then
            return true
        end
    end

    return false
end

---Traverses the metatable chain to determine whether an object is an instance of a class.
---@generic T
---@param obj unknown?
---@param cls T?
---@return TypeGuard<T>
function core.isinstance(obj, cls)
    if not cls or type(obj) ~= 'table' then
        return false
    end

    local seen = {}
    local meta = getmetatable(obj)
    while meta and not seen[meta] do
        if type(meta) ~= 'table' then
            return false
        end

        if rawget(meta, '__index') == cls then
            return true
        end

        seen[meta] = true
        meta = getmetatable(meta)
    end

    return false
end

---Checks whether a mod is activated.
---@param modID string The mod ID, without the workshop ID prefix.
---@return boolean
function core.isModActive(modID)
    if not core._activatedModsSet then
        core._getActivatedMods() ---@cast core._activatedModsSet -?
    end

    return core._activatedModsSet[modID] ~= nil
end

---Returns `true` if the given argument is `nil`, empty, or contains only whitespace.
---@param str string?
---@return boolean
function core.isNilOrWhitespace(str)
    return str == nil or str:match('^%s*$') ~= nil
end

---Returns an iterator which maps elements of a table to the return value of `func`.
---The iterator yields indices and mapped values.
---@generic T, K, V
---@param func fun(value: T): V Map function.
---@param target table<K, T>
---@return fun(): K?, V?
function core.iterMap(func, target)
    local key, value
    local iterator, state = pairs(target)
    return function()
        key, value = iterator(state, key) ---@diagnostic disable-line: redundant-parameter
        if value ~= nil then
            return key, func(value)
        end
    end
end

---Returns an iterator which maps elements of a table to the return value of `func`.
---The iterator yields only mapped values.
---@generic T, U
---@param func fun(value: T): U Map function.
---@param target table<any, T>
---@return fun(): T?
function core.iterMapValues(func, target)
    local key, value
    local iterator, state = pairs(target)
    return function()
        key, value = iterator(state, key) ---@diagnostic disable-line: redundant-parameter
        if value ~= nil then
            return func(value)
        end
    end
end

---Returns an iterator which maps elements in a list to the return value of `func`.
---The iterator yields indices and mapped values.
---@generic T, U
---@param func fun(value: T): U Map function.
---@param target T[] The list to map.
---@return fun(): integer?, U?
function core.iterMapList(func, target)
    local idx = 0
    local value
    return function()
        idx = idx + 1
        value = target[idx]
        if value ~= nil then
            return idx, func(value)
        end
    end
end

---Returns an iterator which maps elements in a list to the return value of `func`.
---The iterator yields only mapped values.
---@generic T, U
---@param func fun(value: T): U Map function.
---@param target T[] The list to map.
---@return fun(): U?
function core.iterMapListValues(func, target)
    local idx = 0
    local value
    return function()
        idx = idx + 1
        value = target[idx]
        if value ~= nil then
            return func(value)
        end
    end
end

---Returns table keys as a list.
---@generic T
---@param t table<T, any>
---@return T[]
function core.keys(t)
    local list = {}
    for k in pairs(t) do
        list[#list + 1] = k
    end

    return list
end

---Returns a table with all elements of `target` mapped to the return value of `func`.
---@generic T, K, V, A
---@param func fun(value: T, ...: A...): V Map function.
---@param target table<K, T> Table containing values to map.
---@param ... A... Additional arguments for the map function.
---@return table<K, V>
function core.map(func, target, ...)
    local mapped = {}
    for k, v in pairs(target) do
        mapped[k] = func(v, ...)
    end

    return mapped
end

---Returns a list with all items of `target` mapped to the return value of `func`.
---@generic T, U, A
---@param func fun(value: T, ...: A...): U Map function.
---@param target T[] List containing items to map.
---@param ... A... Additional arguments for the map function.
---@return U[]
function core.mapList(func, target, ...)
    local mapped = {}
    for i = 1, #target do
        mapped[i] = func(target[i], ...)
    end

    return mapped
end

---Helper for creating a new instance of a class.
---@generic A, T : Class
---@param cls T The class to create an instance of.
---@param cons? fun(cls: T, ...: A...): T The base class constructor.
---@param ... A... Arguments for the base class constructor.
---@return T
function core.new(cls, cons, ...)
    if cons then
        return cons(cls, ...)
    end

    return setmetatable({}, cls)
end

---Executes a callback on the next tick.
---@param callback function
function core.nextTick(callback)
    local listener ---@type function
    listener = function()
        Events.OnTick.Remove(listener)
        callback()
    end

    Events.OnTick.Add(listener)
end

---No-op function.
function core.noop() end

---Returns `true` if the given argument is not `nil`, not empty, and contains text that is not whitespace.
---@param str string?
---@return TypeGuard<string>
function core.notNilOrWhitespace(str)
    return str ~= nil and str:match('^%s*$') == nil
end

---Opens a URL.
---
---If the URL is on the allowlist, this opens it directly.
---Otherwise, it will use the Steam link filter URL.
---@param url string The URL to go to.
---@param inSteamOverlay boolean? Flag for whether the Steam overlay should be used if available.
function core.openUrl(url, inSteamOverlay)
    local isAllowed = URL_ALLOWLIST[url] or false
    if not isAllowed then
        for i = 1, #URL_ALLOWLIST_START do
            local compare = URL_ALLOWLIST_START[i]
            if url:sub(1, #compare) == compare then
                isAllowed = true
                break
            end
        end

        if not isAllowed then
            url = 'https://steamcommunity.com/linkfilter/?u=' .. url
        end
    end

    -- from Reifel's `Keep Stats Online`
    inSteamOverlay = inSteamOverlay and isSteamOverlayEnabled()
    if inSteamOverlay then
        activateSteamOverlayToWebPage(url)
    else
        openUrl(url)
    end
end

---Packs values from an iterator into a table.
---@generic T, U
---@param iterator function Key-value or value iterator function.
---@param ...any Iterator state.
---@return table
---@overload fun(iterator: (fun(...): T), ...): T[]
---@overload fun(iterator: (fun(...): T, U), ...): table<T, U>
function core.pack(iterator, ...)
    local isKV
    local packed = {}
    for k, v in iterator, ... do
        if isKV == nil then
            isKV = k ~= nil and v ~= nil
        end

        if isKV then
            packed[k] = v
        else
            packed[#packed + 1] = k
        end
    end

    return packed
end

---Packs values from an iterator into a table.
---@generic T
---@param iterator fun(...): T Value iterator function.
---@param ...any Iterator state.
---@return T[]
function core.packList(iterator, ...)
    local packed = {}
    for k in iterator, ... do
        packed[#packed + 1] = k
    end

    return packed
end

---Parses a unicode escape string.
---@param str string The string to parse.
---@param json boolean? Flag for whether a JSON unicode escape is expected. This accepts a surrogate pair.
---@param pos integer? The start position in the string. Defaults to `1`.
---@return string? parsed
---@return string? matchedEscape
function core.parseUnicodeEscape(str, json, pos)
    local hex
    if json then
        -- \uXXXX or \uXXXX\uXXXX
        hex = str:match('^\\u[dD][89aAbB]%x%x\\u[dD]%x%x%x', pos) or str:match('^\\u%x%x%x%x', pos)
    else
        -- \uXX, \uXXXX, \uXXXXXX
        hex = str:match('^\\[uU]%x%x?%x?%x?%x?%x?', pos)
    end

    if not hex then
        return
    end

    local n1 = tonumber(hex:sub(3, json and 6 or #hex), 16) ---@cast n1 -?
    local n2 = json and tonumber(hex:sub(9, 12), 16)
    if n2 then
        -- Surrogate pair (see http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa)
        local n = (n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000
        local p = char(floor(n / 262144) + 240, floor(n % 262144 / 4096) + 128, floor(n % 4096 / 64) + 128, n % 64 + 128)
        return p, hex
    end

    -- this is not typical unicode escape handling;
    -- Kahlua's `string.char` accepts arbitrarily large values,
    -- so \uFFFF is just char(0xFFFF)
    return char(n1), hex
end

---Returns a random integer in the given range.
---@param m integer The minimum value. If `n` is not given, this is an inclusive maximum and the minimum is 1.
---@param n integer? The maximum value.
---@return integer
function core.randInt(m, n)
    core._random = core._random or newrandom()

    if not n then
        return core._random:random(m)
    end

    return core._random:random(m, n)
end

---Replaces character entities with the characters that they represent.
---Numeric entities and named entities in ISO-8859-1 are supported.
---@param text string
---@return string
function core.replaceEntities(text)
    return (text:gsub('(&#?x?[%a%d]+;)', core._entityReplacer))
end

---Sets a function to be called every `interval` milliseconds.
---@param interval integer
---@param callback function
---@param ...any
---@return Timer
function core.setInterval(interval, callback, ...)
    return core._scheduler:setInterval(interval, callback, ...)
end

---Sets a function to be called on every UI update.
---This can only be used on the client.
---@param callback function
---@param ...any
---@return Timer
function core.setIntervalUI(callback, ...)
    return core._scheduler:setIntervalUI(callback, ...)
end

---Sets a function to be called after `delay` milliseconds.
---@param delay integer
---@param callback function
---@param ...any
---@return Timer
function core.setTimeout(delay, callback, ...)
    return core._scheduler:setTimeout(delay, callback, ...)
end

---Returns a portion of a list.
---@generic T
---@param tab T[] The table to return a slice of.
---@param i integer? The start index. Defaults to `1`.
---@param j integer? The stop index. Defaults to `#tab`.
---@return T[]
function core.slice(tab, i, j)
    return { unpack(tab, i or 1, j or #tab) }
end

---Splits a string based on a delimiter, ignoring empty values.
---This also trims split strings.
---@param str string The string to split.
---@param delimiter string? The delimiter to use. Defaults to `','`.
---@param list table? The table to include results in. This will be cleared if given.
---@return string[]
function core.split(str, delimiter, list)
    str:trim()

    if list then
        wipe(list)
    end

    list = list or {}
    delimiter = delimiter or ','

    local pos = 1
    while pos <= #str do
        local delimStart, delimEnd = str:find(delimiter, pos, true)

        local value
        if delimStart and delimEnd then
            value = str:sub(pos, delimStart - 1):trim()
            pos = delimEnd + 1
        else
            value = str:sub(pos):trim()
        end

        if value ~= '' then
            list[#list + 1] = value
        end

        if not delimStart then
            break
        end
    end

    return list
end

---Returns whether a string starts with another string.
---@param text string
---@param other string?
---@return boolean
function core.startsWith(text, other)
    if not other then
        return false
    end

    return text:sub(1, #other) == other
end

---Removes whitespace from either side of a string.
---@param text string
---@return string
function core.trim(text)
    return (text:gsub('^%s*(.-)%s*$', '%1'))
end

---Removes whitespace from the start of a string.
---@param text string
---@return string
function core.trimleft(text)
    return (text:gsub('^%s*(.*)', '%1'))
end

---Removes whitespace from the end of a string.
---@param text string
---@return string
function core.trimright(text)
    return (text:gsub('(.-)%s*$', '%1'))
end

---Reverses the operation of escaping text for use in a rich text panel.
---@see RichTextPanel
---@see core.escapeRichText
---@param text string
---@return string
function core.unescapeRichText(text)
    return (text:gsub('&lt;', '<'):gsub('&gt;', '>'))
end

---Returns table values as a list.
---@generic T
---@param t table<any, T>
---@return T[]
function core.values(t)
    local list = {}
    for _, v in pairs(t) do
        list[#list + 1] = v
    end

    return list
end

---Creates a deep copy of a table.
---@param table table
---@param seen table
---@return table
---@private
function core._deepcopy(table, seen)
    local dest = {}
    seen[table] = dest

    for k, v in pairs(table) do
        local key
        if type(k) ~= 'table' then
            key = k
        elseif seen[k] then
            key = seen[k]
        else
            key = core._deepcopy(k, seen)
        end

        if type(v) ~= 'table' then
            dest[key] = v
        elseif seen[v] then
            dest[key] = seen[v]
        else
            dest[key] = core._deepcopy(v, seen)
        end
    end

    return dest
end

---Replaces a character entity with the character it represents.
---On failure, returns the given string.
---@param entity string
---@return string
---@private
function core._entityReplacer(entity)
    return core.getEntityValue(entity) or entity
end

---Retrieves the list of activated mods and caches it.
---@private
function core._getActivatedMods()
    local modIdList = {}
    local modIdSet = {}
    local qualifiedList = {}
    local qualifiedSet = {}

    local activatedModArrayList = getActivatedMods()
    for i = 0, activatedModArrayList:size() - 1 do
        local id = activatedModArrayList:get(i)

        local modId = id:match('^%d*\\(.+)$')
        if modId then
            modIdSet[modId] = true
            modIdList[#modIdList + 1] = modId
        end

        qualifiedSet[id] = true
        qualifiedList[#qualifiedList + 1] = id
    end

    core._activatedMods = modIdList
    core._activatedModsSet = modIdSet
    core._activatedModsQualified = qualifiedList
    core._activatedModsSetQualified = qualifiedSet
end

core._getActivatedMods()
return core
