---Contains tests for the OrderedSet component.
---@using omi
---@diagnostic disable: access-invisible

local OrderedSet = require 'OmiLibrary/Component/Set/OrderedSet'

describe('#component OrderedSet', function()
    local instance ---@type OrderedSet<string>
    before_each(function()
        local arr = { 'A', 'B', 'C', 'D' }
        instance = OrderedSet:new(arr)
    end)

    describe('#function', function()
        describe('add', function()
            it('adds the given item', function()
                local expected = { 'A', 'B', 'C', 'D', 'E' }
                instance:add('E')
                assert.same(expected, instance:list())
            end)

            it('does not add duplicate items', function()
                local expected = { 'A', 'B', 'C', 'D' }
                instance:add('D')
                assert.same(expected, instance:list())
            end)

            it('does not try to add nil', function()
                local expected = { 'A', 'B', 'C', 'D' }

                assert.no_error(function() instance:add(nil --[[@as any]]) end)
                assert.same(expected, instance:list())
            end)
        end)

        describe('clone', function()
            it('clones the OrderedSet', function()
                assert.same(instance:clone(), instance)
            end)

            it('returns a different instance', function()
                assert.is_not_equal(instance:clone(), instance)
            end)
        end)

        describe('elements', function()
            it('returns an iterator over set elements', function()
                local iterator = instance:elements()

                local value = iterator()
                assert.equal('A', value)

                value = iterator()
                assert.equal('B', value)

                value = iterator()
                assert.equal('C', value)

                value = iterator()
                assert.equal('D', value)

                value = iterator()
                assert.is_nil(value)
            end)
        end)

        describe('has', function()
            it('returns true if an element is present', function()
                assert.is_true(instance:has('A'))
                assert.is_true(instance:has('B'))
                assert.is_true(instance:has('C'))
                assert.is_true(instance:has('D'))
            end)

            it('returns false if an element if not present', function()
                assert.is_false(instance:has('E'))
                assert.is_false(instance:has('Z'))
            end)
        end)

        describe('insert', function()
            describe('can handle insertion', function()
                it('at the end', function()
                    local expected = { 'A', 'B', 'C', 'D', 'E' }
                    instance:insert('E', 5)
                    assert.same(expected, instance:list())
                end)

                it('at the beginning', function()
                    local expected = { 'Z', 'A', 'B', 'C', 'D' }
                    instance:insert('Z', 1)
                    assert.same(expected, instance:list())
                end)

                it('in the middle', function()
                    local expected = { 'A', 'B', 'Z', 'C', 'D' }
                    instance:insert('Z', 3)
                    assert.same(expected, instance:list())
                end)
            end)

            describe('can handle insertion of existing items', function()
                it('at the end', function()
                    local expected = { 'A', 'C', 'D', 'B' }
                    instance:insert('B', 4)
                    assert.same(expected, instance:list())
                end)

                it('at the beginning', function()
                    local expected = { 'B', 'A', 'C', 'D' }
                    instance:insert('B', 1)
                    assert.same(expected, instance:list())
                end)

                it('in the middle', function()
                    local expected = { 'A', 'C', 'B', 'D' }
                    instance:insert('B', 3)
                    assert.same(expected, instance:list())
                end)
            end)
        end)

        describe('pairs', function()
            it('returns an iterator over index-value pairs', function()
                local iterator = instance:pairs()

                local index, value = iterator()
                assert.equal(1, index)
                assert.equal('A', value)

                index, value = iterator()
                assert.equal(2, index)
                assert.equal('B', value)

                index, value = iterator()
                assert.equal(3, index)
                assert.equal('C', value)

                index, value = iterator()
                assert.equal(4, index)
                assert.equal('D', value)

                index, value = iterator()
                assert.is_nil(index)
                assert.is_nil(value)
            end)
        end)

        describe('remove', function()
            it('removes the given item', function()
                local expected = { A = true, B = true, D = true }
                instance:remove('C')
                assert.same(expected, instance:table())
            end)

            it('does not throw an error when removing an item that is not present', function()
                assert.no_error(function() instance:remove('Z') end)
            end)
        end)

        describe('size', function()
            it('returns the size of the set', function()
                assert.equal(4, instance:size())
            end)

            it('does not change when adding an existing element', function()
                instance:add('A')
                assert.equal(4, instance:size())
            end)

            it('does not change when removing an element that is not present', function()
                instance:remove('Z')
                assert.equal(4, instance:size())
            end)

            it('reflects size changes due to adding elements', function()
                instance:add('E')
                assert.equal(5, instance:size())
            end)

            it('reflects size changes due to removing elements', function()
                instance:remove('A')
                instance:remove('B')
                assert.equal(2, instance:size())
            end)
        end)

        describe('table', function()
            it('converts to a set table', function()
                local expected = { A = true, B = true, C = true, D = true }
                assert.same(expected, instance:table())
            end)
        end)
    end)

    describe('#operation', function()
        describe('__len', function()
            it('returns the size of the set', function()
                if not _VERSION:match('Lua 5.1') then
                    assert.equal(4, #instance)
                else
                    assert.equal(4, OrderedSet.__len(instance))
                end
            end)
        end)
    end)
end)
