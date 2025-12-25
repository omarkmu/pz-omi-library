---Contains tests for the Cache component.
---@using omi

local cache = require 'OmiLibrary/Module/Cache'

---Creates a basic test cache containing named items.
---@param args Args.Cache.Base?
---@return Cache<{ name: string }>
local function createNameCache(args)
    args = args or {} --[[@as Args.Cache<{ name: string }>]]
    args.primaryKey = 'name'

    return cache.new(args)
end

---Creates a basic test cache containing integer values.
---@param count integer
---@param args Args.Cache.Base?
---@return Cache<{ value: integer }>
local function createValueCache(count, args)
    args = args or {} --[[@as Args.Cache<{ value: integer }>]]
    args.primaryKey = 'value'

    local valueCache = cache.new(args)
    for i = 1, count do
        zomboid.set_timestamp(i * 1000)
        valueCache:set(i, { value = i })
    end

    return valueCache
end

describe('#component Cache #method', function()
    teardown(zomboid.revert_timestamp)

    describe('clear', function()
        it('removes all items', function()
            local valueCache = createValueCache(3)
            assert.equal(3, valueCache:count())

            valueCache:clear()
            assert.equal(0, valueCache:count())
        end)
    end)

    describe('count', function()
        it('returns the number of elements in the cache', function()
            local valueCache = createValueCache(5)
            assert.equal(5, valueCache:count())
        end)
    end)

    describe('defaultCreateItemData', function()
        it('returns nil', function()
            local valueCache = createValueCache(0)
            assert.is_nil(valueCache:defaultCreateItemData('value', 1))
        end)
    end)

    describe('fromList', function()
        it('clears existing cache items', function()
            local _clear = spy.on(cache.Cache, 'clear')
            local valueCache = createValueCache(1)

            valueCache:fromList({ { value = 5 } })

            assert.spy(_clear).called(1)
        end)

        it('populates items from a list', function()
            local valueCache = createValueCache(0)

            valueCache:fromList({
                { value = 1 },
                { value = 2 },
                { value = 3 },
            })

            assert.equal(3, valueCache:count())
            assert.same({ value = 1 }, valueCache:get(1))
            assert.same({ value = 2 }, valueCache:get(2))
            assert.same({ value = 3 }, valueCache:get(3))
        end)
    end)

    describe('fromMap', function()
        it('clears existing cache items', function()
            local _clear = spy.on(cache.Cache, 'clear')
            local nameCache = createNameCache()

            nameCache:fromMap({ Alice = { name = 'Alice' } })

            assert.spy(_clear).called(1)
        end)

        it('populates items from a map', function()
            local nameCache = createNameCache()

            nameCache:fromMap({
                Alice = { name = 'Alice' },
                Bob = { name = 'Bob' },
                Charlie = { name = 'Charlie' },
            })

            assert.equal(3, nameCache:count())
            assert.same({ name = 'Alice' }, nameCache:get('Alice'))
            assert.same({ name = 'Bob' }, nameCache:get('Bob'))
            assert.same({ name = 'Charlie' }, nameCache:get('Charlie'))
        end)
    end)

    describe('get', function()
        it('calls getByIndex with the primary key', function()
            local _getByIndex = spy.on(cache.Cache, 'getByIndex')
            local valueCache = createValueCache(1)

            local result = valueCache:get(1, false)

            assert.same({ value = 1 }, result)
            assert.spy(_getByIndex).called_with(match.ref(valueCache), 'value', 1, false)
        end)

        it('returns nil for unknown indexes', function()
            local valueCache = createValueCache(1)
            assert.is_nil(valueCache:getByIndex('unknown', 1))
        end)

        it('attempts to create cache items on cache miss', function()
            local s = spy.on(cache.Cache, '_createItem')

            local valueCache = createValueCache(0)
            valueCache:get(1)

            assert.spy(s).called(1)
        end)

        it('does not attempt to create cache items on cache miss when passed a flag', function()
            local s = spy.on(cache.Cache, '_createItem')

            local valueCache = createValueCache(0)
            valueCache:get(1, false)

            assert.equal(0, valueCache:count())
            assert.spy(s).not_called()
        end)

        it('calls the given callback on cache miss', function()
            local valueCache = createValueCache(1, {
                onCreateItem = function(_, key, index)
                    if index == 'value' then
                        return { value = key }
                    end
                end,
            })

            assert.same({
                { value = 1 },
            }, valueCache:toList())

            assert.same({ value = 2 }, valueCache:get(2))

            assert.same({
                { value = 1 },
                { value = 2 },
            }, valueCache:toList())
        end)

        it('calls the onCreateItem callback when creating item data', function()
            local f = spy.new(function() return {} end)

            local valueCache = createValueCache(1, {
                onCreateItem = f --[[@as function]],
            })

            valueCache:get(2)

            assert.spy(f).called(1)
        end)
    end)

    describe('getByIndex', function()
        it('returns a value given an index', function()
            local multiCache = cache.new {
                primaryKey = 'value',
                indexes = { 'name' },
            }

            multiCache:set(1, { value = 1, name = 'One' })
            multiCache:set(2, { value = 2, name = 'Two' })

            assert.same({ value = 1, name = 'One' }, multiCache:get(1))
            assert.same({ value = 1, name = 'One' }, multiCache:getByIndex('name', 'One'))
            assert.same({ value = 2, name = 'Two' }, multiCache:getByIndex('name', 'Two'))
            assert.is_nil(multiCache:getByIndex('name', 'Three'))
        end)
    end)

    describe('getPrimaryValue', function()
        it('returns the value of the primary key', function()
            local multiCache = cache.new {
                primaryKey = 'value',
                indexes = { 'name' },
            }

            multiCache:set(1, { value = 1, name = 'One' })
            multiCache:set(2, { value = 2, name = 'Two' })

            assert.equal(1, multiCache:getPrimaryValue('name', 'One'))
            assert.equal(2, multiCache:getPrimaryValue('name', 'Two'))
            assert.is_nil(multiCache:getPrimaryValue('name', 'Three'))
        end)
    end)

    describe('getRequired', function()
        it('returns a cache item if present', function()
            local valueCache = createValueCache(1)
            assert.same({ value = 1 }, valueCache:getRequired(1))
        end)

        it('throws an error if the cache item could not be retrieved', function()
            local valueCache = createValueCache(0)
            assert.error(function() valueCache:getRequired(1) end)
        end)
    end)

    describe('has', function()
        it('checks for presence of items', function()
            local valueCache = createValueCache(2)

            assert.is_true(valueCache:has(1))
            assert.is_true(valueCache:has(2))
            assert.is_false(valueCache:has(3))
        end)

        it('returns false for unknown indexes', function()
            local valueCache = createValueCache(1)
            assert.is_false(valueCache:has(1, 'unknown'))
        end)
    end)

    describe('iterate', function()
        it('allows iteration over cache items', function()
            local valueCache = createValueCache(3)

            local iterator = valueCache:iterate()

            local key, value = iterator()
            assert.is_number(key)
            assert.between(1, 3, key)
            assert.is_table(value)

            key, value = iterator()
            assert.is_number(key)
            assert.between(1, 3, key)
            assert.is_table(value)

            key, value = iterator()
            assert.is_number(key)
            assert.between(1, 3, key)
            assert.is_table(value)

            key, value = iterator()
            assert.is_nil(key)
            assert.is_nil(value)
        end)
    end)

    describe('remove', function()
        it('fails for unknown indexes', function()
            local valueCache = createValueCache(1)
            assert.is_nil(valueCache:removeByIndex('unknown', 1))
        end)
    end)

    describe('set', function()
        it('calls setByIndex with the primary key', function()
            local _setByIndex = spy.on(cache.Cache, 'setByIndex')
            local valueCache = createValueCache(1)

            local data = { value = 2 }
            local result = valueCache:set(2, data)

            assert.is_true(result)
            assert.spy(_setByIndex).called_with(match.ref(valueCache), 'value', 2, match.ref(data))
        end)

        it('removes items to respect the given capacity', function()
            local valueCache = createValueCache(3, { capacity = 3 })
            assert.equal(3, valueCache:count())

            valueCache:set(4, { value = 4 })
            assert.equal(3, valueCache:count())
        end)

        it('removes the least recently accessed item when removing for capacity', function()
            local valueCache = createValueCache(3, { capacity = 3 })

            valueCache:get(1) -- 1 is more recently accessed than 2

            zomboid.set_timestamp(4000)
            valueCache:set(4, { value = 4 })

            assert.same({
                { value = 1 },
                { value = 3 },
                { value = 4 },
            }, valueCache:toList())
        end)

        it('removes the oldest item when removing for capacity in non-lru mode', function()
            local valueCache = createValueCache(3, {
                capacity = 3,
                lru = false,
            })

            valueCache:set(4, { value = 4 })

            assert.same({
                { value = 2 },
                { value = 3 },
                { value = 4 },
            }, valueCache:toList())
        end)

        it('fails for unknown indexes', function()
            local valueCache = createValueCache(1)
            assert.is_false(valueCache:setByIndex('unknown', 2, { value = 2 }))
        end)
    end)

    describe('toList', function()
        it('converts the cache into a list of items', function()
            local valueCache = createValueCache(3)

            assert.same({
                { value = 1 },
                { value = 2 },
                { value = 3 },
            }, valueCache:toList())
        end)
    end)

    describe('toMap', function()
        it('converts the cache into a map of primary keys to items', function()
            local nameCache = createNameCache()

            nameCache:set('Alice', { name = 'Alice' })
            nameCache:set('Bob', { name = 'Bob' })
            nameCache:set('Charlie', { name = 'Charlie' })

            assert.same({
                Alice = { name = 'Alice' },
                Bob = { name = 'Bob' },
                Charlie = { name = 'Charlie' },
            }, nameCache:toMap())
        end)
    end)

    describe('update', function()
        it('removes expired items', function()
            local valueCache = createValueCache(4, { capacity = 4, ttl = 2000 })

            valueCache:update()
            assert.equal(2, valueCache:count())

            assert.same({
                { value = 3 },
                { value = 4 },
            }, valueCache:toList())
        end)

        it('does not remove items if no TTL is given', function()
            local valueCache = createValueCache(4, { capacity = 4 })

            valueCache:update()
            assert.equal(4, valueCache:count())

            assert.same({
                { value = 1 },
                { value = 2 },
                { value = 3 },
                { value = 4 },
            }, valueCache:toList())
        end)
    end)
end)
