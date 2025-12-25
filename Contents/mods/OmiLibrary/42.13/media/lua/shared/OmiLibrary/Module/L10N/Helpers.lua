---Helper functions for localization.
---@namespace omi

local VOWELS_UPPER = require 'OmiLibrary/Definition/L10N/UpperVowels'

local Helpers = {}

local PHONETIC_HEURISTICS = {
    Y = true,    -- "may" → vowel
    OW = true,   -- "now" → vowel
    RH = true,   -- "myrrh" → vowel
    ANE = false, -- "Jane" → consonant
    INE = false, -- "wine" → consonant
    UDE = false, -- "dude" → consonant
    UGE = false, -- "huge" → consonant
}


---Extracts the primary language subtag from a basic BCP 47 language tag.
---This assumes the subtag includes the primary language subtag first (i.e., is not irregular or private-use).
---@param locale string
---@return string languageCode
function Helpers.extractLanguage(locale)
    local dash = locale:find('-', 1, true)
    if not dash then
        return locale
    end

    return locale:sub(1, dash - 1)
end

---Checks whether a character in a Latin-based script is a vowel, consonant, or indeterminate.
---@param c string The character to check.
---@param options Args.IsVowel? Options for resolution.
---@return boolean? isVowel Flag for whether the character is a vowel. If indeterminate, this is `nil`.
function Helpers.isVowelLatin(c, options)
    c = c:upper()

    -- special case: treat Y as a vowel at the end, indeterminate otherwise
    local pos = options and options.position or 'end'
    if c == 'Y' then
        return pos == 'end' or nil
    end

    if options and options.phonetic and options.full then
        local match, result = Helpers.matchVowelPhonetic(options.full)
        if match then
            return result
        end
    end

    -- vowel (basic & extended Latin)
    if VOWELS_UPPER[c] then
        return true
    end

    -- non-vowel A-Z → consonant, otherwise indeterminate
    local code = c:byte()
    if code >= 65 and code <= 90 then
        return false
    end
end

---Checks whether the input matches heuristics for English spelling-to-sound correspondences
---to determine whether to treat it as a vowel for phonetic determination.
---
---For example, "Jane", "wine", and "huge" are treated as ending with a consonantal sound,
---whereas "now" and "say" are treated as ending with a vowel sound.
---@param input string The input to check.
---@return boolean isMatch Flag for whether the result should be used.
---@return boolean? isVowel Flag for whether the input is a vowel, or `nil` for indeterminate.
function Helpers.matchVowelPhonetic(input)
    input = input:upper()

    if input:sub(-1) == 'H' then
        local c = input:sub(-2, -2)
        if c ~= '' and Helpers.isVowelLatin(c, { phonetic = true }) then
            -- ah, eh, oh, etc. → vowel
            return true, true
        end

        if input:sub(-4) == 'OUGH' then
            -- indeterminate (e.g., though → vowel, but tough → consonant)
            return true
        end
    end

    for i = -3, -1 do
        local value = PHONETIC_HEURISTICS[input:sub(i)]
        if value ~= nil then
            return true, value
        end
    end

    return false
end

return Helpers
