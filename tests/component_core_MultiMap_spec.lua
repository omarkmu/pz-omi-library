---Contains tests for the MultiMap component.
---@using omi
---@diagnostic disable: access-invisible

local MultiMap = require 'OmiLibrary/Component/Core/MultiMap'

describe('#component MultiMap', function()
    local map ---@type MultiMap
    before_each(function()
        map = MultiMap.fromList({
            'item1',
            'item2',
            'item3',
        })
    end)

    describe('#function', function()
        describe('fromList', function()
            it('creates a multimap from a list', function()
                assert.equal(3, map:size())
                assert.equal('item1', map:get(1))
                assert.equal('item2', map:get(2))
                assert.equal('item3', map:get(3))
            end)

            it('returns an empty multimap if given nil', function()
                map = MultiMap.fromList()
                assert.equal(0, map:size())
            end)
        end)

        describe('fromSet', function()
            it('creates a multimap from a set', function()
                map = MultiMap.fromSet({
                    ['item1'] = true,
                    ['item2'] = true,
                })

                assert.equal(2, map:size())
                assert.equal('item1', map:get('item1'))
                assert.equal('item2', map:get('item2'))
            end)

            it('returns an empty multimap if given nil', function()
                map = MultiMap.fromSet()
                assert.equal(0, map:size())
            end)
        end)
    end)

    describe('#method', function()
        describe('concat', function()
            it('concatenates values into a string', function()
                assert.equal('item1item2item3', map:concat(''))
                assert.equal('item1,item2,item3', map:concat(','))
            end)

            theory('respects given start and end indices', function(args)
                assert.equal(args.expected, map:concat(',', args.i, args.j))
            end, {
                { expected = 'item3', i = 3 },
                { expected = 'item2,item3', i = 2 },
                { expected = 'item2,item3', i = 2, j = 3 },
                { expected = 'item1,item2,item3', i = 1 },
                { expected = 'item1,item2', i = 1, j = 2 },
                { expected = 'item1,item2,item3', i = 1, j = 3 },
            })
        end)

        describe('entry', function()
            it('returns an entry as a key-value pair', function()
                assert.same({ 2, 'item2' }, map:entry(2))
            end)
        end)

        describe('first', function()
            it('returns the first entry value', function()
                assert.equal('item1', map:first())
            end)
        end)

        describe('get', function()
            it('returns nil or a default value for a key with no entries', function()
                assert.is_nil(map:get('unknown'))
                assert.equal('DEFAULT', map:get('unknown', 'DEFAULT'))
            end)
        end)

        describe('getBoolean', function()
            before_each(function()
                map = MultiMap:new(map, { { 4, '' } })
            end)

            theory('gets values as booleans', function(value)
                assert.is_true(map:getBoolean(value))
            end, 1, 2, 3)

            it('returns false for the empty string', function()
                assert.is_false(map:getBoolean(4))
            end)

            it('returns false for unknown keys', function()
                assert.is_false(map:getBoolean('unknown'))
            end)
        end)

        describe('getNumber', function()
            before_each(function()
                map = MultiMap:new(map, { { 4, '4' } })
            end)

            it('gets values as numbers', function()
                assert.equal(4, map:getNumber(4))
            end)

            theory('returns 0 for non-numeric values', function(value)
                assert.equal(0, map:getNumber(value))
            end, 1, 2, 3)

            theory('returns 0 for non-numeric values when called with a default', function(value)
                assert.equal(0, map:getNumber(value, 100))
            end, 1, 2, 3)

            it('returns 0 for unknown keys', function()
                assert.equal(0, map:getNumber('unknown'))
            end)

            it('returns the given default value for unknown keys', function()
                assert.equal(100, map:getNumber('unknown', 100))
            end)
        end)

        describe('getString', function()
            before_each(function()
                map = MultiMap.fromList({ 1, 2, 3 })
            end)

            theory('gets values as strings', function(value)
                assert.equal(tostring(value), map:getString(value))
            end, 1, 2, 3)

            theory('gets values as strings when called with a default', function(value)
                assert.equal(tostring(value), map:getString(value, 'DEFAULT'))
            end, 1, 2, 3)

            it('returns the empty string for unknown keys', function()
                assert.equal('', map:getString('unknown'))
            end)

            it('returns the given default value for unknown keys', function()
                assert.equal('DEFAULT', map:getString('unknown', 'DEFAULT'))
            end)
        end)

        describe('has', function()
            theory('returns true for existing keys', function(value)
                assert.is_true(map:has(value))
            end, 1, 2, 3)

            theory('returns false for unknown keys', function(value)
                assert.is_false(map:has(value))
            end, {
                '',
                'unknown',
                'undefined',
            })
        end)

        describe('index', function()
            it('returns a list-style multimap of values associated with a key', function()
                local items = map:index(1) --[[@as MultiMap]]

                assert.is_instance(items, MultiMap)
                assert.equal(1, items:size())
            end)

            it('returns nil or a default value for a key with no entries', function()
                assert.is_nil(map:index('unknown'))
                assert.equal('DEFAULT', map:index('unknown', 'DEFAULT'))
            end)
        end)

        describe('keys', function()
            it('returns an iterator over keys', function()
                local iterator = map:keys()

                assert.equal(1, iterator())
                assert.equal(2, iterator())
                assert.equal(3, iterator())
                assert.is_nil(iterator())
            end)
        end)

        describe('last', function()
            it('returns the last entry value', function()
                assert.equal('item3', map:last())
            end)
        end)

        describe('pairs', function()
            it('returns an iterator over key-value pairs', function()
                local iterator = map:pairs()

                local key, value = iterator()
                assert.equal(1, key)
                assert.equal('item1', value)

                key, value = iterator()
                assert.equal(2, key)
                assert.equal('item2', value)

                key, value = iterator()
                assert.equal(3, key)
                assert.equal('item3', value)

                assert.is_nil(iterator())
            end)
        end)

        describe('size', function()
            it('returns the number of entries', function()
                assert.equal(3, map:size())
            end)
        end)

        describe('toOptions', function()
            it('converts to a copy that evaluates boolean false from case-insensitive strings', function()
                map = MultiMap:new(map, { { 4, 'false' }, { 5, 'False' } })
                local options = map:toOptions()

                assert.equal(5, options:size())
                assert.equal('item1', options:get(1))
                assert.equal('item2', options:get(2))
                assert.equal('item3', options:get(3))
                assert.is_false(options:get(4))
                assert.is_false(options:get(5))
                assert.is_nil(options:get(6))
            end)
        end)

        describe('toValueSet', function()
            it('converts to a simple set of values', function()
                assert.same({
                    item1 = true,
                    item2 = true,
                    item3 = true,
                }, map:toValueSet())
            end)
        end)

        describe('unique', function()
            it('returns a multimap of unique values', function()
                map = MultiMap:new(map, { { 4, 'item1' } })
                map = map:unique()

                assert.equal(3, map:size())
                assert.equal('item1', map:get(1))
                assert.equal('item2', map:get(2))
                assert.equal('item3', map:get(3))
                assert.is_nil(map:get(4))
            end)
        end)

        describe('values', function()
            it('returns an iterator over values', function()
                local iterator = map:values()

                assert.equal('item1', iterator())
                assert.equal('item2', iterator())
                assert.equal('item3', iterator())
                assert.is_nil(iterator())
            end)
        end)

        describe('withSet', function()
            it('creates a copy with additional set values', function()
                local copy = map:withSet({
                    item4 = true,
                    item5 = true,
                })

                assert.equal('item1', copy:get(1))
                assert.equal('item2', copy:get(2))
                assert.equal('item3', copy:get(3))
                assert.equal('item4', copy:get('item4'))
                assert.equal('item5', copy:get('item5'))
            end)
        end)

        describe('withSetValue', function()
            it('creates a copy with one additional set value', function()
                local copy = map:withSetValue('item4')

                assert.equal('item1', copy:get(1))
                assert.equal('item2', copy:get(2))
                assert.equal('item3', copy:get(3))
                assert.equal('item4', copy:get('item4'))
            end)
        end)
    end)

    describe('#operation', function()
        describe('__len', function()
            it('returns the size of the multimap', function()
                if not _VERSION:match('Lua 5.1') then
                    assert.equal(3, #map)
                else
                    assert.equal(3, MultiMap.__len(map))
                end
            end)
        end)

        describe('__tostring', function()
            it('only uses the first value', function()
                assert.equal('item1', tostring(map))
            end)
        end)
    end)
end)
