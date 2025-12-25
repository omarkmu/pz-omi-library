---Localization utilities specific to Korean.
---@namespace omi.l10n
---@using omi

local Helpers = require 'OmiLibrary/Module/L10N/Helpers'

---@class korean
local Korean = {}

local type = type
local tonumber = tonumber
local SYLLABLE_START = 44032
local SYLLABLE_END = 55203

local KR_NUM_VOWELS_SINO = {
    [2] = true,
    [4] = true,
    [5] = true,
    [9] = true,
}

---Constants representing final consonants in Korean syllable blocks.
---@enum korean.Final
Korean.Final = {
    -- No final consonant.
    NONE = 0,

    -- Represents the final consonant `ㄱ`.
    GIYEOK = 1,

    -- Represents the final consonant `ㄲ`.
    SSANG_GIYEOK = 2,

    -- Represents the final consonant `ㄳ`.
    CLUSTER_GIYEOK_SIOT = 3,

    -- Represents the final consonant `ㄴ`.
    NIEUN = 4,

    -- Represents the final consonant `ㄵ`.
    CLUSTER_NIEUN_JIEUT = 5,

    -- Represents the final consonant `ㄶ`.
    CLUSTER_NIEUN_HIEUT = 6,

    -- Represents the final consonant `ㄷ`.
    DIGEUT = 7,

    -- Represents the final consonant `ㄹ`.
    RIEUL = 8,

    -- Represents the final consonant `ㄺ`.
    CLUSTER_RIUEL_GIYEOK = 9,

    -- Represents the final consonant `ㄻ`.
    CLUSTER_RIEUL_MIEUM = 10,

    -- Represents the final consonant `ㄼ`.
    CLUSTER_RIEUL_BIEUP = 11,

    -- Represents the final consonant `ㄽ`.
    CLUSTER_RIEUL_SIOT = 12,

    -- Represents the final consonant `ㄾ`.
    CLUSTER_RIEUL_TIEUT = 13,

    -- Represents the final consonant `ㄿ`.
    CLUSTER_RIEUL_PIEUP = 14,

    -- Represents the final consonant `ㅀ`.
    CLUSTER_RIEUL_HIEUT = 15,

    -- Represents the final consonant `ㅁ`.
    MIEUM = 16,

    -- Represents the final consonant `ㅂ`.
    BIEUP = 17,

    -- Represents the final consonant `ㅄ`.
    CLUSTER_BIEUP_SIOT = 18,

    -- Represents the final consonant `ㅅ`.
    SIOT = 19,

    -- Represents the final consonant `ㅆ`.
    SSANG_SIOT = 20,

    -- Represents the final consonant `ㅇ`.
    IEUNG = 21,

    -- Represents the final consonant `ㅈ`.
    JIEUT = 22,

    -- Represents the final consonant `ㅊ`.
    CHIEUT = 23,

    -- Represents the final consonant `ㅋ`.
    KIEUK = 24,

    -- Represents the final consonant `ㅌ`.
    TIEUT = 25,

    -- Represents the final consonant `ㅍ`.
    PIEUP = 26,

    -- Represents the final consonant `ㅎ`.
    HIEUT = 27,
}

---Gets a value representing a final consonant for a Korean syllable character.
---If the character is not a Korean syllable, returns `nil`.
---@param c string | integer The character to check, or its character code.
---@return korean.Final? index
function Korean.getFinal(c)
    if type(c) ~= 'number' then
        c = c:byte()
    end

    if c < SYLLABLE_START or c > SYLLABLE_END then
        return
    end

    return (c - SYLLABLE_START) % 28
end

---Determines whether a Korean number should be treated as a vowel.
---@param value number The value to check.
---@param system 'sino' | 'native' The numeral system to use.
---@return boolean isVowel
function Korean.isNumberVowel(value, system)
    local onesPlace = value % 10
    if system == 'sino' then
        -- numbers ending in 2, 4, 5, and 9 should be treated as vowels
        -- assuming value < 10^12, everything else is a consonant
        return KR_NUM_VOWELS_SINO[onesPlace] or false
    end

    -- native numbers ending with 1 are vowels
    return onesPlace == 1
end

---Checks whether a character is a Korean syllable.
---@param c string | integer The character to check, or its character code.
---@return boolean
function Korean.isSyllable(c)
    if type(c) ~= 'number' then
        c = c:byte()
    end

    return c >= SYLLABLE_START and c <= SYLLABLE_END
end

---Checks whether a character should be considered a vowel using Korean rules.
---Returns `nil` for indeterminate.
---@param c string The character to check.
---@param options Args.IsVowel? Options for resolution.
---@return boolean?
function Korean.isVowel(c, options)
    options = options or {} --[[@as Args.IsVowel]]

    local pos = options.position or 'end'

    local final
    if options.koreanParticle == 'ro' then
        final = Korean.getFinal(c)
        if final == Korean.Final.RIEUL then
            -- special case: always treat final 리을 as vowel for 로
            return true
        end
    end

    local match, result
    local system = options.koreanNumeralSystem
    if options.phonetic then
        if pos == 'end' and c:upper() == 'R' then
            -- special case: treat R as a vowel (typically maps to 러 or 르)
            return true
        end

        match, result = Korean.matchVowelNumeral(c, system)
        if match then
            return result
        end
    end

    result = Helpers.isVowelLatin(c, options)
    if result ~= nil then
        return result
    end

    if Korean.isSyllable(c) then
        final = final or Korean.getFinal(c)
        return final == Korean.Final.NONE
    end
end

---Checks whether input is a numeral, then matches the final value of the numeral as a word.
---@param input string The input string to check.
---@param system ('sino' | 'native')? The numeral system to use. If not given, numerals are indeterminate.
---@return boolean isMatch Flag for whether the result should be used.
---@return boolean? isVowel Flag for whether the input is a vowel, or `nil` for indeterminate.
function Korean.matchVowelNumeral(input, system)
    input = input:gsub('[%.$-, ]', '') -- get numeral without separators
    local value = tonumber(input)
    if not value then
        return false
    end

    if not system then
        return true
    end

    return true, Korean.isNumberVowel(value, system)
end


return Korean
