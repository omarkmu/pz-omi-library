---Contains tests for the L10N.korean module.
---@using omi.l10n

local korean = require 'OmiLibrary/Module/L10N/Korean'
local Helpers = require 'OmiLibrary/Module/L10N/Helpers'

describe('#module l10n.korean #function', function()
    describe('getFinal', function()
        theory('returns nil for characters that are not Korean syllables', function(value)
            assert.is_nil(korean.getFinal(value))
        end, 'a', 'b', 'z', '1', '.', '_')

        theory('returns the expected value for Korean syllables', function(args)
            assert.equal(args.expected, korean.getFinal(args.value))
        end, {
            { expected = korean.Final.NONE, value = 44032 },                 -- 가
            { expected = korean.Final.BIEUP, value = 48165 },                -- 밥
            { expected = korean.Final.CLUSTER_RIUEL_GIYEOK, value = 45805 }, -- 닭
            { expected = korean.Final.HIEUT, value = 55203 },                -- 힣
        })
    end)

    describe('isNumberVowel', function()
        theory('returns true for Sino-Korean numbers that should be treated as vowels', function(value)
            assert.is_true(korean.isNumberVowel(value, 'sino'))
        end, {
            2,
            4,
            5,
            9,
            12,
            54,
            1005,
            60019,
        })

        theory('returns false for Sino-Korean numbers that should not be treated as vowels', function(value)
            assert.is_false(korean.isNumberVowel(value, 'sino'))
        end, {
            0,
            1,
            3,
            6,
            7,
            8,
            11,
            63,
            106,
            557,
            608,
        })

        theory('returns true for native numbers that should be treated as vowels', function(value)
            assert.is_true(korean.isNumberVowel(value, 'native'))
        end, {
            1,
            11,
            21,
            101,
            1001,
        })

        theory('returns false for native numbers that should not be treated as vowels', function(value)
            assert.is_false(korean.isNumberVowel(value, 'native'))
        end, {
            0,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            12,
        })
    end)

    describe('isSyllable', function()
        theory('returns true for Korean syllable characters', function(value)
            assert.is_true(korean.isSyllable(value))
        end, 44032, 48165, 55203)

        theory('returns false for characters that are not Korean syllables', function(value)
            assert.is_false(korean.isSyllable(value))
        end, 'a', 'b', 'z', '1', '.', '_')
    end)

    describe('isVowel', function()
        -- have to cheat a little since regular Lua doesn't allow arbitrary character values,
        -- so passing numbers in & stubbing where necessary

        it('returns true for Latin vowels', function()
            stub(Helpers, 'isVowelLatin', true):auto_revert()
            assert.is_true(korean.isVowel('a'))
        end)

        it('returns true for a Korean syllable with no final consonant', function()
            stub(Helpers, 'isVowelLatin'):auto_revert()
            assert.is_true(korean.isVowel(45208 --[[@as string]])) -- 나
        end)

        it('returns true for a Korean syllable ending in ㄹ when the particle type is 로', function()
            assert.is_true(korean.isVowel(45804 --[[@as string]], { koreanParticle = 'ro' })) -- 달
        end)

        it('returns false for a Korean syllable with a final consonant', function()
            stub(Helpers, 'isVowelLatin'):auto_revert()
            assert.is_false(korean.isVowel(48165 --[[@as string]])) -- 밥
        end)

        it('returns nil for an indeterminate character', function()
            stub(Helpers, 'isVowelLatin'):auto_revert()
            assert.is_nil(korean.isVowel('!'))
        end)

        describe('when phonetic matching is enabled', function()
            it('treats R as a vowel at the end', function()
                assert.is_true(korean.isVowel('r', { phonetic = true }))
            end)

            theory('does not treat R as a vowel when the position is set to {value}', function(value)
                stub(Helpers, 'isVowelLatin', false):auto_revert()
                assert.is_false(korean.isVowel('r', { phonetic = true, position = value }))
            end, { 'start', 'middle' })

            it('calls matchVowelNumeral with the given system to determine the result', function()
                local _matchVowelNumber = spy.on(korean, 'matchVowelNumeral')

                assert.is_true(korean.isVowel('1', { phonetic = true, koreanNumeralSystem = 'native' }))

                assert.spy(_matchVowelNumber).called(1)
                assert.spy(_matchVowelNumber).called_with('1', 'native')
            end)
        end)
    end)

    describe('matchVowelNumeral', function()
        it('returns false when the input is not a number', function()
            local isMatch = korean.matchVowelNumeral('hello')
            assert.is_false(isMatch)
        end)

        it('ignores numeral separators', function()
            local isMatch = korean.matchVowelNumeral('1,000.00 000')
            assert.is_true(isMatch)
        end)

        theory('returns true and a boolean when the input is a number', function(value)
            local isMatch, isVowel = korean.matchVowelNumeral('1', value)
            assert.is_true(isMatch)
            assert.boolean(isVowel)
        end, { 'sino', 'native' })

        it('returns true and nil when the input is a number but no system', function()
            local isMatch, isVowel = korean.matchVowelNumeral('1')
            assert.is_true(isMatch)
            assert.is_nil(isVowel)
        end)
    end)
end)
