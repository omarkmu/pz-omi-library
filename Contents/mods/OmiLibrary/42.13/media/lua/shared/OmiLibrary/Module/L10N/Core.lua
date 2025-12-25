---Core localization utilities.
---@namespace omi
---@using omi.l10n

local core = require 'OmiLibrary/Module/Utils'
local Helpers = require 'OmiLibrary/Module/L10N/Helpers'
local PluralRules = require 'OmiLibrary/Component/L10N/PluralRules'

-- abbreviated month, day, hour, minute, second, year
local PATT_DATE = '^%w+ (%w+) (%d+) (%d+):(%d+):(%d+) .- (%d+)$'

-- year, month, day, hour, minute, second
local PATT_LOCAL_DATETIME = '^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)%.%d+$'

local MONTH_TO_NUM = {
    Jan = 1,
    Feb = 2,
    Mar = 3,
    Apr = 4,
    May = 5,
    Jun = 6,
    Jul = 7,
    Aug = 8,
    Sep = 9,
    Oct = 10,
    Nov = 11,
    Dec = 12,
}

---@class l10n.core
---@field protected _calendar PZCalendar Shared calendar instance.
---This is used for various Date operations and isn't guaranteed to reflect a particular date.
local L10N = {}

---Contains localization utilities for Korean.
L10N.korean = require 'OmiLibrary/Module/L10N/Korean'

---Associates game languages that are not already valid BCP 47 language tags
---(or do not match the expected language) to the expected tag for the locale.
---
---This may be extended in the future to include modded languages.
---@protected
L10N._correctedLocaleTags = {
    AR = 'es-AR',
    CH = 'zh-Hant',
    CN = 'zh-Hans',
    JP = 'ja',
    PH = 'tl',
    UA = 'uk',
    PTBR = 'pt-BR',
}

---The current game language.
---@protected
---@readonly
L10N._language = Translator.getLanguage()

L10N.extractLanguage = Helpers.extractLanguage


---Converts a timestamp (in milliseconds) to a Date.
---@param timestamp number
---@return Date
function L10N.dateFromTimestamp(timestamp)
    local cal = L10N._getCalendar()
    cal:setTimeInMillis(timestamp --[[@as integer]])

    return cal:getTime()
end

---Converts a LocalDateTime to a Date.
---This only has accuracy up to the level of seconds.
---@param datetime LocalDateTime
---@return Date
function L10N.dateFromLocalDateTime(datetime)
    return L10N.dateFromTimestamp(L10N.dateToTimestamp(datetime))
end

---Converts a Date object to a timestamp in milliseconds.
---This only has accuracy up to the level of seconds.
---@param date Date | LocalDateTime
---@return integer
function L10N.dateToTimestamp(date)
    local str = tostring(date)

    -- if this seems weird, it's because it is
    -- the game sets the default locale to ROOT on startup (see LocaleManager.initialise),
    -- so the format for these is always consistent — which means we can parse it for the date components
    local month
    local abbrMonth, day, hour, minute, second, year = str:match(PATT_DATE) --[[@as any]]
    if abbrMonth then
        month = MONTH_TO_NUM[abbrMonth]
    else
        year, month, day, hour, minute, second = str:match(PATT_LOCAL_DATETIME)
    end

    if not year or not month or not day or not hour or not minute or not second then
        error('expected a Date or LocalDateTime')
    end

    month = core.tointeger(month) --[[@as integer]]
    year = core.tointeger(year) --[[@as integer]]
    day = core.tointeger(day) --[[@as integer]]
    hour = core.tointeger(hour) --[[@as integer]]
    minute = core.tointeger(minute) --[[@as integer]]
    second = core.tointeger(second) --[[@as integer]]

    local cal = L10N._getCalendar()
    cal:set(year, month - 1, day, hour, minute)

    -- PZCalendar's set method does not accept seconds,
    -- so we have to subtract the seconds and add the proper seconds
    -- no way to retain the milliseconds, as far as I can tell
    local timestamp = cal:getTimeInMillis()
    return timestamp - (timestamp % 60000) + second * 1000
end

---Gets the BCP 47 language tag to use for the given game language.
---@param language string? The language name to convert. Defaults to the current game language.
---@return string localeTag
function L10N.gameLanguageToLocaleTag(language)
    language = language or L10N._language:name()
    return L10N._correctedLocaleTags[language] or language:lower()
end

---Gets the locale name for the current game language.
---@return string
function L10N.getLocaleTag()
    return L10N._localeTag
end

---Checks whether an object is a Date object.
---
---This matches on the object's stringified form,
---so if an object stringifies identically to a Date it may cause false positives.
---@param obj any
---@return TypeGuard<Date>
function L10N.isDate(obj)
    if type(obj) ~= 'userdata' then
        return false
    end

    local str = tostring(obj)
    if str:match(PATT_DATE) then
        return true
    end

    return false
end

---Checks whether an object is a Date or LocalDateTime object.
---
---This matches on the object's stringified form,
---so if an object stringifies identically to a Date or LocalDateTime it may cause false positives.
---@param obj any
---@return TypeGuard<Date | LocalDateTime>
function L10N.isDateLike(obj)
    if type(obj) ~= 'userdata' then
        return false
    end

    local str = tostring(obj)
    if str:match(PATT_DATE) then
        return true
    end

    if str:match(PATT_LOCAL_DATETIME) then
        return true
    end

    return false
end

---Checks whether an object is a LocalDateTime object.
---
---This matches on the object's stringified form,
---so if an object stringifies identically to a LocalDateTime it may cause false positives.
---@param obj any
---@return TypeGuard<LocalDateTime>
function L10N.isLocalDateTime(obj)
    if type(obj) ~= 'userdata' then
        return false
    end

    local str = tostring(obj)
    if str:match(PATT_LOCAL_DATETIME) then
        return true
    end

    return false
end

---Checks whether a character is a vowel, a consonant, or indeterminate.
---@param c string The character to check.
---@param options Args.IsVowel.WithLocale? Options for resolution.
---@return boolean? isVowel Flag for whether the character is a vowel. If indeterminate, this is `nil`.
function L10N.isVowel(c, options)
    if c == '' then
        return
    end

    options = options or {} --[[@as Args.IsVowel.WithLocale]]
    local locale = options.locale and L10N.extractLanguage(options.locale) or 'en'
    if locale == 'ko' then
        return L10N.korean.isVowel(c, options)
    end

    return Helpers.isVowelLatin(c, options)
end

---Gets the plural category to use for a number.
---@param n number The number to check.
---@param locale string The locale name.
---@param pluralType PluralRuleType? The type of plural to retrieve. Defaults to `cardinal`.
---@return PluralCategory category
function L10N.selectPlural(n, locale, pluralType)
    return PluralRules.fromOptions({ locale = locale, type = pluralType }):select(n)
end

---Gets the Locale object that represents a locale tag.
---@param tag string A BCP 47 language tag.
---@return Locale
function L10N.tagToLocale(tag)
    return Locale.forLanguageTag(tag)
end


---Gets or creates the shared calendar instance.
---@return PZCalendar
---@protected
function L10N._getCalendar()
    if L10N._calendar then
        return L10N._calendar
    end

    L10N._calendar = Calendar.getInstance()
    return L10N._calendar
end


---The language tag for the current locale, based on the current game language.
---@protected
---@readonly
L10N._localeTag = L10N.gameLanguageToLocaleTag()


return L10N

--#region Type Definitions

---@class Args.IsVowel
---@field phonetic boolean? Flag for whether phonetic matching should be used. Defaults to `false`.
---
---For details on phonetic matching, see `L10N/Helpers.matchVowelPhonetic`.
---@field full string? The full input text, for phonetic matching.
---@field position ('start' | 'middle' | 'end')? The position of the character in a word, for phonetic matching. Defaults to `'end'`.
---@field koreanNumeralSystem ('sino' | 'native')? The type of numerals to use for Korean.
---
---If this is not specified, numerals will be considered indeterminate.
---Ignored for locales other than `ko`.
---@field koreanParticle korean.ParticleType? The type of particle to consider for resolution.
---
---If `position` is `'end'` and this indicates that the particle is 로, 리을 will be treated as a vowel.
---Ignored for locales other than `ko`.

---@class Args.IsVowel.WithLocale : Args.IsVowel
---@field locale string? The locale to use for checking. Defaults to `en`.
---
---Currently, this really only supports `en` and `ko`.
---Other locales will look for Latin vowels, like `en` does.

--#endregion
