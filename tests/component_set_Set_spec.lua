---Contains tests for the Set component.
---@using omi
---@diagnostic disable: access-invisible

local Set = require 'OmiLibrary/Component/Set/Set'

describe('#component Set', function()
    local instance ---@type Set<string>
    before_each(function()
        local arr = { 'A', 'B', 'C', 'D' }
        instance = Set:new(arr)
    end)

    describe('#function', function()
        describe('add', function()
            it('adds the given item', function()
                local expected = { A = true, B = true, C = true, D = true, E = true }
                instance:add('E')
                assert.same(expected, instance:table())
            end)

            it('does not try to add nil', function()
                local expected = { A = true, B = true, C = true, D = true }

                ---@diagnostic disable-next-line: param-type-mismatch
                assert.no_error(function() instance:add(nil) end)
                assert.same(expected, instance:table())
            end)
        end)

        describe('clone', function()
            it('clones the Set', function()
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
                assert.is_string(value)

                value = iterator()
                assert.is_string(value)

                value = iterator()
                assert.is_string(value)

                value = iterator()
                assert.is_string(value)

                value = iterator()
                assert.is_nil(value)
            end)
        end)

        describe('has', function()
            theory('returns true if an element is present', function(value)
                assert.is_true(instance:has(value))
            end, 'A', 'B', 'C', 'D')

            theory('returns false if an element if not present', function(value)
                assert.is_false(instance:has(value))
            end, 'GG', 'EZ', 'NO', 'RE')
        end)

        describe('remove', function()
            it('removes the given item', function()
                instance:remove('C')
                assert.same({ A = true, B = true, D = true }, instance:table())
            end)

            it('does not throw an error when removing an item that is not present', function()
                assert.no_error(function() instance:remove('Z') end)
            end)
        end)

        describe('size', function()
            it('returns the size of the set', function()
                assert.equal(4, instance:size())
            end)

            theory('does not change when adding an existing element', function(value)
                instance:add(value)
                assert.equal(4, instance:size())
            end, 'A', 'B', 'C', 'D')

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
                assert.same({ A = true, B = true, C = true, D = true }, instance:table())
            end)
        end)
    end)

    describe('#operation', function()
        describe('__len', function()
            it('returns the size of the set', function()
                if not _VERSION:match('Lua 5.1') then
                    assert.equal(4, #instance)
                else
                    assert.equal(4, Set.__len(instance))
                end
            end)
        end)
    end)
end)
