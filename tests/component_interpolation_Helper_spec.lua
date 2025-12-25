---Contains tests for interpolation library helper functions.
---@using omi
---@diagnostic disable: access-invisible

local MultiMap = require 'OmiLibrary/Component/Core/MultiMap'
local Interpolator = require 'OmiLibrary/Component/Interpolation/Interpolator'
local LibraryHelpers = require 'OmiLibrary/Component/Interpolation/Libraries/Helpers'

describe('interpolation library helper #function', function()
    local id ---@type luassert.spy
    local interpolator ---@type Interpolator
    before_each(function()
        interpolator = Interpolator:new()
        id = spy.new(function(...) return ... end)
    end)

    describe('argsToStrings', function()
        it('converts all arguments to strings using interpolator logic', function()
            local converted = LibraryHelpers.argsToStrings(id --[[@as function]])

            converted(interpolator, 1, true, false, 'string')

            assert.spy(id).called(1)
            assert.spy(id).called_with('1', 'true', '', 'string')
        end)

        it('respects the maxArgs argument', function()
            local converted = LibraryHelpers.argsToStrings(id --[[@as function]], 2)

            converted(interpolator, 1, 2, 3, 4)

            assert.spy(id).called(1)
            assert.spy(id).called_with('1', '2')
        end)
    end)

    describe('concatenateArgs', function()
        it('concatenates arguments into a single string', function()
            local converted = LibraryHelpers.concatenateArgs(id --[[@as function]])

            converted(interpolator, true, 'string', 1)

            assert.spy(id).called(1)
            assert.spy(id).called_with('truestring1')
        end)
    end)

    describe('firstToString', function()
        it('converts the first argument to a string and passes the rest as-is', function()
            local converted = LibraryHelpers.firstToString(id --[[@as function]])

            converted(interpolator, true, 1, 2)

            assert.spy(id).called(1)
            assert.spy(id).called_with('true', 1, 2)
        end)
    end)

    describe('try', function()
        it('returns function results if no error occurred', function()
            local a, b = LibraryHelpers.try(id --[[@as function]], 1, 2)

            assert.spy(id).called(1)
            assert.spy(id).called_with(1, 2)
            assert.equal(1, a)
            assert.equal(2, b)
        end)

        it('returns nil if an error occurred', function()
            local errFunc = spy.new(function() error('fail') end)
            local a, b = LibraryHelpers.try(errFunc --[[@as function]], 1, 2)

            assert.spy(errFunc).called(1)
            assert.spy(errFunc).called_with(1, 2)
            assert.is_nil(a)
            assert.is_nil(b)
        end)
    end)

    describe('tryList', function()
        it('returns function results as a map if no error occurred', function()
            local result = LibraryHelpers.tryList(
                id --[[@as function]], interpolator, 1, 2
            ) --[[@as MultiMap]]

            assert.spy(id).called(1)
            assert.spy(id).called_with(1, 2)
            assert.is_instance(result, MultiMap)
            assert.equal(2, result:size())
        end)

        it('returns nil if an error occurred', function()
            local errFunc = spy.new(function() error('fail') end)
            local result = LibraryHelpers.tryList(errFunc --[[@as function]], interpolator, 1, 2)

            assert.spy(errFunc).called(1)
            assert.spy(errFunc).called_with(1, 2)
            assert.is_nil(result)
        end)
    end)
end)
