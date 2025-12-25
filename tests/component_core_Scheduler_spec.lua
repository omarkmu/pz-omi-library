---Contains tests for the Scheduler component.
---@using omi
---@diagnostic disable: access-invisible, duplicate-require

local TICK_EVENT = 'OnTickEvenPaused'

local Scheduler = require 'OmiLibrary/Component/Core/Scheduler'

describe('#component Scheduler', function()
    ---Helper function to switch to a server context.
    local function switchToServer()
        zomboid.set_is_server(true)
        Scheduler = reload_module('OmiLibrary/Component/Core/Scheduler')
    end

    ---Helper function to switch back from a server context.
    local function switchToClient()
        zomboid.set_is_server(false)
        Scheduler = reload_module('OmiLibrary/Component/Core/Scheduler')
    end

    local instance ---@type Scheduler
    before_each(function()
        instance = Scheduler:new()
        zomboid.set_timestamp(0)
        triggerEvent('OnGameStart')
    end)

    after_each(zomboid.revert)

    describe('#method', function()
        describe('clear', function()
            it('cancels connected timers', function()
                local timer1 = instance:setTimeout(100, function() end)
                local timer2 = instance:setTimeout(500, function() end)
                local timer3 = instance:setInterval(100, function() end)
                local timer4 = instance:setInterval(500, function() end)
                local timer5 = instance:setIntervalUI(function() end)

                instance:clear()

                assert.is_true(timer1.isCancelled)
                assert.is_true(timer2.isCancelled)
                assert.is_true(timer3.isCancelled)
                assert.is_true(timer4.isCancelled)
                assert.is_true(timer5.isCancelled)
            end)

            it('disconnects from the tick listener', function()
                local _OnTickEvenPaused_Remove = spy.on(Events.OnTickEvenPaused, 'Remove')

                instance:setTimeout(100, function() end)
                instance:clear()

                assert.spy(_OnTickEvenPaused_Remove).called(1)
            end)
        end)

        describe('setInterval', function()
            it('adds a repeating timer', function()
                zomboid.set_timestamp(400)

                local f = function() end
                local timer = instance:setInterval(100, f)

                local expected = {
                    value = 100,
                    target = 500,
                    isInterval = true,
                    isCancelled = false,
                    func = {
                        callback = f,
                        args = { n = 0 },
                    },
                }

                assert.same(expected, timer)
            end)

            it('callback is called on an interval', function()
                local f = spy.new()

                instance:setInterval(100, f --[[@as function]])

                zomboid.set_timestamp(100)
                triggerEvent(TICK_EVENT)

                zomboid.set_timestamp(200)
                triggerEvent(TICK_EVENT)

                assert.spy(f).called(2)
            end)

            it('throws an error when no callback is provided', function()
                ---@diagnostic disable-next-line: missing-parameter
                assert.error(function() instance:setInterval() end, 'Cannot add a timer with no callback')
            end)
        end)

        describe('setIntervalUI', function()
            it('adds a repeating timer', function()
                zomboid.set_timestamp(400)

                local f = function() end
                local timer = instance:setIntervalUI(f)

                local expected = {
                    value = 0,
                    target = 0,
                    isInterval = true,
                    isCancelled = false,
                    func = {
                        callback = f,
                        args = { n = 0 },
                    },
                }

                assert.same(expected, timer)
            end)

            it('callback is called on every UI update', function()
                local f = spy.new()

                instance:setIntervalUI(f --[[@as function]])

                zomboid.trigger_update_ui(100)
                zomboid.trigger_update_ui(200)
                zomboid.trigger_update_ui(300)

                assert.spy(f).called(3)
            end)

            it('callback is not called on tick updates', function()
                local f = spy.new()

                instance:setIntervalUI(f --[[@as function]])

                zomboid.set_timestamp(100)
                triggerEvent(TICK_EVENT)

                zomboid.set_timestamp(200)
                triggerEvent(TICK_EVENT)

                assert.spy(f).not_called()
            end)

            it('throws an error when no callback is provided', function()
                ---@diagnostic disable-next-line: missing-parameter
                assert.error(function() instance:setIntervalUI() end, 'Cannot add a timer with no callback')
            end)

            describe('when used on the server', function()
                setup(switchToServer)
                teardown(switchToClient)

                it('throws an error', function()
                    assert.error(
                        function()
                            instance:setIntervalUI(function() end)
                        end,
                        'setIntervalUI cannot be used on the server'
                    )
                end)
            end)
        end)

        describe('setTimeout', function()
            it('adds a non-repeating timer', function()
                zomboid.set_timestamp(400)

                local f = function() end
                local timer = instance:setTimeout(100, f)

                local expected = {
                    value = 100,
                    target = 500,
                    isInterval = false,
                    isCancelled = false,
                    func = {
                        callback = f,
                        args = { n = 0 },
                    },
                }

                assert.same(expected, timer)
            end)

            it('callback is called after the given delay', function()
                local f = spy.new()

                instance:setTimeout(100, f --[[@as function]])

                zomboid.set_timestamp(100)
                triggerEvent(TICK_EVENT)

                assert.spy(f).called(1)
            end)

            it('throws an error when no callback is provided', function()
                ---@diagnostic disable-next-line: missing-parameter
                assert.error(function() instance:setTimeout() end, 'Cannot add a timer with no callback')
            end)
        end)

        describe('_update', function()
            it('reconnects the tick listener for new tick-bound timers', function()
                local _OnTickEvenPaused_Add = spy.on(Events.OnTickEvenPaused, 'Add')
                local _OnTickEvenPaused_Remove = spy.on(Events.OnTickEvenPaused, 'Remove')

                instance:setTimeout(100, function() end)
                instance:setTimeout(150, function() end)
                instance:setTimeout(200, function() end)

                assert.spy(_OnTickEvenPaused_Add).called(3)
                assert.spy(_OnTickEvenPaused_Remove).called(2)
            end)

            it('disconnects the tick listener if there are no active timers', function()
                local _OnTickEvenPaused_Remove = spy.on(Events.OnTickEvenPaused, 'Remove')

                -- add and immediately cancel a timer
                local timer = instance:setTimeout(100, function() end)
                timer:cancel()

                triggerEvent(TICK_EVENT) -- update 1 removes the timer from the list
                triggerEvent(TICK_EVENT) -- update 2 cancels the listener

                assert.spy(_OnTickEvenPaused_Remove).called(1)
            end)

            it('does not throw an error if an error occurs in a callback', function()
                local f = spy.new(function() error('bad callback') end)

                instance:setTimeout(100, f --[[@as function]])

                zomboid.set_timestamp(100)

                assert.no_error(function() triggerEvent(TICK_EVENT) end)
                assert.spy(f).called(1)
            end)

            it('is called with false when the tick listener is triggered', function()
                local _update = spy.on(Scheduler, '_update')

                instance:setTimeout(100, function() end)
                triggerEvent(TICK_EVENT)

                assert.spy(_update).called(1)
                assert.spy(_update).called_with(match.ref(instance), false)
            end)

            it('is called with true when a UI update occurs', function()
                local _update = spy.on(Scheduler, '_update')

                instance:setTimeout(300, function() end)

                zomboid.trigger_update_ui(100)

                assert.spy(_update).called(1)
                assert.spy(_update).called_with(match.ref(instance), true)
            end)

            it('removes cancelled UI interval timers', function()
                local timer = instance:setIntervalUI(function() end)
                assert.is_true(instance._uiIntervalTimers[timer])

                timer:cancel()
                zomboid.trigger_update_ui(100)

                assert.is_nil(instance._uiIntervalTimers[timer])
            end)
        end)
    end)

    describe('when used on the client', function()
        it('connects to game boot and game start events', function()
            local _OnGameBoot_Add = spy.on(Events.OnGameBoot, 'Add')
            local _OnGameStart_Add = spy.on(Events.OnGameStart, 'Add')

            Scheduler:new()

            assert.spy(_OnGameBoot_Add).called(1)
            assert.spy(_OnGameStart_Add).called(1)
        end)

        it('creates a UI element on game boot', function()
            local _createUI = spy.on(Scheduler, '_createUI')

            triggerEvent('OnGameBoot')
            assert.spy(_createUI).called(1)
            assert.spy(_createUI).called_with(match.ref(instance))
        end)

        it('creates a UI element on game start', function()
            local _createUI = spy.on(Scheduler, '_createUI')

            triggerEvent('OnGameStart')
            assert.spy(_createUI).called(1)
            assert.spy(_createUI).called_with(match.ref(instance))
        end)

        it('connects to OnTickEvenPaused if the timer value is <250', function()
            local _OnTickEvenPaused_Add = spy.on(Events.OnTickEvenPaused, 'Add')

            instance:setInterval(200, function() end)

            assert.spy(_OnTickEvenPaused_Add).called(1)
        end)

        it('does not connect to OnTickEvenPaused if the timer value is 250', function()
            local _OnTickEvenPaused_Add = spy.on(Events.OnTickEvenPaused, 'Add')

            instance:setInterval(250, function() end)

            assert.spy(_OnTickEvenPaused_Add).not_called()
        end)

        it('does not connect to OnTickEvenPaused if the timer value is >250ms', function()
            local _OnTickEvenPaused_Add = spy.on(Events.OnTickEvenPaused, 'Add')

            instance:setInterval(300, function() end)

            assert.spy(_OnTickEvenPaused_Add).not_called()
        end)

        it('switches from UI-bound to tick-bound for timers with <250ms remaining', function()
            local _OnTickEvenPaused_Add = spy.on(Events.OnTickEvenPaused, 'Add')

            instance:setTimeout(300, function() end)

            assert.equal(1, #instance._uiUpdateTimers)
            assert.equal(0, #instance._tickTimers)

            zomboid.trigger_update_ui(100)

            assert.equal(0, #instance._uiUpdateTimers)
            assert.equal(1, #instance._tickTimers)
            assert.spy(_OnTickEvenPaused_Add).called(1)
        end)

        it('switches from tick-bound to UI-bound for interval timers resetting to values >250ms', function()
            local _OnTickEvenPaused_Add = spy.on(Events.OnTickEvenPaused, 'Add')

            instance:setInterval(300, function() end)

            zomboid.trigger_update_ui(250)

            assert.equal(0, #instance._uiUpdateTimers)
            assert.equal(1, #instance._tickTimers)
            assert.spy(_OnTickEvenPaused_Add).called(1)

            zomboid.set_timestamp(300)
            triggerEvent(TICK_EVENT)

            assert.equal(1, #instance._uiUpdateTimers)
            assert.equal(0, #instance._tickTimers)
        end)
    end)

    describe('when used on the server', function()
        setup(switchToServer)
        teardown(switchToClient)

        it('does not connect to game boot and game start events', function()
            local _OnGameBoot_Add = spy.on(Events.OnGameBoot, 'Add')
            local _OnGameStart_Add = spy.on(Events.OnGameStart, 'Add')

            Scheduler:new()

            assert.spy(_OnGameBoot_Add).not_called()
            assert.spy(_OnGameStart_Add).not_called()
        end)

        it('does not create a UI element on game boot', function()
            local _createUI = spy.on(Scheduler, '_createUI')

            triggerEvent('OnGameBoot')
            assert.spy(_createUI).not_called()
        end)

        it('does not create a UI element on game start', function()
            local _createUI = spy.on(Scheduler, '_createUI')

            triggerEvent('OnGameStart')
            assert.spy(_createUI).not_called()
        end)

        it('does not switch from tick-bound to UI-bound for interval timers resetting to values >250ms', function()
            local _OnTickEvenPaused_Add = spy.on(Events.OnTickEvenPaused, 'Add')

            instance:setInterval(300, function() end)

            assert.spy(_OnTickEvenPaused_Add).called(1)
            assert.equal(0, #instance._uiUpdateTimers)
            assert.equal(1, #instance._tickTimers)

            zomboid.set_timestamp(250)
            triggerEvent(TICK_EVENT)

            assert.equal(0, #instance._uiUpdateTimers)
            assert.equal(1, #instance._tickTimers)

            zomboid.set_timestamp(300)
            triggerEvent(TICK_EVENT)

            assert.equal(0, #instance._uiUpdateTimers)
            assert.equal(1, #instance._tickTimers)
        end)

        describe('connects to OnTickEvenPaused', function()
            local _OnTickEvenPaused_Add ---@type luassert.spy
            before_each(function()
                _OnTickEvenPaused_Add = spy.on(Events.OnTickEvenPaused, 'Add')
            end)

            it('if the timer value is <250', function()
                instance:setInterval(200, function() end)
                assert.spy(_OnTickEvenPaused_Add).called(1)
            end)

            it('if the timer value is 250', function()
                instance:setInterval(250, function() end)
                assert.spy(_OnTickEvenPaused_Add).called(1)
            end)

            it('if the timer value is >250', function()
                instance:setInterval(300, function() end)
                assert.spy(_OnTickEvenPaused_Add).called(1)
            end)
        end)
    end)
end)

describe('#component Timer #method', function()
    after_each(zomboid.revert)

    describe('cancel', function()
        it('prevents a timer callback from being called', function()
            local instance = Scheduler:new()
            zomboid.set_timestamp(0)
            triggerEvent('OnGameStart')

            local f = spy.new()

            local timer = instance:setTimeout(100, f --[[@as function]])
            timer:cancel()

            zomboid.set_timestamp(100)
            triggerEvent(TICK_EVENT)

            assert.spy(f).not_called()
        end)
    end)
end)
