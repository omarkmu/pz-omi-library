---Contains tests for the Interpolator component.
---@using omi
---@diagnostic disable: access-invisible

local MultiMap = require 'OmiLibrary/Component/Core/MultiMap'
local Interpolator = require 'OmiLibrary/Component/Interpolation/Interpolator'

describe('#component Interpolator', function()
    local interpolator ---@type Interpolator
    before_each(function()
        interpolator = Interpolator:new()
        interpolator:setToken('empty', '')
        interpolator:setToken('number', '1')
        interpolator:setToken('token', 'value')
        interpolator:setToken('table', setmetatable({}, {
            __tostring = function() return 'tableValue' end,
        }))
    end)

    describe('#method', function()
        describe('convert', function()
            it('converts values to strings', function()
                assert.equal('', interpolator:convert(nil))
                assert.equal('', interpolator:convert(false))
                assert.equal('true', interpolator:convert(true))
                assert.equal('value', interpolator:convert('value'))
                assert.equal('1', interpolator:convert(1))
            end)

            it('converts multimaps if not allowing multimaps', function()
                interpolator = Interpolator:new({ allowMultiMaps = false })
                local mMap = MultiMap.fromList({ 'item' })
                assert.equal('item', interpolator:convert(mMap))
            end)

            it('does not convert multimaps if allowing multimaps', function()
                local mMap = MultiMap.fromList({ 'item', 'item2' })
                assert.equal(mMap, interpolator:convert(mMap))
            end)
        end)

        describe('convertLiteral', function()
            it('converts values to strings', function()
                assert.equal('', interpolator:convertLiteral(false))
                assert.equal('true', interpolator:convertLiteral(true))
                assert.equal('value', interpolator:convertLiteral('value'))
                assert.equal('1', interpolator:convertLiteral(1))
                assert.equal('table', interpolator:convertLiteral(setmetatable({}, {
                    __tostring = function() return 'table' end,
                })))
            end)
        end)

        describe('getTokens', function()
            it('returns a copy of the tokens table', function()
                interpolator:setToken('token', 'value')

                local tokens = interpolator._tokens
                local copy = interpolator:getTokens()

                assert.same(tokens, copy)
                assert.is_not_equal(tokens, copy)
            end)
        end)

        describe('interpolate', function()
            it('throws an error if interpolation pattern parsing fails', function()
                local InterpolationParser = require 'OmiLibrary/Component/Interpolation/InterpolateParser'
                local _parse = stub(InterpolationParser, 'parse', {
                    success = false,
                    errors = {
                        { message = 'error 1' },
                        { message = 'error 2' },
                    },
                }):auto_revert()

                assert.error(
                    function() interpolator:interpolate('$name') end,
                    'Failed to parse pattern `$name`: error 1, error 2'
                )

                assert.spy(_parse).called(1)
            end)
        end)

        describe('tokenBoolean', function()
            it('returns tokens as booleans', function()
                assert.equal(true, interpolator:tokenBoolean('number'))
                assert.equal(true, interpolator:tokenBoolean('token'))
                assert.equal(true, interpolator:tokenBoolean('table'))
            end)

            it('returns false for unknown tokens', function()
                assert.equal(false, interpolator:tokenBoolean('undefined'))
            end)

            it('returns false for tokens set to the empty string', function()
                assert.equal(false, interpolator:tokenBoolean('empty'))
            end)
        end)

        describe('tokenNumber', function()
            it('returns tokens as numbers', function()
                assert.equal(1, interpolator:tokenNumber('number'))
            end)

            it('returns nil for non-numeric tokens', function()
                assert.is_nil(interpolator:tokenNumber('empty'))
                assert.is_nil(interpolator:tokenNumber('token'))
                assert.is_nil(interpolator:tokenNumber('table'))
            end)

            it('returns nil for unknown tokens', function()
                assert.is_nil(interpolator:tokenNumber('undefined'))
            end)
        end)

        describe('tokenString', function()
            it('returns tokens as strings', function()
                assert.equal('', interpolator:tokenString('empty'))
                assert.equal('1', interpolator:tokenString('number'))
                assert.equal('value', interpolator:tokenString('token'))
                assert.equal('tableValue', interpolator:tokenString('table'))
            end)

            it('returns the empty string for unknown tokens', function()
                assert.equal('', interpolator:tokenString('undefined'))
            end)
        end)
    end)

    it('can use allowlist to include and exclude libraries', function()
        interpolator = Interpolator:new({ libraryInclude = { pz = true } })

        assert.is_nil(interpolator:getFunction('Add'))
        assert.is_nil(interpolator:getFunction('Str'))
        assert.is_nil(interpolator:getFunction('Map'))
        assert.is_nil(interpolator:getFunction('If'))
        assert.is_nil(interpolator:getFunction('Set'))

        assert.is_function(interpolator:getFunction('GetText'))
        assert.is_function(interpolator:getFunction('GetTextOrNull'))
    end)

    it('can load extra library functions', function()
        local testFunc = function() end
        interpolator = Interpolator:new({ libraryExtra = { Test = testFunc } })

        assert.is_function(interpolator:getFunction('Test'))
        assert.equal(testFunc, interpolator:getFunction('Test'))
    end)

    describe('can exclude', function()
        it('the boolean library', function()
            interpolator = Interpolator:new({ libraryExclude = { boolean = true } })

            assert.is_nil(interpolator:getFunction('EQ'))
            assert.is_nil(interpolator:getFunction('GT'))
            assert.is_nil(interpolator:getFunction('GTE'))
            assert.is_nil(interpolator:getFunction('If'))
            assert.is_nil(interpolator:getFunction('IfElse'))
            assert.is_nil(interpolator:getFunction('LT'))
            assert.is_nil(interpolator:getFunction('LTE'))
            assert.is_nil(interpolator:getFunction('NEQ'))
            assert.is_nil(interpolator:getFunction('Not'))
        end)

        it('the map library', function()
            interpolator = Interpolator:new({ libraryExclude = { map = true } })

            assert.is_nil(interpolator:getFunction('Get'))
            assert.is_nil(interpolator:getFunction('Has'))
            assert.is_nil(interpolator:getFunction('List'))
            assert.is_nil(interpolator:getFunction('Map'))
            assert.is_nil(interpolator:getFunction('NthValue'))
            assert.is_nil(interpolator:getFunction('Unique'))
        end)

        it('the math library', function()
            interpolator = Interpolator:new({ libraryExclude = { math = true } })

            assert.is_nil(interpolator:getFunction('Abs'))
            assert.is_nil(interpolator:getFunction('Add'))
            assert.is_nil(interpolator:getFunction('Ceil'))
            assert.is_nil(interpolator:getFunction('Div'))
            assert.is_nil(interpolator:getFunction('Floor'))
            assert.is_nil(interpolator:getFunction('Int'))
            assert.is_nil(interpolator:getFunction('Max'))
            assert.is_nil(interpolator:getFunction('Min'))
            assert.is_nil(interpolator:getFunction('Num'))
            assert.is_nil(interpolator:getFunction('Subtract'))
        end)

        it('the mutate library', function()
            interpolator = Interpolator:new({ libraryExclude = { mutate = true } })

            assert.is_nil(interpolator:getFunction('Choose'))
            assert.is_nil(interpolator:getFunction('Random'))
            assert.is_nil(interpolator:getFunction('Randomseed'))
            assert.is_nil(interpolator:getFunction('Set'))
        end)

        it('the string library', function()
            interpolator = Interpolator:new({ libraryExclude = { string = true } })

            assert.is_nil(interpolator:getFunction('Byte'))
            assert.is_nil(interpolator:getFunction('Capitalize'))
            assert.is_nil(interpolator:getFunction('Char'))
            assert.is_nil(interpolator:getFunction('EndsWith'))
            assert.is_nil(interpolator:getFunction('Punctuate'))
            assert.is_nil(interpolator:getFunction('StartsWith'))
            assert.is_nil(interpolator:getFunction('Str'))
            assert.is_nil(interpolator:getFunction('Sub'))
            assert.is_nil(interpolator:getFunction('Trim'))
        end)

        it('the PZ library', function()
            interpolator = Interpolator:new({ libraryExclude = { pz = true } })

            assert.is_nil(interpolator:getFunction('GetText'))
            assert.is_nil(interpolator:getFunction('GetTextOrNull'))
        end)
    end)
end)
