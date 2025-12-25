---Contains tests for the DelimitedList component.
---@using omi

local core = require 'OmiLibrary/Module/Utils'
local DelimitedList = require 'OmiLibrary/Component/Core/DelimitedList'

describe('#component DelimitedList', function()
    local _split ---@type luassert.spy
    local delimList ---@type DelimitedList
    before_each(function()
        delimList = DelimitedList:new({ source = 'a;b;c' })
        _split = spy.on(core, 'split')
    end)

    describe('#method', function()
        describe('list', function()
            it('converts to a list of strings', function()
                assert.same({ 'a', 'b', 'c' }, delimList:list())
            end)

            it('caches the result of the split function', function()
                delimList:list()
                assert.spy(_split).not_called()
            end)

            it('uses the given delimiter to split', function()
                delimList:setDelimiter(',')
                delimList:update('1,2,3')

                assert.same({ '1', '2', '3' }, delimList:list())
            end)

            it('auto-updates if given a source table', function()
                local source = { value = 'a;b;c' }
                local tableDelimList = DelimitedList:new({ table = source, source = 'value' })

                assert.same({ 'a', 'b', 'c' }, tableDelimList:list())

                source.value = 'd;e;f'
                local _update = spy.on(DelimitedList, 'update')

                local result = tableDelimList:list()

                assert.spy(_update).called(1)
                assert.same({ 'd', 'e', 'f' }, result)
            end)
        end)

        describe('setDelimiter', function()
            it('updates the delimiter', function()
                delimList:setDelimiter(',')

                assert.same({ 'a;b;c' }, delimList:list())
            end)

            it('does not update if setting to the same delimiter', function()
                local _update = spy.on(DelimitedList, 'update')
                delimList:setDelimiter(';')

                assert.spy(_update).not_called()
            end)

            it('auto-updates if given a source table', function()
                local source = { value = 'a;b,c;d' }
                local tableDelimList = DelimitedList:new({ table = source, source = 'value' })

                assert.same({ 'a', 'b,c', 'd' }, tableDelimList:list())

                local _update = spy.on(DelimitedList, 'update')

                tableDelimList:setDelimiter(',')

                assert.spy(_update).called(1)
                assert.same({ 'a;b', 'c;d' }, tableDelimList:list())
            end)
        end)

        describe('update', function()
            it('does not call the split function if the value is equivalent', function()
                delimList:update('a;b;c')
                delimList:update('   a;b;c   ')
                assert.spy(_split).not_called()
            end)

            it('invalidates its cached value and calls the split function if the value differs', function()
                delimList:update('1;2;3')
                assert.spy(_split).called(1)
            end)

            it('treats nil as the empty string in update when no source table is specified', function()
                delimList:update()
                assert.same({}, delimList:list())
            end)
        end)
    end)
end)
