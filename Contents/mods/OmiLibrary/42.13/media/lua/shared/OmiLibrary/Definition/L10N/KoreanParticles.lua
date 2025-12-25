---Information about Korean particles to use for vowels and consonants.
---@namespace omi.l10n.korean
---@using omi.l10n

local char = string.char

---@type table<ParticleName, ParticleInfo>
local KR_PARTICLES = {
    -- '와', '과', '과/와'
    gwa = {
        type = 'gwa',
        vowel = char(50752),
        consonant = char(44284),
        other = char(44284, 47, 50752),
    },

    -- '랑', '이랑', '(이)랑'
    irang = {
        type = 'irang',
        vowel = char(46993),
        consonant = char(51060),
        other = char(40, 51060, 41, 46993),
    },

    -- '로', '으로', '(으)로'
    ro = {
        type = 'ro',
        vowel = char(47196),
        consonant = char(51004, 47196),
        other = char(40, 51004, 41, 47196),
    },

    -- '를', '을', '을(를)',
    object = {
        type = 'object',
        vowel = char(47484),
        consonant = char(51012),
        other = char(40, 51012, 41, 47484),
    },

    -- '가', '이', '이/가',
    subject = {
        type = 'subject',
        vowel = char(44032),
        consonant = char(51060),
        other = char(51060, 47, 44032),
    },

    -- '는', '은', '은(는)',
    topic = {
        type = 'topic',
        vowel = char(45716),
        consonant = char(51008),
        other = char(51008, 40, 45716, 41),
    },

    -- '야', '아', '아/야',
    ya = {
        type = 'ya',
        vowel = char(50556),
        consonant = char(50500),
        other = char(50500, 47, 50556),
    },
}

KR_PARTICLES.obj = KR_PARTICLES.object
KR_PARTICLES.subj = KR_PARTICLES.subject


return KR_PARTICLES

--#region Type Definitions

---@class ParticleInfo
---@field type ParticleType The type of particle described by the object.
---@field vowel string The particle to use when the preceding character is a vowel.
---@field consonant string The particle to use when the preceding character is a consonant.
---@field other string The string to use when uncertain whether the preceding character is a vowel or consonant.

---@alias ParticleType
---| 'ro'
---| 'gwa'
---| 'irang'
---| 'ya'
---| 'topic'
---| 'object'
---| 'subject'

---@alias ParticleName
---| ParticleType
---| 'obj'
---| 'subj'

--#endregion
