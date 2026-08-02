---Contains tests for the Dispatcher component.
---@using omi
---@diagnostic disable: access-invisible, duplicate-require

local Channel = require 'OmiLibrary/Component/Dispatch/Channel'
local Dispatcher = require 'OmiLibrary/Component/Dispatch/Dispatcher'
local Request = require 'OmiLibrary/Component/Dispatch/Request'
local core = require 'OmiLibrary/Module/Utils'

---Helper function to switch to a server context.
local function switchToServer()
    zomboid.set_is_server()
    Dispatcher = reload_module('OmiLibrary/Component/Dispatch/Dispatcher')
end

---Helper function to switch back from a server context.
local function switchToClient()
    zomboid.revert_is_server()
    Dispatcher = reload_module('OmiLibrary/Component/Dispatch/Dispatcher')
end

describe('#component Dispatcher', function()
    local dispatch ---@type Dispatcher
    local channel ---@type Channel
    local player ---@type IsoPlayer

    local _Request_send ---@type luassert.spy

    before_each(function()
        _Request_send = spy.on(Request, 'send')
        player = zomboid.player()
        dispatch = Dispatcher:new({ module = 'modname' })
        channel = dispatch:channel('CHANNEL')
    end)

    after_each(zomboid.revert)

    describe('#constructor', function()
        describe('calls the connect method', function()
            local _connect = spy.on(Dispatcher, 'connect')

            Dispatcher:new({ module = 'othermodname' })
            assert.spy(_connect).called(1)
        end)
    end)

    describe('#method', function()
        describe('addTrigger', function()
            local _onEvent ---@type luassert.spy
            local _triggerOnEvent ---@type luassert.spy
            before_each(function()
                _triggerOnEvent = spy.on(Dispatcher, '_triggerOnEvent')
                _onEvent = spy.on(Dispatcher, '_onEvent')
            end)

            it('does not add the trigger if the channel is not part of the dispatcher', function()
                local otherDispatch = Dispatcher:new({ module = 'othermodname' })
                local otherChannel = otherDispatch:channel('OTHER_CHANNEL')

                dispatch:addTrigger(otherChannel, dispatch.trigger.everyDay())

                assert.spy(_triggerOnEvent).not_called()
            end)

            describe('when adding an Interval trigger', function()
                local _onInterval ---@type luassert.spy
                local _triggerOnInterval ---@type luassert.spy
                before_each(function()
                    _triggerOnInterval = spy.on(Dispatcher, '_triggerOnInterval')
                    _onInterval = spy.on(Dispatcher, '_onInterval')
                end)

                it('calls the appropriate method', function()
                    dispatch:addTrigger(channel, dispatch.trigger.onInterval(1000))

                    assert.spy(_triggerOnInterval).called(1)
                end)

                it('replaces an existing trigger', function()
                    zomboid.set_timestamp(0)

                    dispatch:addTrigger(channel, dispatch.trigger.onInterval(1000))
                    dispatch:addTrigger(channel, dispatch.trigger.onInterval(2000))
                    assert.spy(_triggerOnInterval).called(2)

                    zomboid.set_timestamp(1000)
                    core._scheduler:_update(true)
                    assert.spy(_onInterval).not_called()

                    zomboid.trigger_update_ui(2000)
                    core._scheduler:_update(true)
                    assert.spy(_onInterval).called(1)
                end)
            end)

            describe('when adding a PlayerDeath trigger', function()
                local _onPlayerDeath ---@type luassert.spy
                local _triggerOnPlayerDeath ---@type luassert.spy
                before_each(function()
                    _triggerOnPlayerDeath = spy.on(Dispatcher, '_triggerOnPlayerDeath')
                    _onPlayerDeath = spy.on(Dispatcher, '_onPlayerDeath')
                end)

                describe('on the server', function()
                    setup(switchToServer)
                    teardown(switchToClient)

                    it('does not add a trigger', function()
                        dispatch:addTrigger(channel, dispatch.trigger.onPlayerDeath())
                        assert.same({}, dispatch._triggers)
                    end)
                end)

                it('calls the appropriate method', function()
                    dispatch:addTrigger(channel, dispatch.trigger.onPlayerDeath())

                    assert.spy(_triggerOnPlayerDeath).called(1)
                end)

                it('replaces an existing trigger', function()
                    dispatch:addTrigger(channel, dispatch.trigger.onPlayerDeath())
                    dispatch:addTrigger(channel, dispatch.trigger.onPlayerDeath())

                    triggerEvent('OnPlayerDeath', player)

                    assert.spy(_onPlayerDeath).called(1)
                    assert.spy(_triggerOnPlayerDeath).called(2)
                end)
            end)

            describe('when adding a PlayerJoined trigger', function()
                local _onPlayerJoined ---@type luassert.spy
                local _triggerOnPlayerJoined ---@type luassert.spy
                before_each(function()
                    _triggerOnPlayerJoined = spy.on(Dispatcher, '_triggerOnPlayerJoined')
                    _onPlayerJoined = spy.on(Dispatcher, '_onPlayerJoinedCheck')
                end)

                describe('on the server', function()
                    setup(switchToServer)
                    teardown(switchToClient)

                    it('does not add a trigger', function()
                        dispatch:addTrigger(channel, dispatch.trigger.onPlayerJoined())
                        assert.same({}, dispatch._triggers)
                    end)
                end)

                it('calls the appropriate method', function()
                    dispatch:addTrigger(channel, dispatch.trigger.onPlayerJoined())

                    assert.spy(_triggerOnPlayerJoined).called(1)
                end)

                it('replaces an existing trigger', function()
                    dispatch:addTrigger(channel, dispatch.trigger.onPlayerJoined())
                    dispatch:addTrigger(channel, dispatch.trigger.onPlayerJoined())

                    triggerEvent('OnTick')

                    assert.spy(_onPlayerJoined).called(1)
                    assert.spy(_triggerOnPlayerJoined).called(2)
                end)
            end)

            describe('when adding an EveryDay trigger', function()
                it('calls the appropriate method', function()
                    dispatch:addTrigger(channel, dispatch.trigger.everyDay())

                    assert.spy(_triggerOnEvent).called(1)
                    assert.spy(_triggerOnEvent).called_with(
                        match.ref(dispatch),
                        match.ref(channel),
                        'EveryDay',
                        'EveryDays'
                    )
                end)

                it('replaces an existing trigger', function()
                    dispatch:addTrigger(channel, dispatch.trigger.everyDay())
                    dispatch:addTrigger(channel, dispatch.trigger.everyDay())

                    triggerEvent('EveryDays')

                    assert.spy(_onEvent).called(1)
                    assert.spy(_triggerOnEvent).called(2)
                end)
            end)

            describe('when adding an EveryHour trigger', function()
                it('calls the appropriate method', function()
                    dispatch:addTrigger(channel, dispatch.trigger.everyHour())

                    assert.spy(_triggerOnEvent).called(1)
                    assert.spy(_triggerOnEvent).called_with(
                        match.ref(dispatch),
                        match.ref(channel),
                        'EveryHour',
                        'EveryHours'
                    )
                end)

                it('replaces an existing trigger', function()
                    dispatch:addTrigger(channel, dispatch.trigger.everyHour())
                    dispatch:addTrigger(channel, dispatch.trigger.everyHour())

                    triggerEvent('EveryHours')

                    assert.spy(_onEvent).called(1)
                    assert.spy(_triggerOnEvent).called(2)
                end)
            end)

            describe('when adding an EveryTenMinutes trigger', function()
                it('calls the appropriate method', function()
                    dispatch:addTrigger(channel, dispatch.trigger.everyTenMinutes())

                    assert.spy(_triggerOnEvent).called(1)
                    assert.spy(_triggerOnEvent).called_with(
                        match.ref(dispatch),
                        match.ref(channel),
                        'EveryTenMinutes',
                        'EveryTenMinutes'
                    )
                end)

                it('replaces an existing trigger', function()
                    dispatch:addTrigger(channel, dispatch.trigger.everyTenMinutes())
                    dispatch:addTrigger(channel, dispatch.trigger.everyTenMinutes())

                    triggerEvent('EveryTenMinutes')

                    assert.spy(_onEvent).called(1)
                    assert.spy(_triggerOnEvent).called(2)
                end)
            end)

            describe('when adding an EveryMinute trigger', function()
                it('calls the appropriate method', function()
                    dispatch:addTrigger(channel, dispatch.trigger.everyMinute())

                    assert.spy(_triggerOnEvent).called(1)
                    assert.spy(_triggerOnEvent).called_with(
                        match.ref(dispatch),
                        match.ref(channel),
                        'EveryMinute',
                        'EveryOneMinute'
                    )
                end)

                it('replaces an existing trigger', function()
                    dispatch:addTrigger(channel, dispatch.trigger.everyMinute())
                    dispatch:addTrigger(channel, dispatch.trigger.everyMinute())

                    triggerEvent('EveryOneMinute')

                    assert.spy(_onEvent).called(1)
                    assert.spy(_triggerOnEvent).called(2)
                end)
            end)

            describe('when adding an unknown trigger', function()
                it('logs an error', function()
                    local _log = spy.on(Dispatcher, 'log')

                    local trigger = { type = 'UNKNOWN', options = {} }
                    dispatch:addTrigger(channel, trigger --[[@as Trigger]])

                    assert.spy(_log).called(1)
                    assert.spy(_log).called_with(
                        match.ref(dispatch),
                        'Ignoring unknown trigger %s for %s',
                        'UNKNOWN',
                        match.ref(channel)
                    )
                end)
            end)
        end)

        describe('broadcast', function()
            describe('when used on the client', function()
                it('throws an error', function()
                    assert.error(
                        function() dispatch:broadcast(channel) end,
                        'Dispatcher.broadcast cannot be used on the client'
                    )
                end)
            end)

            describe('when used on the server', function()
                setup(switchToServer)
                teardown(switchToClient)

                it('sends a broadcast', function()
                    local _sendServerCommand = spy.on(_G, 'sendServerCommand')

                    dispatch:broadcast(channel)
                    assert.spy(_sendServerCommand).called(1)
                    assert.spy(_sendServerCommand).called_with('modname', 'CHANNEL', match.table())
                end)

                it('does not attempt to send a cancelled request', function()
                    channel = dispatch:channel('CHANNEL', {
                        onSend = function(req) req:cancel() end,
                    })

                    dispatch:broadcast(channel)
                    assert.spy(_Request_send).not_called()
                end)

                it('does not attempt to send an already sent request', function()
                    channel = dispatch:channel('CHANNEL', {
                        onSend = function(req) req:send() end,
                    })

                    dispatch:broadcast(channel)
                    assert.spy(_Request_send).called(1)
                end)
            end)
        end)

        describe('connect', function()
            describe('when used on the client', function()
                it('connects a new listener', function()
                    local _Add = spy.on(_G.Events.OnServerCommand, 'Add')

                    dispatch:connect()
                    assert.spy(_Add).called(1)
                end)
                it('disconnects an existing listener', function()
                    local _Remove = spy.on(_G.Events.OnServerCommand, 'Remove')

                    dispatch:connect()
                    assert.spy(_Remove).called(1)
                end)
            end)

            describe('when used on the server', function()
                setup(switchToServer)
                teardown(switchToClient)

                it('connects a new listener', function()
                    local _Add = spy.on(_G.Events.OnClientCommand, 'Add')

                    dispatch:connect()
                    assert.spy(_Add).called(1)
                end)
                it('disconnects an existing listener', function()
                    local _Remove = spy.on(_G.Events.OnClientCommand, 'Remove')

                    dispatch:connect()
                    assert.spy(_Remove).called(1)
                end)
            end)
        end)

        describe('disconnect', function()
            describe('when used on the client', function()
                it('disconnects an existing listener', function()
                    local _Remove = spy.on(_G.Events.OnServerCommand, 'Remove')

                    dispatch:disconnect()
                    assert.spy(_Remove).called(1)
                end)
            end)

            describe('when used on the server', function()
                setup(switchToServer)
                teardown(switchToClient)

                it('disconnects an existing listener', function()
                    local _Remove = spy.on(_G.Events.OnClientCommand, 'Remove')

                    dispatch:disconnect()
                    assert.spy(_Remove).called(1)
                end)
            end)
        end)

        describe('getChannel', function()
            it('returns a channel', function()
                assert.equal(channel, dispatch:getChannel('CHANNEL'))
            end)

            it('returns nil for an unknown channel', function()
                assert.is_nil(dispatch:getChannel('UNKNOWN_CHANNEL'))
            end)
        end)

        describe('getModule', function()
            it('returns the module name', function()
                assert.equal('modname', dispatch:getModule())
            end)
        end)

        describe('log', function()
            local _debug ---@type luassert.spy
            local logger
            before_each(function()
                _debug = spy.new()
                logger = { debug = _debug }
            end)

            it('logs a debug message', function()
                dispatch = Dispatcher:new({ module = 'modname', logger = logger })
                local table = setmetatable({}, { __tostring = function() return 'TABLE' end })

                dispatch:log('%s %d', table, 10)

                assert.spy(_debug).called_with('%s %d', match.ref(table), 10)
            end)

            it('does not log a message if a logger is not given', function()
                dispatch = Dispatcher:new({ module = 'modname' })

                dispatch:log('message')

                assert.spy(_debug).not_called()
            end)
        end)

        describe('toPlayer', function()
            describe('when used on the client', function()
                it('throws an error', function()
                    assert.error(
                        function() dispatch:toPlayer(channel, player) end,
                        'Dispatcher.toPlayer cannot be used on the client'
                    )
                end)
            end)

            describe('when used on the server', function()
                setup(switchToServer)
                teardown(switchToClient)

                it('sends a server command to a player', function()
                    local _sendServerCommand = spy.on(_G, 'sendServerCommand')

                    dispatch:toPlayer(channel, player)
                    assert.spy(_sendServerCommand).called(1)
                    assert.spy(_sendServerCommand).called_with(match.ref(player), 'modname', 'CHANNEL', match.table())
                end)

                it('does not attempt to send a cancelled request', function()
                    channel = dispatch:channel('CHANNEL', {
                        onSend = function(req) req:cancel() end,
                    })

                    dispatch:toPlayer(channel, player)
                    assert.spy(_Request_send).not_called()
                end)

                it('does not attempt to send an already sent request', function()
                    channel = dispatch:channel('CHANNEL', {
                        onSend = function(req) req:send() end,
                    })

                    dispatch:toPlayer(channel, player)
                    assert.spy(_Request_send).called(1)
                end)
            end)
        end)

        describe('toServer', function()
            describe('when used on the client', function()
                it('sends a client command to the server', function()
                    local _sendClientCommand = spy.on(_G, 'sendClientCommand')

                    dispatch:toServer(channel)
                    assert.spy(_sendClientCommand).called(1)
                    assert.spy(_sendClientCommand).called_with('modname', 'CHANNEL', match.table())
                end)

                it('fails with a validation error when validation fails', function()
                    channel = dispatch:channel('CHANNEL', {
                        onSend = function(req) req:send() end,
                        onValidate = function() return false end,
                    })

                    local success, err = dispatch:toServer(channel)

                    assert.is_false(success)
                    assert.equal('Validation failed', err)
                    assert.spy(_Request_send).called(1)
                end)

                it('fails with an error when unable to determine a requesting player', function()
                    zomboid.revert_players()

                    local success, err = dispatch:toServer(channel)

                    assert.is_false(success)
                    assert.equal('Failed to get a player for sending the request', err)
                    assert.spy(_Request_send).not_called()
                end)

                it('does not attempt to send a cancelled request', function()
                    channel = dispatch:channel('CHANNEL', {
                        onSend = function(req) req:cancel() end,
                    })

                    dispatch:toServer(channel)
                    assert.spy(_Request_send).not_called()
                end)

                it('does not attempt to send an already sent request', function()
                    channel = dispatch:channel('CHANNEL', {
                        onSend = function(req) req:send() end,
                    })

                    dispatch:toServer(channel)
                    assert.spy(_Request_send).called(1)
                end)
            end)

            describe('when used on the server', function()
                setup(switchToServer)
                teardown(switchToClient)

                it('throws an error', function()
                    assert.error(
                        function() dispatch:toServer(channel) end,
                        'Dispatcher.toServer cannot be used on the server'
                    )
                end)
            end)
        end)
    end)

    describe('#operation', function()
        describe('__tostring', function()
            it('returns the dispatcher as a string', function()
                assert.is_string(tostring(dispatch))
            end)
        end)
    end)

    describe('when receiving a request', function()
        local _log ---@type luassert.spy
        before_each(function()
            _log = spy.on(Dispatcher, 'log')
        end)

        it('unsets internal information attached to the arguments table', function()
            local args = {
                ['$__EXID'] = 'exchange-id',
                ['$__REPLY'] = true,
            }

            triggerEvent('OnServerCommand', 'modname', 'CHANNEL', args)

            assert.same({}, args)
        end)

        describe('on the client', function()
            local _onClientReceive ---@type luassert.spy
            before_each(function()
                _onClientReceive = spy.on(Channel, 'onClientReceive')
            end)

            it('passes the request to the channel', function()
                triggerEvent('OnServerCommand', 'modname', 'CHANNEL')

                assert.spy(_onClientReceive).called_with(match.ref(channel), match.table())
            end)

            it('ignores commands that do not match the module', function()
                triggerEvent('OnServerCommand', 'othermodname', 'CHANNEL')

                assert.spy(_onClientReceive).not_called()
            end)

            it('logs a message then ignores an unknown channel', function()
                triggerEvent('OnServerCommand', 'modname', 'UNKNOWN_CHANNEL')

                assert.spy(_onClientReceive).not_called()
                assert.spy(_log).called_with(
                    match.ref(dispatch),
                    'Ignoring request on unknown channel %q',
                    'UNKNOWN_CHANNEL'
                )
            end)

            it('logs a message then ignores requests that fail the canReceive check', function()
                stub(Request, 'canReceive', false, 'Not allowed'):auto_revert()

                triggerEvent('OnServerCommand', 'modname', 'CHANNEL')

                assert.spy(_onClientReceive).not_called()
                assert.spy(_log).called_with(
                    match.ref(dispatch),
                    'Cannot receive %s: %s',
                    match.table(),
                    'Not allowed'
                )
            end)
        end)

        describe('on the server', function()
            setup(switchToServer)
            teardown(switchToClient)

            local _onServerReceive ---@type luassert.spy
            before_each(function()
                _onServerReceive = spy.on(Channel, 'onServerReceive')
            end)

            it('passes the request to the channel', function()
                triggerEvent('OnClientCommand', 'modname', 'CHANNEL', {}, player)

                assert.spy(_onServerReceive).called_with(match.ref(channel), match.table())
            end)

            it('ignores commands that do not match the module', function()
                triggerEvent('OnClientCommand', 'othermodname', 'CHANNEL', {}, player)

                assert.spy(_onServerReceive).not_called()
            end)

            it('logs a message then ignores an unknown channel', function()
                triggerEvent('OnClientCommand', 'modname', 'UNKNOWN_CHANNEL', {}, player)

                assert.spy(_onServerReceive).not_called()
                assert.spy(_log).called_with(
                    match.ref(dispatch),
                    'Ignoring request on unknown channel %q',
                    'UNKNOWN_CHANNEL'
                )
            end)

            it('logs a message then ignores requests that fail the canReceive check', function()
                stub(Request, 'canReceive', false, 'Not allowed'):auto_revert()

                triggerEvent('OnClientCommand', 'modname', 'CHANNEL', {}, player)

                assert.spy(_onServerReceive).not_called()
                assert.spy(_log).called_with(
                    match.ref(dispatch),
                    'Cannot receive %s: %s',
                    match.table(),
                    'Not allowed'
                )
            end)
        end)
    end)

    describe('does not throw an error', function()
        describe('when inappropriately activating', function()
            it('an Interval trigger', function()
                dispatch:_onInterval(channel)
            end)

            it('a PlayerDeath trigger', function()
                dispatch:_onPlayerDeath(player)
            end)

            it('a PlayerJoined trigger', function()
                dispatch:_onPlayerJoinedCheck()
            end)

            it('an event trigger', function()
                dispatch:_onEvent('EveryDay', 'EveryDays')
            end)
        end)

        it('when the player is not available in a PlayerJoined trigger', function()
            zomboid.revert_players()
            dispatch:addTrigger(channel, dispatch.trigger.onPlayerJoined())
            dispatch:_onPlayerJoinedCheck()
        end)
    end)
end)
