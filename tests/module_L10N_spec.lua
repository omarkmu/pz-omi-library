---Contains tests for the L10N module.
---@using omi.l10n
---@diagnostic disable: access-invisible, duplicate-require

local fixtures = require 'busted.fixtures'
local l10n = require 'OmiLibrary/Module/L10N'
local LibraryLogger = require 'OmiLibrary/Component/Logging/LibraryLogger'

--#region data

local TEST_FTL = fixtures.read('fixtures/test.ftl')
local GLOBAL_FTL = [[
### @global

global-message = I am global
  .attr = attribute
]]

local MOD_ID = 'OmiLibrary'

local MSG_BASIC = 'message-basic'
local MSG_UNKNOWN = 'unknown-message'
local MSG_VARIANTS = 'message-variants-default'

local ID_MSG_BASIC = MOD_ID .. '.' .. MSG_BASIC
local ID_MSG_PARAM_ATTR = MOD_ID .. '.message-parameterized-attr'
local ID_MSG_UNKNOWN = MOD_ID .. '.' .. MSG_UNKNOWN
local ID_MSG_VARIANTS = MOD_ID .. '.' .. MSG_VARIANTS

local VAL_MSG_BASIC = 'Hello world'

---@type string[]
local TEST_LANGUAGES = {
    'AR',
    'CA',
    'CH',
    'CN',
    'CS',
    'DA',
    'DE',
    'EN',
    'ES',
    'FI',
    'FR',
    'HU',
    'ID',
    'IT',
    'JP',
    'KO',
    'NL',
    'NO',
    'PH',
    'PL',
    'PT',
    'PTBR',
    'RO',
    'RU',
    'TH',
    'TR',
    'UA',
}

-- not included → lowercase of language name
local EXPECTED_LOCALES = {
    AR = 'es-AR',
    CH = 'zh-Hant',
    CN = 'zh-Hans',
    JP = 'ja',
    PH = 'tl',
    UA = 'uk',
    PTBR = 'pt-BR',
}

--#endregion

--#region helpers

local function TEST_FILENAME_CACHE(locale)
    return locale .. '/test.ftl'
end

local function TEST_FILENAME_MOD(locale, filename)
    return 'media/ftl/' .. locale .. '/' .. (filename or 'test.ftl')
end

local function PATT_MISSING_ATTR(id, bundle)
    bundle = bundle and ('bundle ' .. bundle) or 'global bundle'
    return 'Missing attribute in ' .. bundle .. ': ' .. id:gsub('([-.])', '%%%1')
end

local function PATT_MISSING_MSG(id, bundle)
    bundle = bundle and ('bundle ' .. bundle) or 'global bundle'
    return 'Missing message in ' .. bundle .. ': ' .. id:gsub('([-.])', '%%%1')
end

local function reload()
    reload_module('OmiLibrary/Module/Core/L10N')
    l10n = reload_module('OmiLibrary/Module/L10N')
end

---@param block fun(locale: string, language: string)
---@param immediate? boolean
---@return function?
---@overload fun(block: fun(locale: string, language: string)): function
local function eachLanguage(block, immediate)
    if immediate then
        for i = 1, #TEST_LANGUAGES do
            local language = TEST_LANGUAGES[i]
            local locale = EXPECTED_LOCALES[language] or language:lower()
            block(locale, language)
        end

        return
    end

    return function()
        teardown(reload)

        for i = 1, #TEST_LANGUAGES do
            local language = TEST_LANGUAGES[i] --[[@as string]]
            local locale = EXPECTED_LOCALES[language] or language:lower()

            describe('when the current language is ' .. language, function()
                setup(function()
                    stub(Translator, 'getLanguage', function()
                        return {
                            name = function() return language end,
                            base = function() end,
                        }
                    end):auto_revert()

                    reload()
                end)

                block(locale, language)
            end)
        end
    end
end

--#endregion

describe('#module l10n', function()
    local _print ---@type luassert.stub
    local _error ---@type luassert.spy
    local _bundle ---@type FluentBundle
    setup(function()
        _print = stub(_G, 'print'):auto_revert()
        _error = spy.on(_G, 'error'):auto_revert()
        _bundle = l10n.getOrCreateBundle(MOD_ID)

        zomboid.stub_activated_mods({ MOD_ID }):auto_revert()
        reload_module('OmiLibrary/Module/Utils')
    end)

    eachLanguage(function(locale)
        setup(function()
            zomboid.set_cache_file(TEST_FILENAME_CACHE(locale), TEST_FTL)
            zomboid.set_mod_file(MOD_ID, TEST_FILENAME_MOD(locale), TEST_FTL)
            zomboid.set_mod_file(MOD_ID, TEST_FILENAME_MOD(locale, 'global.ftl'), GLOBAL_FTL)
        end)
    end, true)

    teardown(zomboid.revert_files)

    after_each(function()
        _print:clear()
        _error:clear()
    end)


    describe('(on load)', eachLanguage(function(locale)
        it('loads mod resources', function()
            assert.is_true(l10n.hasBundle(MOD_ID))
            assert.equal(VAL_MSG_BASIC, l10n.getText(ID_MSG_BASIC))
        end)
    end))

    describe('#function', function()
        before_each(function()
            -- clear logger caches so logs aren't skipped due to .once
            _bundle.log --[[@cast -?]].warn._seenOnceMessages = {}
            LibraryLogger.warn._seenOnceMessages = {}
        end)

        describe('addResource', function()
            local resource ---@type FluentResource
            before_each(function()
                resource = l10n.parseResource(TEST_FTL, 'test.ftl')
            end)

            it('adds the resource to the global bundle when no bundle is specified', function()
                local bundle = l10n.addResource(resource)
                assert.equal(l10n._global, bundle)
            end)

            it('adds the resource to the bundle specified in the resource', function()
                resource = l10n.parseResource('### @bundle ' .. MOD_ID .. '\n' .. TEST_FTL, 'test.ftl')
                local bundle = l10n.addResource(resource)
                assert.equal(MOD_ID, bundle.name)
            end)
        end)

        describe('addModResource', function()
            eachLanguage(function(locale)
                it('adds a resource from a mod directory for locale ' .. locale, function()
                    local resource, bundle = l10n.addModResource(MOD_ID, TEST_FILENAME_MOD(locale))
                    assert.not_nil(resource)
                    assert.is_instance(resource, l10n.FluentResource)

                    assert.not_nil(bundle) ---@cast bundle -?
                    assert.is_instance(bundle, l10n.FluentBundle)
                    assert.equal(MOD_ID, bundle.name)
                end)
            end, true)

            it('returns nil for an unknown mod id', function()
                local resource, bundle = l10n.addModResource('UnknownMod', 'media/ftl/en/test.ftl')
                assert.is_nil(resource)
                assert.is_nil(bundle)
            end)
        end)

        describe('extractLanguage', function()
            it('returns the input string for a simple language tag', function()
                assert.equal('en', l10n.extractLanguage('en'))
                assert.equal('uk', l10n.extractLanguage('uk'))
                assert.equal('tl', l10n.extractLanguage('tl'))
                assert.equal('fil', l10n.extractLanguage('fil'))
            end)

            it('returns the primary language subtag for a language tag with multiple components', function()
                assert.equal('en', l10n.extractLanguage('en-US'))
                assert.equal('en', l10n.extractLanguage('en-GB'))
                assert.equal('uk', l10n.extractLanguage('uk-UA'))
                assert.equal('ja', l10n.extractLanguage('ja-JP'))
            end)
        end)

        describe('getAttr', function()
            it('returns an attribute value for a defined attribute', function()
                assert.equal('message', l10n.getAttr(ID_MSG_BASIC, 'type'))
            end)

            it('returns a attribute value for a defined global attribute', function()
                assert.equal('attribute', l10n.getAttr('global-message', 'attr'))
            end)

            it('returns the attribute name for an unknown bundle', function()
                assert.equal('message-basic.type', l10n.getAttr('Unknown.message-basic', 'type'))
            end)

            it('returns the attribute name for an unknown message', function()
                assert.equal('unknown-message.type', l10n.getAttr(ID_MSG_UNKNOWN, 'type'))
            end)

            it('returns the attribute name for an unknown attribute', function()
                assert.equal('message-basic.unknown', l10n.getAttr(ID_MSG_BASIC, 'unknown'))
            end)

            it('logs a warning for an unknown message', function()
                l10n.getAttr(ID_MSG_UNKNOWN, 'type')
                assert.spy(_print).called(1)
                assert.spy(_print).called_with(match.match(PATT_MISSING_ATTR('unknown-message.type', MOD_ID)))
            end)

            it('logs a warning for an unknown attribute', function()
                l10n.getAttr(ID_MSG_BASIC, 'unknown')
                assert.spy(_print).called(1)
                assert.spy(_print).called_with(match.match(PATT_MISSING_ATTR('message-basic.unknown', MOD_ID)))
            end)

            it('logs a warning for an unknown global message', function()
                l10n.getAttr(MSG_UNKNOWN, 'type')
                assert.spy(_print).called(1)
                assert.spy(_print).called_with(match.match(PATT_MISSING_ATTR('unknown-message.type')))
            end)

            it('logs a warning for an unknown global attribute', function()
                l10n.getAttr('global-message', 'unknown')
                assert.spy(_print).called(1)
                assert.spy(_print).called_with(match.match(PATT_MISSING_ATTR('global-message.unknown')))
            end)
        end)

        describe('getAttrOrNull', function()
            it('returns an attribute value for a defined attribute', function()
                assert.equal('message', l10n.getAttrOrNull(ID_MSG_BASIC, 'type'))
            end)

            it('returns a attribute value for a defined global attribute', function()
                assert.equal('attribute', l10n.getAttrOrNull('global-message', 'attr'))
            end)

            it('uses the given default bundle', function()
                assert.equal('message', l10n.getAttrOrNull(MSG_BASIC, 'type', nil, MOD_ID))
            end)

            it('returns nil for an unknown bundle', function()
                assert.is_nil(l10n.getAttrOrNull('Unknown.message-basic', 'type'))
            end)

            it('returns nil for an unknown message', function()
                assert.is_nil(l10n.getAttrOrNull(ID_MSG_UNKNOWN, 'type'))
            end)

            it('returns nil for an unknown attribute', function()
                assert.is_nil(l10n.getAttrOrNull(ID_MSG_UNKNOWN, 'type'))
            end)

            it('logs errors that occur during message formatting', function()
                local pattName = 'message%-parameterized%-attr%.attr'
                local expected = 'Error while formatting ' .. pattName .. '%. Missing variable: %$value'

                l10n.getAttrOrNull(ID_MSG_PARAM_ATTR, 'attr')

                assert.spy(_error).called(1)
                assert.spy(_error).called_with(match.match(expected))
            end)
        end)

        describe('getBundle', function()
            it('returns nil for a bundle that does not exist', function()
                assert.is_false(l10n.hasBundle('UNKNOWN_BUNDLE'))

                local bundle = l10n.getBundle('UNKNOWN_BUNDLE')
                assert.is_nil(bundle)
            end)
        end)

        describe('getOrCreateBundle', function()
            it('returns an existing logger', function()
                local bundle = l10n.getOrCreateBundle(MOD_ID)
                assert.is_instance(bundle, l10n.FluentBundle)
            end)

            it('creates the logger if it does not exist', function()
                assert.is_false(l10n.hasBundle('NEW_BUNDLE'))

                local bundle = l10n.getOrCreateBundle('NEW_BUNDLE')
                assert.is_instance(bundle, l10n.FluentBundle)
            end)

            it('creates a logger for the bundle', function()
                assert.is_true(l10n.hasBundle(MOD_ID))

                local bundle = l10n.getOrCreateBundle(MOD_ID)
                local logger = bundle.log

                assert.not_nil(logger) ---@cast logger -?
                assert.equal(MOD_ID, logger._id)
            end)
        end)

        describe('getLocaleTag', eachLanguage(function(locale)
            it('returns the corresponding locale name', function()
                assert.equal(locale, l10n.getLocaleTag())
            end)
        end))

        describe('gameLanguageToLocaleTag', function()
            eachLanguage(function(locale, language)
                it('returns the expected locale for ' .. language, function()
                    assert.equal(locale, l10n.gameLanguageToLocaleTag(language))
                end)
            end, true)
        end)

        describe('getText', function()
            it('returns a string value for a defined message', function()
                assert.equal(VAL_MSG_BASIC, l10n.getText(ID_MSG_BASIC))
            end)

            it('returns a string value for a defined global message', function()
                assert.equal('I am global', l10n.getText('global-message'))
            end)

            it('returns the message id for an unknown bundle', function()
                assert.equal(MSG_BASIC, l10n.getText('Unknown.message-basic'))
            end)

            it('returns the message id for an unknown message', function()
                assert.equal(MSG_UNKNOWN, l10n.getText(ID_MSG_UNKNOWN))
            end)

            it('logs a warning for an unknown message', function()
                l10n.getText(ID_MSG_UNKNOWN)
                assert.spy(_print).called(1)
                assert.spy(_print).called_with(match.match(PATT_MISSING_MSG(MSG_UNKNOWN, MOD_ID)))
            end)

            it('logs a warning for an unknown global message', function()
                l10n.getText(MSG_UNKNOWN)
                assert.spy(_print).called(1)
                assert.spy(_print).called_with(match.match(PATT_MISSING_MSG(MSG_UNKNOWN)))
            end)
        end)

        describe('getTextOrNull', function()
            it('returns a string value for a defined message', function()
                assert.equal(VAL_MSG_BASIC, l10n.getTextOrNull(ID_MSG_BASIC))
            end)

            it('returns a string value for a defined global message', function()
                assert.equal('I am global', l10n.getTextOrNull('global-message'))
            end)

            it('uses the given default bundle', function()
                assert.equal(VAL_MSG_BASIC, l10n.getTextOrNull(MSG_BASIC, nil, MOD_ID))
            end)

            it('returns nil for an unknown bundle', function()
                assert.is_nil(l10n.getTextOrNull('Unknown.message-basic'))
            end)

            it('returns nil for an unknown message', function()
                assert.is_nil(l10n.getTextOrNull(ID_MSG_UNKNOWN))
            end)

            it('logs errors that occur during message formatting', function()
                local expected = 'Error while formatting message%-variants%-default%. Missing variable: %$gender'

                l10n.getTextOrNull(ID_MSG_VARIANTS)

                assert.spy(_error).called(1)
                assert.spy(_error).called_with(match.match(expected))
            end)
        end)

        describe('hasBundle', function()
            it('returns true for the name of an existing bundle', function()
                assert.is_true(l10n.hasBundle(MOD_ID))
            end)

            it('returns false for the name of an unknown bundle', function()
                assert.is_false(l10n.hasBundle('Unknown'))
            end)
        end)

        describe('isVowel', function()
            it('returns true for basic vowels', function()
                assert.is_true(l10n.isVowel('a'))
                assert.is_true(l10n.isVowel('e'))
                assert.is_true(l10n.isVowel('i'))
                assert.is_true(l10n.isVowel('o'))
                assert.is_true(l10n.isVowel('u'))
            end)

            it('returns false for consonants', function()
                assert.is_false(l10n.isVowel('b'))
                assert.is_false(l10n.isVowel('c'))
                assert.is_false(l10n.isVowel('d'))
                assert.is_false(l10n.isVowel('f'))
                assert.is_false(l10n.isVowel('h'))
                assert.is_false(l10n.isVowel('j'))
                assert.is_false(l10n.isVowel('m'))
                assert.is_false(l10n.isVowel('z'))
            end)

            it('returns true for `y` by default', function()
                assert.is_true(l10n.isVowel('y'))
            end)

            it('returns true for `y` if the position is set to end', function()
                assert.is_true(l10n.isVowel('y', { position = 'end' }))
            end)

            it('returns nil for the empty string', function()
                assert.is_nil(l10n.isVowel(''))
            end)

            it('returns nil for `y` if the position is set to start or middle', function()
                assert.is_nil(l10n.isVowel('y', { position = 'start' }))
                assert.is_nil(l10n.isVowel('y', { position = 'middle' }))
            end)

            describe('with phonetic matching enabled', function()
                it('returns true for phonetic vowel heuristics', function()
                    assert.is_true(l10n.isVowel('h', { full = 'rah', phonetic = true }))
                    assert.is_true(l10n.isVowel('h', { full = 'myrrh', phonetic = true }))
                    assert.is_true(l10n.isVowel('y', { full = 'may', phonetic = true }))
                    assert.is_true(l10n.isVowel('w', { full = 'now', phonetic = true }))
                end)

                it('returns false for phonetic consonant heuristics', function()
                    assert.is_false(l10n.isVowel('e', { full = 'jane', phonetic = true }))
                    assert.is_false(l10n.isVowel('e', { full = 'wine', phonetic = true }))
                    assert.is_false(l10n.isVowel('e', { full = 'dude', phonetic = true }))
                    assert.is_false(l10n.isVowel('e', { full = 'huge', phonetic = true }))
                end)

                it('returns nil for words ending in ough', function()
                    assert.is_nil(l10n.isVowel('h', { full = 'though', phonetic = true }))
                    assert.is_nil(l10n.isVowel('h', { full = 'dough', phonetic = true }))
                    assert.is_nil(l10n.isVowel('h', { full = 'tough', phonetic = true }))
                    assert.is_nil(l10n.isVowel('h', { full = 'rough', phonetic = true }))
                end)

                it('returns the default result when there are no phonetic matches', function()
                    assert.is_true(l10n.isVowel('e', { full = 'tree', phonetic = true }))

                    assert.is_false(l10n.isVowel('h', { full = 'mirth', phonetic = true }))

                    assert.is_nil(l10n.isVowel('?', { full = 'sky?', phonetic = true }))
                end)
            end)

            theory('with the locale set to {value}', function(locale)
                it('calls the korean.isVowel function to determine the result', function()
                    local _isVowel = stub(l10n.korean, 'isVowel', false):auto_revert()

                    local options = { locale = locale }
                    assert.is_false(l10n.isVowel('e', options))

                    assert.stub(_isVowel).called(1)
                    assert.stub(_isVowel).called_with('e', match.ref(options))
                end)
            end, 'ko', 'ko-KR')
        end)

        describe('loadCacheResource', function()
            eachLanguage(function(locale)
                it('loads a resource from the Lua cache directory for locale ' .. locale, function()
                    local resource = l10n.loadCacheResource(TEST_FILENAME_CACHE(locale))
                    assert.not_nil(resource) ---@cast resource -?
                    assert.is_instance(resource, l10n.FluentResource)
                    assert.is_nil(resource.bundle)
                end)
            end, true)

            it('returns nil for an unknown filename', function()
                assert.is_nil(l10n.loadCacheResource('media/ftl/en/test.ftl'))
            end)
        end)

        describe('loadModResource', function()
            eachLanguage(function(locale)
                it('loads a resource from a mod directory for locale ' .. locale, function()
                    local resource = l10n.loadModResource(MOD_ID, TEST_FILENAME_MOD(locale))
                    assert.not_nil(resource) ---@cast resource -?
                    assert.is_instance(resource, l10n.FluentResource)

                    assert.equal(MOD_ID, resource.bundle)
                end)
            end, true)

            it('returns nil for an unknown mod id', function()
                assert.is_nil(l10n.loadModResource('UnknownMod', 'media/ftl/en/test.ftl'))
            end)

            it('returns nil for an unknown filename', function()
                assert.is_nil(l10n.loadModResource(MOD_ID, 'media/ftl/zzz/test.ftl'))
            end)
        end)

        describe('parseResource', function()
            local _parse ---@type luassert.spy
            local _fromAST ---@type luassert.spy
            before_each(function()
                _parse = stub(l10n.FluentParser, 'parse'):auto_revert()
                _fromAST = stub(l10n.FluentResource, 'fromAST'):auto_revert()
            end)

            it('calls parse on a FluentParser', function()
                l10n.parseResource(TEST_FTL)
                assert.spy(_parse).called(1)
                assert.spy(_parse).called_with(match._, TEST_FTL)
            end)

            it('calls FluentResource.fromAST', function()
                l10n.parseResource(TEST_FTL)
                assert.spy(_fromAST).called(1)
            end)
        end)

        describe('resolveTranslateTable', function()
            it('returns a string value given an id', function()
                local value = l10n.resolveTranslateTable({ id = MSG_BASIC }, MOD_ID)
                assert.equal(VAL_MSG_BASIC, value)
            end)

            it('returns a string value given an id and arguments', function()
                local value = l10n.resolveTranslateTable({
                    id = 'message-var',
                    args = {
                        name = 'Amadi',
                        num = l10n.FluentNumber:new(15),
                    },
                }, MOD_ID)

                assert.equal('Hello, Amadi! Your lucky number is 15.', value)
            end)

            it('returns a string value given an id and attribute', function()
                local value = l10n.resolveTranslateTable({
                    id = MSG_BASIC,
                    attribute = 'type',
                }, MOD_ID)

                assert.equal('message', value)
            end)

            it('returns a string id for a cyclic reference', function()
                local rec = {
                    id = 'message-var',
                    args = {
                        num = 42,
                    },
                }

                rec.args.name = rec
                local value = l10n.resolveTranslateTable(rec, MOD_ID)

                local expected = string.format('Hello, message-var! Your lucky number is 42.', MOD_ID)
                assert.equal(expected, value)
            end)
        end)

        describe('selectPlural', function()
            it('returns the result for the absolute value of a negative input', function()
                assert.equal('one', l10n.selectPlural(-1, 'en'))
                assert.equal('two', l10n.selectPlural(-2, 'en', 'ordinal'))
            end)

            it('defaults to rules for the primary language subtag in a locale tag', function()
                -- no rules for pt-BR, but pt indicates that 0..1 → one
                assert.equal('one', l10n.selectPlural(0, 'pt-BR'))
                assert.equal('one', l10n.selectPlural(1, 'pt-BR'))
                assert.equal('other', l10n.selectPlural(2, 'pt-BR'))
            end)

            theory('returns the expected values for locale {locale}', function(args)
                assert.equal(args.category, l10n.selectPlural(args.n, args.locale, args.type))
            end, {
                -- en: cardinal → one, other; ordinal → one, two, few, other (tests 'n' operand)
                { locale = 'en', n = 1, category = 'one' },
                { locale = 'en', n = 2, category = 'other' },
                { locale = 'en', n = 3, category = 'other' },
                { locale = 'en', n = 4, category = 'other' },
                { locale = 'en', n = 50, category = 'other' },
                { locale = 'en', n = 51, category = 'other' },
                { locale = 'en', n = 1, category = 'one', type = 'ordinal' },
                { locale = 'en', n = 2, category = 'two', type = 'ordinal' },
                { locale = 'en', n = 3, category = 'few', type = 'ordinal' },
                { locale = 'en', n = 4, category = 'other', type = 'ordinal' },

                -- ko: cardinal → other; ordinal → other (tests default)
                { locale = 'ko', n = 1, category = 'other' },
                { locale = 'ko', n = 2, category = 'other' },
                { locale = 'ko', n = 3, category = 'other' },
                { locale = 'ko', n = 4, category = 'other' },
                { locale = 'ko', n = 1, category = 'other', type = 'ordinal' },
                { locale = 'ko', n = 2, category = 'other', type = 'ordinal' },
                { locale = 'ko', n = 3, category = 'other', type = 'ordinal' },
                { locale = 'ko', n = 4, category = 'other', type = 'ordinal' },

                -- es: cardinal → one, many; ordinal → other (tests 'e' operand)
                { locale = 'es', n = 1, category = 'one' },
                { locale = 'es', n = 2, category = 'other' },
                { locale = 'es', n = 3, category = 'other' },
                { locale = 'es', n = 1000000, category = 'many' },
                { locale = 'es', n = 2000000, category = 'many' },
                { locale = 'es', n = 1, category = 'other', type = 'ordinal' },
                { locale = 'es', n = 2, category = 'other', type = 'ordinal' },
                { locale = 'es', n = 3, category = 'other', type = 'ordinal' },

                -- sr: cardinal → one, few, other; ordinal → other (tests 'f' operand)
                { locale = 'sr', n = 1, category = 'one' },
                { locale = 'sr', n = 1.1, category = 'one' },
                { locale = 'sr', n = 1.2, category = 'few' },
                { locale = 'sr', n = 1.3, category = 'few' },
                { locale = 'sr', n = 1.4, category = 'few' },
                { locale = 'sr', n = 1.5, category = 'other' },
                { locale = 'sr', n = 2, category = 'few' },
                { locale = 'sr', n = 2.1, category = 'one' },
                { locale = 'sr', n = 2.2, category = 'few' },
                { locale = 'sr', n = 2.3, category = 'few' },
                { locale = 'sr', n = 2.4, category = 'few' },
                { locale = 'sr', n = 2.5, category = 'other' },
                { locale = 'sr', n = 3, category = 'few' },
                { locale = 'sr', n = 4, category = 'few' },
                { locale = 'sr', n = 5, category = 'other' },
                { locale = 'sr', n = 1, category = 'other', type = 'ordinal' },
                { locale = 'sr', n = 2, category = 'other', type = 'ordinal' },
                { locale = 'sr', n = 3, category = 'other', type = 'ordinal' },
                { locale = 'sr', n = 4, category = 'other', type = 'ordinal' },
                { locale = 'sr', n = 5, category = 'other', type = 'ordinal' },
            })
        end)
    end)
end)
