---Contains tests for the InterpolationParser component.
---@using omi
---@diagnostic disable: access-invisible

local BaseParser = require 'OmiLibrary/Component/Core/Parser'
local Parser = require 'OmiLibrary/Component/Interpolation/InterpolateParser'

describe('#component InterpolationParser #method', function()
    local parser ---@type InterpolateParser
    before_each(function()
        parser = Parser:new()
    end)

    describe('parse', function()
        it('returns an error result when an error occurs', function()
            stub(Parser, 'readExpression'):auto_revert()

            local result = parser:parse('hello')

            assert.is_table(result)
            assert.is_false(result.success)
            assert.is_true(#result.errors > 0)
        end)
    end)

    describe('readAtExpression', function()
        it('produces an error when unable to read an expression', function()
            local _errorHere = spy.on(BaseParser, 'errorHere')

            parser:reset('@(A)')
            stub(Parser, 'readExpression'):auto_revert()

            parser:readAtExpression()
            assert.spy(_errorHere).called_at_least(1)
        end)
    end)

    describe('readFunction', function()
        it('produces an error when unable to read an expression', function()
            local _errorHere = spy.on(BaseParser, 'errorHere')

            parser:reset('$func(arg)')
            stub(Parser, 'readExpression'):auto_revert()

            parser:readFunction()
            assert.spy(_errorHere).called_at_least(1)
        end)

        it('produces an error when unable to read a variable in an unterminated function', function()
            local _error = spy.on(BaseParser, 'error')

            parser:reset('$func(arg')
            stub(Parser, 'readVariable'):auto_revert()

            parser:readFunction()
            assert.spy(_error).called_at_least(1)
        end)
    end)

    describe('readSpecialText', function()
        it('returns nil when attempting to read a non-special string', function()
            parser:reset('A')
            assert.is_nil(parser:readSpecialText())
        end)
    end)
end)
