---Information used for formatting datetimes.
---@namespace omi.l10n

local getCLDRData = require 'OmiLibrary/Definition/Generated/CLDRDateTimeData'

local Data = {}

---@type table<string, DateTimeFormats>
---Associates language tags to data time format tables.
Data.formats = {}

do
    local cldrData = getCLDRData()
    for i = 1, #cldrData do
        local data = cldrData[i]
        local formats = {
            dateFormats = data.dateFormats,
            timeFormats = data.timeFormats,
            dateTimeFormats = data.dateTimeFormats,
        }

        for j = 1, #data.locales do
            local locale = data.locales[j] --[[@as string]]
            Data.formats[locale] = formats
        end
    end
end

return Data

--#region Type Definitions

---@alias DateTimeFormatStyle
---| 'full'
---| 'long'
---| 'medium'
---| 'short'

---@class DateTimeFormatTable
---@field full string
---@field long string
---@field medium string
---@field short string

---@class DateTimeFormats
---@field dateFormats DateTimeFormatTable
---@field timeFormats DateTimeFormatTable
---@field dateTimeFormats DateTimeFormatTable

--#endregion
