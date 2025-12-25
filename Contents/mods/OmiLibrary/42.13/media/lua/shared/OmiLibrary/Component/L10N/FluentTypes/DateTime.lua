---Fluent type representing a datetime.
---@namespace omi.l10n
---@using omi
---@using omi.l10n.fluent

local core = require 'OmiLibrary/Module/Utils'
local l10n = require 'OmiLibrary/Module/L10N/Core'
local FluentType = require 'OmiLibrary/Component/L10N/FluentTypes/Type'
local DateTimeFormat = require 'OmiLibrary/Component/L10N/DateTimeFormat'

---@class FluentDateTime : FluentType<Date>
---@field options FluentDateTimeOptions? Options for formatting the value.
---@field dateStyle? DateTimeFormatStyle The style to use for date formatting.
---@field timeStyle? DateTimeFormatStyle The style to use for time formatting.
local FluentDateTime = FluentType:derive('FluentDateTime')

---Format function for converting the datetime into a string.
---@return string
function FluentDateTime:convert()
    local formatter = DateTimeFormat.fromOptions({
        locale = l10n.getLocaleTag(),
        dateStyle = self.dateStyle,
        timeStyle = self.timeStyle,
    })

    return formatter:format(self.value)
end

---Converts the date value into a timestamp.
---@return integer
function FluentDateTime:toNumber()
    return l10n.dateToTimestamp(self.value)
end

---Creates an instance of `FluentDateTime` with the given value.
---@param value number | Date | LocalDateTime The internal value.
---@param options FluentDateTimeOptions? Options for formatting the value.
---@return FluentDateTime
function FluentDateTime:new(value, options)
    local this = core.new(self, FluentType.new, value)

    this.options = options

    if type(value) == 'number' then
        this.value = l10n.dateFromTimestamp(value)
    elseif l10n.isLocalDateTime(value) then
        this.value = l10n.dateFromLocalDateTime(value)
    else
        this.value = value
    end

    this.dateStyle = options and options.dateStyle
    this.timeStyle = options and options.timeStyle

    return this
end


return FluentDateTime

--#region Type Definitions

---@class FluentDateTimeOptions : DateTimeFormatOptions

--#endregion
