---Contains tests for the Decoder component.
---@using omi
---@diagnostic disable: access-invisible

local Decoder = require 'OmiLibrary/Component/JSON/Decoder'

local char = string.char

describe('#component Decoder #method', function()
    local instance ---@type json.Decoder
    before_each(function()
        instance = Decoder:new()
    end)

    describe('decode', function()
        describe('decodes', function()
            it('true', function()
                assert.is_true(instance:decode('true'))
            end)

            it('false', function()
                assert.is_false(instance:decode('false'))
            end)

            it('null as nil', function()
                assert.is_nil(instance:decode('null'))
            end)

            it('null as the given sentinel value', function()
                local null = {}
                instance = Decoder:new({ null = null })
                assert.equal(null, instance:decode('null'))
            end)

            it('numeric values', function()
                assert.equal(1, instance:decode('1'))
                assert.equal(-100, instance:decode('-100'))
            end)

            it('strings', function()
                assert.equal('Hello, world', instance:decode('"Hello, world"'))
            end)

            it('strings with escapes', function()
                assert.equal(char(0), instance:decode('"\\u0000"'))
                assert.equal(char(127), instance:decode('"\\u007F"'))
                assert.equal(char(255), instance:decode('"\\u00FF"'))
                assert.equal('"', instance:decode('"\\""'))
                assert.equal('\\', instance:decode('"\\\\"'))
                assert.equal('/', instance:decode('"\\/"'))
                assert.equal('\b\f\r\t\n', instance:decode('"\\b\\f\\r\\t\\n"'))

                -- \uD800\uDC00 → U+10000 → (utf-8) 0xF0 0x90 0x80 0x80
                assert.equal(char(240, 144, 128, 128), instance:decode('"\\uD800\\uDC00"'))
            end)

            it('an empty array as an empty table', function()
                assert.same({}, instance:decode('[]'))
            end)

            it('an array as an equivalent table', function()
                assert.same({ 1, 2, 3 }, instance:decode('[1,2,3]'))
            end)

            it('an array with newlines as an equivalent table', function()
                assert.same({ 1, 2, 3 }, instance:decode('[\n  1,\n  2,\n  3\n]'))
            end)

            it('an object as an equivalent table', function()
                assert.same({ inner = { name = 'Bob' } }, instance:decode('{"inner":{"name":"Bob"}}'))
            end)

            it('an object with newlines as an equivalent table', function()
                assert.same({ name = 'Bob', age = 5 }, instance:decode('{\n  "name": "Bob",\n  "age": 5\n}'))
            end)
        end)

        describe('throws an error', function()
            it('when the argument is not a string', function()
                assert.error(function()
                    local value ---@type string
                    instance:decode(value)
                end, 'expected argument of type string, got nil')
            end)

            it('when an invalid character is encountered', function()
                assert.error_match(function() instance:decode('invalid') end, '^unexpected character `i`')
            end)

            it('when an invalid literal is encountered', function()
                assert.error_match(function() instance:decode('falseness') end, 'invalid literal `falseness`')
            end)

            it('when an invalid number is encountered', function()
                assert.error_match(function() instance:decode('1a') end, 'invalid number `1a`')
            end)

            it('when a control character is encountered in a string', function()
                local value = '"' .. char(30) .. '"'
                assert.error_match(function() instance:decode(value) end, 'control character in string')
            end)

            it('when an invalid unicode escape is encountered in a string', function()
                assert.error_match(function() instance:decode('"\\uZ"') end, 'invalid unicode escape in string')
            end)

            it('when an invalid escape is encountered in a string', function()
                assert.error_match(function() instance:decode('"\\z"') end, 'invalid escape char `z` in string')
            end)

            it('when a string is unterminated', function()
                assert.error_match(function() instance:decode('"hello') end, 'expected closing quote for string')
            end)

            it('when a trailing character is present', function()
                assert.error(function() instance:decode('{} {') end, 'trailing garbage')
            end)

            it('when input ends unexpectedly', function()
                assert.error_match(function() instance:decode('[') end, 'unexpected end of input')
            end)

            it('when an array has an invalid character', function()
                assert.error_match(function() instance:decode('[\n  1 a\n]') end, 'expected `]` or `,`')
            end)

            it('when an object does not have a string key', function()
                assert.error_match(function() instance:decode('{1:1}') end, 'expected string for key')
            end)

            it('when an object key is invalid', function()
                local value = '{"unterminated:1}'
                assert.error_match(function() instance:decode(value) end, 'expected closing quote for string')
            end)

            it('when an object value is invalid', function()
                local value = '{"key":"unterminated}'
                assert.error_match(function() instance:decode(value) end, 'expected closing quote for string')
            end)

            it('when missing an object delimiter', function()
                assert.error_match(function() instance:decode('{"key" 1}') end, 'expected `:` after key')
                assert.error_match(function() instance:decode('{"key":1 2}') end, 'expected `}` or `,`')
            end)
        end)
    end)

    describe('tryDecode', function()
        it('returns false and an error when decoding fails', function()
            local result, err = instance:tryDecode('invalid')

            assert.is_false(result)
            assert.match('unexpected character `i`', err --[[@as string]])
        end)
    end)
end)
