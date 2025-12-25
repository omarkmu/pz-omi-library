---Contains tests for the FluentBundle component.
---@using omi
---@using omi.l10n
---@diagnostic disable: access-invisible

local fixtures = require 'busted.fixtures'
local FluentBundle = require 'OmiLibrary/Component/L10N/FluentBundle'
local FluentParser = require 'OmiLibrary/Component/L10N/FluentParser'
local FluentResource = require 'OmiLibrary/Component/L10N/FluentResource'
local FluentNumber = require 'OmiLibrary/Component/L10N/FluentTypes/Number'
local FluentFlattener = require 'OmiLibrary/Component/L10N/FluentFlattener'

local BUNDLE_NAME = 'mod_id'
local TEST_FTL = fixtures.read('fixtures/test.ftl')

describe('#component FluentBundle #method', function()
    local bundle ---@type FluentBundle
    local resource ---@type FluentResource

    setup(function()
        zomboid.set_string('UI_Yes', 'Yes')

        local parser = FluentParser:new()
        resource = FluentResource.fromAST(parser:parse(TEST_FTL))
    end)

    teardown(zomboid.revert_strings)

    before_each(function()
        bundle = FluentBundle:new({ name = BUNDLE_NAME })
        bundle:addResource(resource)
    end)

    ---Runs tests using both early and late resource evaluation.
    ---@param block function
    local function earlyAndLate(block)
        return function()
            describe('(with flattening enabled)', function()
                block(true)
            end)

            describe('(with flattening disabled)', function()
                before_each(function()
                    bundle = FluentBundle:new({ name = BUNDLE_NAME })
                    bundle:addResource(resource, false)
                end)

                block(false)
            end)
        end
    end

    describe('addResource', earlyAndLate(function(isEarly)
        it('adds messages from the resource to the bundle', function()
            assert.is_true(bundle:hasMessage('message-basic'))
            assert.is_not_nil(bundle:getMessage('message-basic'))
        end)

        it('adds terms from the resource to the bundle', function()
            assert.is_not_nil(bundle._terms['-term'])
            assert.is_not_nil(bundle._terms['-term-parameterized'])
        end)

        if isEarly then
            it('flattens expected messages', function()
                bundle = FluentBundle:new({ name = BUNDLE_NAME })
                bundle:addResource(resource)

                assert.equal('pi is a number', bundle._messages['message-str'].value)
                assert.equal('pi is ~3.14159', bundle._messages['message-num'].value)
                assert.equal('I am a message, not a term', bundle._messages['message-term'].value)
                assert.equal('I am number one!', bundle._messages['message-term-selector'].value)
                assert.equal('Something cool', bundle._messages['message-term-parameterized'].value)
                assert.equal('term is a word', bundle._messages['message-variants-term-attribute'].value)
            end)

            it('does not flatten messages with message references', function()
                assert.is_table(bundle._messages['message-ref'].value)
                assert.is_table(bundle._messages['message-ref-attr'].value)
            end)

            it('does not flatten messages with variable references', function()
                assert.is_table(bundle._messages['message-var'].value)
            end)
        else
            it('does not flatten messages that can be flattened', function()
                assert.is_table(bundle._messages['message-term'].value)
                assert.is_table(bundle._messages['message-term-parameterized'].value)
            end)
        end
    end))

    describe('flatten', function()
        it('calls flattenBundle on a FluentFlattener', function()
            local _flattenBundle = stub(FluentFlattener, 'flattenBundle'):auto_revert()

            local skipIds = {}
            bundle:flatten(skipIds)

            assert.stub(_flattenBundle).called(1)
            assert.stub(_flattenBundle).called_with(match._, match.ref(skipIds))
        end)
    end)

    describe('getMessage', earlyAndLate(function()
        it('returns a message object for a known ID', function()
            local message = bundle:getMessage('message-basic')
            local expected = {
                id = 'message-basic',
                value = 'Hello world',
                attributes = { type = 'message' },
            }

            assert.same(expected, message)
        end)

        it('returns nil for messages that do not exist', function()
            assert.is_nil(bundle:getMessage('unknown'))
        end)
    end))

    describe('hasMessage', earlyAndLate(function()
        it('returns true for a known ID', function()
            assert.is_true(bundle:hasMessage('message-basic'))
        end)

        it('returns false for messages that do not exist', function()
            assert.is_false(bundle:hasMessage('unknown'))
        end)
    end))

    describe('formatPattern', earlyAndLate(function()
        local function formatWithErrors(id, args)
            local message = bundle:getMessage(id)
            if not message then
                error('message ' .. id .. ' does not exist')
            end

            local value = message.value
            if not value then
                error('message ' .. id .. ' has no value')
            end

            return bundle:formatPattern(value, args)
        end

        local function format(id, args)
            local str, errors = formatWithErrors(id, args)
            assert.is_nil(errors)

            return str
        end

        it('replaces escapes in strings with their value', function()
            local unicode1 = string.char(0x00A0)
            local unicode2 = string.char(0x10000)
            local expected = 'A message with "escapes", like \\, ' .. unicode1 .. ', and ' .. unicode2
            assert.equal(expected, format('message-escapes'))
        end)

        it('formats a basic string message', function()
            assert.equal('Hello world', format('message-basic'))
        end)

        it('formats a message with a message reference', function()
            assert.equal('Hello world, I am here', format('message-ref'))
        end)

        it('formats a message with a message attribute reference', function()
            assert.equal('This is a message', format('message-ref-attr'))
        end)

        it('formats a message with a term reference', function()
            assert.equal('I am a message, not a term', format('message-term'))
        end)

        it('formats a message with a parameterized term reference', function()
            assert.equal('Something cool', format('message-term-parameterized'))
        end)

        it('formats a message with a number literal', function()
            assert.equal('pi is ~3.14159', format('message-num'))
        end)

        it('formats a message with a string literal', function()
            assert.equal('pi is a number', format('message-str'))
        end)

        it('formats a message with variable references', function()
            local str = format('message-var', { name = 'Angela', num = 42 })
            assert.equal('Hello, Angela! Your lucky number is 42.', str)
        end)

        it('formats a message using the NUMBER function', function()
            assert.equal('5.00', format('message-num-function'))
        end)

        it('formats a message using the GETTEXT function', function()
            assert.equal('Yes', format('message-gettext'))
        end)

        it('formats a message using the GETTEXT function with a default', function()
            assert.equal('DEFAULT', format('message-gettext-default'))
        end)

        it('formats a selector using a term attribute', function()
            assert.equal('term is a word', format('message-variants-term-attribute'))
        end)

        it('formats a selector with an ordinal number', function()
            local place = FluentNumber:new(22, { type = 'ordinal' })
            local str = format('message-variants-ordinal', { place = place })
            assert.equal('You came in 22nd.', str)
        end)

        it('formats a selector with the given variant', function()
            local str = format('message-variants-default', { gender = 'female' })
            assert.equal('She is pretty cool.', str)
        end)

        it('formats a selector with the default variant', function()
            local str = format('message-variants-default', { gender = 'unspecified' })
            assert.equal('They are pretty cool.', str)
        end)

        it('produces an error for an unknown function', function()
            local str, errors = formatWithErrors('message-unknown-function')
            assert.equal('UNKNOWN()', str)
            assert.same({ 'Unknown function: UNKNOWN()' }, errors)
        end)
    end))
end)
