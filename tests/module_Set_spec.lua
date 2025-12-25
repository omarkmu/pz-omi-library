---Contains tests for the set module.
---@using omi

local set = require 'OmiLibrary/Module/Set'
local Set = require 'OmiLibrary/Component/Set/Set'
local OrderedSet = require 'OmiLibrary/Component/Set/OrderedSet'

describe('#function set', function()
    it('calls the set.new function with the given arguments', function()
        local s = spy.on(set, 'new'):auto_revert()

        local source = { 1, 2, 3 }
        set(source)
        assert.spy(s).called_with(match.ref(source))
    end)
end)

describe('#module set #function', function()
    describe('new', function()
        it('creates a new Set', function()
            assert.is_instance(set.new(), Set)
        end)
    end)

    describe('ordered', function()
        it('creates a new OrderedSet', function()
            assert.is_instance(set.ordered(), OrderedSet)
        end)
    end)

    describe('table', function()
        it('returns an empty table if no source is given', function()
            assert.same({}, set.table())
        end)

        it('returns a table with the source table keys', function()
            assert.same({ A = true, B = true }, set.table { 'A', 'B' })
        end)
    end)
end)
