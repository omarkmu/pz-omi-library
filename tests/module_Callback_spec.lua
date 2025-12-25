---Contains tests for the callback module.
---@using omi

local callback = require 'OmiLibrary/Module/Callback'

local TARGET = {}
local CB_ZERO = function() return 0 end

describe('#function callback', function()
    it('calls the create function with the given arguments', function()
        local s = spy.on(callback, 'create')

        callback(TARGET, CB_ZERO, 1, 2)
        assert.spy(s).called_with(TARGET, CB_ZERO, 1, 2)
    end)
end)

describe('#module calback #function', function()
    describe('create', function()
        it('returns nil if no callback function is passed', function()
            assert.is_nil(callback.create())
        end)

        it('returns a callback info object', function()
            local info = callback.create(TARGET, CB_ZERO, 1, 2) --[[@as CallbackInfo]]

            assert.is_not_nil(info)
            assert.equal(TARGET, info.target)
            assert.equal(CB_ZERO, info.callback)
            assert.same({ 1, 2, n = 2 }, info.args)
        end)

        it('returns a callback info object with gaps in its arguments table', function()
            local info = callback.create(TARGET, CB_ZERO, 1, nil, 3) --[[@as CallbackInfo]]

            assert.is_not_nil(info)
            assert.equal(TARGET, info.target)
            assert.equal(CB_ZERO, info.callback)
            assert.same({ 1, [3] = 3, n = 3 }, info.args)
        end)
    end)

    describe('invoke', function()
        it('returns nil when given nil', function()
            assert.is_nil(callback.invoke())
        end)

        it('returns nil when given a table without a callback field', function()
            assert.is_nil(callback.invoke({ args = {} }))
        end)

        it('invokes the callback with the bound arguments', function()
            local info = callback.create(TARGET, CB_ZERO, 1, nil, 3)
            local s = spy.on(info --[[@as table]], 'callback')

            callback.invoke(info)

            assert.spy(s).called(1)
            assert.spy(s).called_with(TARGET, 1, nil, 3)
        end)

        it('invokes the callback with provided prefix arguments before bound arguments', function()
            local info = callback.create(TARGET, CB_ZERO, 1)
            local s = spy.on(info --[[@as table]], 'callback')

            callback.invoke(info, -1, 0)

            assert.spy(s).called(1)
            assert.spy(s).called_with(TARGET, -1, 0, 1)
        end)
    end)

    describe('safeInvoke', function()
        it('returns a success boolean before return values', function()
            local info = callback.create(TARGET, CB_ZERO)

            local success, result = callback.safeInvoke(info)

            assert.is_true(success)
            assert.equal(0, result)
        end)

        it('returns false and the error if the callback throws an error', function()
            local errorCb = function() error('callback error') end
            local info = callback.create(TARGET, errorCb)

            local success, result ---@type boolean, string
            assert.no_error(function()
                success, result = callback.safeInvoke(info)
            end)

            assert.is_false(success)
            assert.is_string(result)
            assert.match('callback error', result)
        end)
    end)
end)
