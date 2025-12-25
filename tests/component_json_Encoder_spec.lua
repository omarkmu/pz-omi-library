---Contains tests for the Encoder component.
---@using omi
---@diagnostic disable: access-invisible

local Encoder = require 'OmiLibrary/Component/JSON/Encoder'

describe('#component Encoder #method', function()
    local noop = function() end
    local instance ---@type json.Encoder
    before_each(function()
        instance = Encoder:new({})
    end)

    describe('encode', function()
        it('updates options if given a table', function()
            local _setOptions = spy.on(Encoder, '_setOptions')

            instance:encode(1, { pretty = true })

            assert.spy(_setOptions).called(1)
        end)

        it('uses identation and newlines for tables if the pretty option is given', function()
            local value = { key = 'value' }
            local options = { pretty = true }
            assert.equal('{\n  "key": "value"\n}', instance:encode(value, options))

            value = { 1, 2, 3 }
            assert.equal('[\n  1,\n  2,\n  3\n]', instance:encode(value, options))
        end)

        describe('encodes', function()
            it('true as a boolean', function()
                assert.equal('true', instance:encode(true))
            end)

            it('false as a boolean', function()
                assert.equal('false', instance:encode(false))
            end)

            it('nil as null', function()
                assert.equal('null', instance:encode(nil))
            end)

            it('numeric values', function()
                assert.equal('1', instance:encode(1))
                assert.equal('-100', instance:encode(-100))
            end)

            it('strings', function()
                assert.equal('"Hello, world"', instance:encode('Hello, world'))
            end)

            it('strings with escapes', function()
                assert.equal('"\\u0000"', instance:encode(string.char(0)))
                assert.equal('"\\b\\f\\r\\n\\t"', instance:encode('\b\f\r\n\t'))
            end)

            it('an empty table as an array', function()
                assert.equal('[]', instance:encode({}))
            end)

            it('a table with continuous elements starting at index 1 as an array', function()
                assert.equal('[1,2,3]', instance:encode({ 1, 2, 3 }))
            end)

            it('the same table multiple times within an array', function()
                local inner = { one = 1 }
                local result = instance:encode({ inner, inner, inner })
                assert.equal('[{"one":1},{"one":1},{"one":1}]', result)
            end)
        end)

        describe('throws an error', function()
            it('when attempting to encode a function', function()
                assert.error(function() instance:encode(noop) end, 'cannot encode type `function`')
            end)

            it('when attempting to encode NaN', function()
                assert.error(function() instance:encode(0 / 0) end, 'unexpected number value `-nan`')
            end)

            it('when attempting to encode a mixed table', function()
                local value = { 'hello', noun = 'world' }
                assert.error(function() instance:encode(value) end, 'invalid table: mixed or invalid key types')
            end)

            it('when attempting to encode a table with a circular reference', function()
                local t = {}
                t.table = t

                assert.error(function() instance:encode(t) end, 'circular reference')
            end)

            it('when attempting to encode an object with an invalid key', function()
                ---@diagnostic disable-next-line: duplicate-set-field
                instance._encodeString = function() return 'test error' end

                assert.error(function() instance:encode({ key = true }) end, 'test error')
            end)

            it('when attempting to encode an object with an invalid value', function()
                assert.error(function() instance:encode({ noop = noop }) end, 'cannot encode type `function`')
            end)

            it('when attempting to encode an array with an invalid value', function()
                assert.error(function() instance:encode({ noop }) end, 'cannot encode type `function`')
            end)
        end)
    end)

    describe('tryEncode', function()
        it('returns nil and an error when encoding fails', function()
            local result, err = instance:tryEncode(function() end)

            assert.is_nil(result)
            assert.equal('cannot encode type `function`', err)
        end)
    end)
end)
