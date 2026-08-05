---Built-in fluent functions.
---@namespace omi
---@using omi.l10n
---@using omi.l10n.fluent

local core = require 'OmiLibrary/Module/Utils'
local l10n = require 'OmiLibrary/Module/Core/L10N'
local FluentNone = require 'OmiLibrary/Component/L10N/FluentTypes/None'
local FluentNumber = require 'OmiLibrary/Component/L10N/FluentTypes/Number'
local FluentDateTime = require 'OmiLibrary/Component/L10N/FluentTypes/DateTime'
local KR_PARTICLES = require 'OmiLibrary/Definition/L10N/KoreanParticles'

local type = type
local pairs = pairs
local getText = getText
local tostring = tostring
local unpack = unpack
local getTextOrNull = getTextOrNull

---@class l10n.builtins
local BuiltIn = {}

---Container for built-in functions.
---@type table<string, FluentFunction>
BuiltIn.functions = {}

local FUNCTION = BuiltIn.functions

local DATETIME_ALLOWED = {
    dateStyle = true,
    timeStyle = true,
}

local NUMBER_ALLOWED = {
    minimumFractionDigits = true,
    maximumFractionDigits = true,
}


---Gets the Korean particle for an input value.
---@param name string The function name.
---@param args FluentValue[] Positional arguments.
---@param opts table<string, FluentValue?> Named arguments.
---@return FluentValue value
---@return string? error
---@private
function BuiltIn._getKrParticle(name, args, opts)
    local input = args[1]
    if not input then
        return FluentNone:new(), 'Invalid argument to ' .. name
    end

    local system = opts.numeral and tostring(opts.numeral):lower() or nil
    if system and system ~= 'sino' and system ~= 'native' then
        return FluentNone:new(), 'Invalid numeral argument to ' .. name
    end

    local targetType = (opts.type and tostring(opts.type):lower() or nil) --[[@as korean.ParticleName?]]
    local particleInfo = targetType and KR_PARTICLES[targetType]
    if targetType and not particleInfo then
        return FluentNone:new(), 'Invalid type argument to ' .. name
    end

    local options = {} ---@type string[]
    for i = 2, 4 do
        local value = args[i]
        if not value then
            break
        end

        options[#options + 1] = tostring(value)
    end

    local particleType = particleInfo and particleInfo.type
    if particleInfo then
        options[1] = options[1] or particleInfo.vowel
        options[2] = options[2] or particleInfo.consonant
        options[3] = options[3] or particleInfo.other
    elseif #options == 0 then
        return FluentNone:new(), 'Expected at least one particle argument for ' .. name
    end

    input = tostring(input):gsub('%p$', ''):trim() -- ignore trailing punctuation
    local c = input:sub(-1)

    local isVowel = l10n.isVowel(c, {
        locale = 'ko',
        phonetic = true,
        full = input,
        koreanNumeralSystem = system,
        koreanParticleType = particleType,
    })

    -- true → 1, false → 2, nil → 3
    local targetIdx = (isVowel == nil) and 3 or (isVowel and 1 or 2)

    return (options[targetIdx] or options[#options]) --[[@as string]]
end

---Filters options to only include those included in a set.
---Also, unwraps values to their internal value.
---@param base table?
---@param opts table<string, FluentValue?>
---@param allowSet SetTable<string>
---@return table
---@private
function BuiltIn._values(base, opts, allowSet)
    local result = {}

    if base then
        for k, v in pairs(base) do
            result[k] = v
        end
    end

    for k, v in pairs(opts) do
        if allowSet[k] then
            result[k] = type(v) == 'string' and v or v.value
        end
    end

    return result
end


---The `DATETIME()` builtin.
---This is not currently supported.
---@param args FluentValue[] Positional arguments.
---@param opts table<string, FluentValue> Named arguments.
---@return FluentValue value
---@return string? error
---@diagnostic disable-next-line: unused
function FUNCTION.DATETIME(args, opts)
    local argument = args[1]

    if core.isinstance(argument, FluentNone) then
        return FluentNone:new('DATETIME(' .. argument.value .. ')')
    end

    if core.isinstance(argument, FluentNumber) then
        return FluentDateTime:new(argument.value, BuiltIn._values(nil, opts, DATETIME_ALLOWED))
    end

    if core.isinstance(argument, FluentDateTime) then
        return FluentDateTime:new(argument.value, BuiltIn._values(argument.options, opts, DATETIME_ALLOWED))
    end

    return FluentNone:new(), 'Invalid argument to DATETIME'
end

---The `GETTEXT()` builtin.
---This can be used to reference a string defined in PZ translation files.
---@param args FluentValue[] Positional arguments.
---@param opts table<string, FluentValue?> Named arguments.
---@return FluentValue value
---@return string? error
function FUNCTION.GETTEXT(args, opts)
    local id = args[1]

    if not id then
        return FluentNone:new(), 'Invalid argument to GETTEXT'
    end

    if type(id) ~= 'string' then
        return FluentNone:new('GETTEXT(' .. id.value .. ')')
    end

    local unwrapped = {}
    for i = 2, #args do
        unwrapped[i - 1] = tostring(args[i])
    end

    local default = opts.default
    if default then
        return getTextOrNull(id, unpack(unwrapped)) or default
    end

    return getText(id, unpack(unwrapped))
end

---The `KO_PARTICLE()` builtin.
---This can be used to choose a Korean particle based on whether
---the first argument ends with a vowel or consonant.
---@param args FluentValue[] Positional arguments.
---@param opts table<string, FluentValue> Named arguments.
---@return FluentValue value
---@return string? error
function FUNCTION.KO_PARTICLE(args, opts)
    return BuiltIn._getKrParticle('KO_PARTICLE', args, opts)
end

---The `KO_WITH_PARTICLE()` builtin.
---This can be used to choose a Korean particle based on whether
---the first argument ends with a vowel or consonant.
---
---This is the same as `KO_PARTICLE`, but includes the input before the particle.
---@param args FluentValue[] Positional arguments.
---@param opts table<string, FluentValue> Named arguments.
---@return FluentValue value
---@return string? error
function FUNCTION.KO_WITH_PARTICLE(args, opts)
    local result, err = BuiltIn._getKrParticle('KO_WITH_PARTICLE', args, opts)
    if core.isinstance(result, FluentNone) then
        return result, err
    end

    local prefix = ''
    local suffix = ''

    if opts.wrap then
        prefix = tostring(opts.wrap)
        suffix = prefix
    else
        if opts.prefix then
            prefix = tostring(opts.prefix)
        end

        if opts.suffix then
            suffix = tostring(opts.suffix)
        end
    end

    return prefix .. tostring(args[1]) .. suffix .. tostring(result)
end

---The `NUMBER()` builtin.
---This can be used to specify formatting options for numbers.
---@param args FluentValue[] Positional arguments.
---@param opts table<string, FluentValue> Named arguments.
---@return FluentValue value
---@return string? error
function FUNCTION.NUMBER(args, opts)
    local argument = args[1]

    if core.isinstance(argument, FluentNone) then
        return FluentNone:new('NUMBER(' .. argument.value .. ')')
    end

    if core.isinstance(argument, FluentNumber) then
        return FluentNumber:new(argument.value, BuiltIn._values(argument.options, opts, NUMBER_ALLOWED))
    end

    return FluentNone:new(), 'Invalid argument to NUMBER'
end


return BuiltIn
