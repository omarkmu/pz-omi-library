---Contains tests for the dispatch module.
---@using omi

local dispatch = require 'OmiLibrary/Module/Dispatch'

describe('#function dispatch', function()
    it('calls the dispatch.new function with the given arguments', function()
        local s = spy.on(dispatch, 'new')

        local args = {}
        dispatch(args --[[@as Args.Dispatcher]])
        assert.spy(s).called_with(match.ref(args))
    end)
end)

describe('#module dispatch #function', function()
    describe('new', function()
        it('returns a Dispatcher', function()
            local instance = dispatch.new({ module = 'modname' })
            assert.is_instance(instance, dispatch.Dispatcher)
        end)
    end)
end)
