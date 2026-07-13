---Handler for formatting dates and times (and datetimes).
---@namespace omi.l10n
---@using omi

local core = require 'OmiLibrary/Module/Utils'
local Helpers = require 'OmiLibrary/Module/L10N/Helpers'
local DATETIME = require 'OmiLibrary/Definition/L10N/CLDRDateTime'

local concat = table.concat
local getLocale = Locale.forLanguageTag

local VALID_STYLES = {
    full = true,
    long = true,
    medium = true,
    short = true,
}

---@class DateTimeFormat : Class
---@field private _locale string The language tag for the locale to use.
---@field private _formatter SimpleDateFormat The internal formatter to use.
local DateTimeFormat = core.class('DateTimeFormat')

---Cache for memoizing DateTimeFormat objects.
---@type table<string, DateTimeFormat>
---@protected
DateTimeFormat._memo = {}

---Cache for SimpleDateFormat objects.
---@type table<string, SimpleDateFormat>
---@protected
DateTimeFormat._sdfMemo = {}

---Gets a cached DateTimeFormat object for the given options,
---creating one if it doesn't exist.
---@param options Args.DateTimeFormat
---@return DateTimeFormat
function DateTimeFormat.fromOptions(options)
    local locale = options.locale
    local dateStyle = options.dateStyle or ''
    local timeStyle = options.timeStyle or ''

    local key = concat({ locale:lower(), dateStyle, timeStyle }, '_')

    local format = DateTimeFormat._memo[key]
    if not format then
        format = DateTimeFormat:new(options)
        DateTimeFormat._memo[key] = format
    end

    return format
end

---Formats a date according to the configured format.
---@param date Date
---@return string
function DateTimeFormat:format(date)
    local formatter = self._formatter --[[@as DateFormat]]
    return formatter:format(date)
end

---Creates a new DateTimeFormat instance.
---Using `DateTimeFormat.fromOptions` should be preferred.
---@see DateTimeFormat.fromOptions
---@param options Args.DateTimeFormat Options for creation of the instance.
---@return DateTimeFormat
function DateTimeFormat:new(options)
    local this = core.new(self)
    local localeTag = options.locale
    local timeStyle = options.timeStyle
    local dateStyle = options.dateStyle or (not timeStyle and 'short' or nil)

    if dateStyle and not VALID_STYLES[dateStyle] then
        error('Expected one of "full", "long", "medium", or "short" for dateStyle')
    end

    if timeStyle and not VALID_STYLES[timeStyle] then
        error('Expected one of "full", "long", "medium", or "short" for timeStyle')
    end

    this._locale = localeTag
    localeTag = localeTag:lower()

    local formats = DATETIME.formats[localeTag]
    if not formats then
        local lang = Helpers.extractLanguage(localeTag)
        formats = DATETIME.formats[lang] or DATETIME.formats.en
    end

    local datePattern = dateStyle and formats.dateFormats[dateStyle]
    local timePattern = timeStyle and formats.timeFormats[timeStyle]

    local pattern
    if datePattern and timePattern then
        local dateTimePattern = formats.dateTimeFormats[dateStyle] or '{1}, {0}'
        pattern = dateTimePattern:gsub('{0}', timePattern):gsub('{1}', datePattern)
    else
        pattern = datePattern or timePattern
    end

    assert(pattern, 'Expected pattern to be initialized')

    local sdfKey = localeTag .. '_' .. pattern
    local sdf = DateTimeFormat._sdfMemo[sdfKey]
    if not sdf then
        sdf = SimpleDateFormat.new(pattern, getLocale(localeTag))
        DateTimeFormat._sdfMemo[sdfKey] = sdf
    end

    this._formatter = sdf

    return this
end


return DateTimeFormat


--#region Type Definitions

---@class Args.DateTimeFormat
---@field locale string A BCP 47 language tag.
---@field dateStyle? DateTimeFormatStyle The style for the date. Defaults to `short` if `timeStyle` is not given.
---@field timeStyle? DateTimeFormatStyle The style for the time.

--#endregion
