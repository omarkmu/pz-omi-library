---Contains tests for the Channel component.
---@using omi
---@diagnostic disable: access-invisible, duplicate-require

local Channel = require 'OmiLibrary/Component/Dispatch/Channel'
local ClientRequest = require 'OmiLibrary/Component/Dispatch/ClientRequest'
local ServerRequest = require 'OmiLibrary/Component/Dispatch/ServerRequest'
local Dispatcher = require 'OmiLibrary/Component/Dispatch/Dispatcher'

---Helper function to switch to a server context.
local function switchToServer()
    zomboid.set_is_server()
    Channel = reload_module('OmiLibrary/Component/Dispatch/Channel')
    Dispatcher = reload_module('OmiLibrary/Component/Dispatch/Dispatcher')
end

---Helper function to switch back from a server context.
local function switchToClient()
    zomboid.revert_is_server()
    Channel = reload_module('OmiLibrary/Component/Dispatch/Channel')
    Dispatcher = reload_module('OmiLibrary/Component/Dispatch/Dispatcher')
end

describe('#component Channel', function()
    local dispatch ---@type Dispatcher
    local channel ---@type Channel
    before_each(function()
        dispatch = Dispatcher:new({ module = 'modname' })
        channel = dispatch:channel('CHANNEL')
    end)

    describe('#constructor', function()
        local clientTrigger ---@type Trigger
        local serverTrigger ---@type Trigger
        local _addTrigger ---@type luassert.spy
        before_each(function()
            clientTrigger = dispatch.trigger.onPlayerJoined()
            serverTrigger = dispatch.trigger.everyDay()

            _addTrigger = stub(Dispatcher, 'addTrigger'):auto_revert()

            channel = dispatch:channel('CHANNEL', {
                clientTriggers = { clientTrigger },
                serverTriggers = { serverTrigger },
            })
        end)

        describe('when used on the client', function()
            it('adds client triggers to the dispatcher', function()
                assert.spy(_addTrigger).called_with(match.ref(dispatch), match.ref(channel), match.ref(clientTrigger))
            end)

            it('does not add server triggers to the dispatcher', function()
                assert.spy(_addTrigger).not_called_with(match.ref(dispatch), match.ref(channel), match.ref(serverTrigger))
            end)
        end)

        describe('when used on the server', function()
            setup(switchToServer)
            teardown(switchToClient)

            it('adds server triggers to the dispatcher', function()
                assert.spy(_addTrigger).called_with(match.ref(dispatch), match.ref(channel), match.ref(serverTrigger))
            end)

            it('does not add client triggers to the dispatcher', function()
                assert.spy(_addTrigger).not_called_with(match.ref(dispatch), match.ref(channel), match.ref(clientTrigger))
            end)
        end)
    end)

    describe('#method', function()
        describe('broadcast', function()
            it('calls broadcast on the dispatcher', function()
                local _broadcast = stub(Dispatcher, 'broadcast'):auto_revert()

                local args = {}
                local source = {}
                channel:broadcast(args, source --[[@as Request]])

                assert.spy(_broadcast).called(1)
                assert.spy(_broadcast).called_with(
                    match.ref(dispatch),
                    match.ref(channel),
                    match.ref(args),
                    match.ref(source)
                )
            end)
        end)

        describe('canLogArgs', function()
            it('returns true if unset in arguments', function()
                assert.is_true(channel:canLogArgs())
            end)

            it('returns true if set to true in argument', function()
                channel = dispatch:channel('CHANNEL', { canLogArgs = true })
                assert.is_true(channel:canLogArgs())
            end)

            it('returns false if set to false in argument', function()
                channel = dispatch:channel('CHANNEL', { canLogArgs = false })
                assert.is_false(channel:canLogArgs())
            end)
        end)

        describe('getDispatcher', function()
            it('returns the dispatcher', function()
                assert.equal(dispatch, channel:getDispatcher())
            end)
        end)

        describe('getName', function()
            it('returns the channel name', function()
                assert.equal('CHANNEL', channel:getName())
            end)
        end)

        describe('getModule', function()
            it('returns the dispatcher module', function()
                assert.equal('modname', channel:getModule())
            end)
        end)

        describe('getModuleAndName', function()
            it('returns the dispatcher module and channel name', function()
                local module, name = channel:getModuleAndName()
                assert.equal('modname', module)
                assert.equal('CHANNEL', name)
            end)
        end)

        describe('isAllowDead', function()
            it('returns false if unset in arguments', function()
                assert.is_false(channel:isAllowDead())
            end)

            it('returns true if set to true in argument', function()
                channel = dispatch:channel('CHANNEL', { allowDead = true })
                assert.is_true(channel:isAllowDead())
            end)

            it('returns false if set to false in argument', function()
                channel = dispatch:channel('CHANNEL', { allowDead = false })
                assert.is_false(channel:isAllowDead())
            end)
        end)

        describe('isRequireAdmin', function()
            it('returns false if unset in arguments', function()
                assert.is_false(channel:isRequireAdmin())
            end)

            it('returns true if set to true in argument', function()
                channel = dispatch:channel('CHANNEL', { requireAdmin = true })
                assert.is_true(channel:isRequireAdmin())
            end)

            it('returns false if set to false in argument', function()
                channel = dispatch:channel('CHANNEL', { requireAdmin = false })
                assert.is_false(channel:isRequireAdmin())
            end)
        end)

        describe('onClientReceive', function()
            local _onReceive ---@type luassert.spy
            local _onClientReceive ---@type luassert.spy
            before_each(function()
                _onReceive = spy.new()
                _onClientReceive = spy.new()

                channel = dispatch:channel('CHANNEL', {
                    onReceive = _onReceive --[[@as function]],
                    onClientReceive = _onClientReceive --[[@as function]],
                })

                local req = {}
                channel:onClientReceive(req --[[@as Request]])
            end)

            it('calls the onReceive callback', function()
                assert.spy(_onReceive).called(1)
            end)

            it('calls the onClientReceive callback', function()
                assert.spy(_onClientReceive).called(1)
            end)
        end)

        describe('onClientSend', function()
            local _onSend ---@type luassert.spy
            local _onClientSend ---@type luassert.spy
            before_each(function()
                _onSend = spy.new()
                _onClientSend = spy.new()

                channel = dispatch:channel('CHANNEL', {
                    onSend = _onSend --[[@as function]],
                    onClientSend = _onClientSend --[[@as function]],
                })

                local player = {}
                local req = ClientRequest:new({ channel = channel, player = player --[[@as IsoPlayer]] })
                channel:onClientSend(req)
            end)

            it('calls the onSend callback', function()
                assert.spy(_onSend).called(1)
            end)

            it('calls the onClientSend callback', function()
                assert.spy(_onClientSend).called(1)
            end)
        end)

        describe('onServerReceive', function()
            local _onReceive ---@type luassert.spy
            local _onServerReceive ---@type luassert.spy
            before_each(function()
                _onReceive = spy.new()
                _onServerReceive = spy.new()

                channel = dispatch:channel('CHANNEL', {
                    onReceive = _onReceive --[[@as function]],
                    onServerReceive = _onServerReceive --[[@as function]],
                })

                local req = {}
                channel:onServerReceive(req --[[@as Request]])
            end)

            it('calls the onReceive callback', function()
                assert.spy(_onReceive).called(1)
            end)

            it('calls the onServerReceive callback', function()
                assert.spy(_onServerReceive).called(1)
            end)
        end)

        describe('onServerSend', function()
            local _onSend ---@type luassert.spy
            local _onServerSend ---@type luassert.spy
            before_each(function()
                _onSend = spy.new()
                _onServerSend = spy.new()

                channel = dispatch:channel('CHANNEL', {
                    onSend = _onSend --[[@as function]],
                    onServerSend = _onServerSend --[[@as function]],
                })

                local req = {}
                channel:onServerSend(req --[[@as Request]])
            end)

            it('calls the onSend callback', function()
                assert.spy(_onSend).called(1)
            end)

            it('calls the onServerSend callback', function()
                assert.spy(_onServerSend).called(1)
            end)
        end)

        describe('stringifyArgs', function()
            local _onStringifyArgs ---@type luassert.spy
            local _onStringifyClientArgs ---@type luassert.spy
            local _onStringifyServerArgs ---@type luassert.spy
            before_each(function()
                _onStringifyArgs = spy.new()
                _onStringifyClientArgs = spy.new()
                _onStringifyServerArgs = spy.new()

                channel = dispatch:channel('CHANNEL', {
                    onStringifyArgs = _onStringifyArgs --[[@as function]],
                    onStringifyClientArgs = _onStringifyClientArgs --[[@as function]],
                    onStringifyServerArgs = _onStringifyServerArgs --[[@as function]],
                })
            end)

            it('returns a table with an ellipsis if the channel cannot log arguments', function()
                channel = dispatch:channel('CHANNEL', { canLogArgs = false })

                local req = ServerRequest:new({ channel = channel })
                assert.equal('{...}', channel:stringifyArgs(req))
            end)

            it('returns a table with an ellipsis if the callback returns an empty string', function()
                channel = dispatch:channel('CHANNEL', {
                    onStringifyArgs = function() return '' end,
                })

                local req = ServerRequest:new({ channel = channel })
                assert.equal('{...}', channel:stringifyArgs(req))
            end)

            it('returns the result from the callback', function()
                channel = dispatch:channel('CHANNEL', {
                    onStringifyArgs = function() return '{ <private> }' end,
                })

                local req = ServerRequest:new({ channel = channel })
                assert.equal('{ <private> }', channel:stringifyArgs(req))
            end)

            it('calls the correct callback for a request from the server', function()
                local req = ServerRequest:new({ channel = channel })

                channel:stringifyArgs(req)

                assert.spy(_onStringifyArgs).not_called()
                assert.spy(_onStringifyClientArgs).not_called()
                assert.spy(_onStringifyServerArgs).called(1)
            end)

            it('calls the correct callback for a request from the client', function()
                local player = {}
                local req = ClientRequest:new({ channel = channel, player = player --[[@as IsoPlayer]] })

                channel:stringifyArgs(req)

                assert.spy(_onStringifyArgs).not_called()
                assert.spy(_onStringifyClientArgs).called(1)
                assert.spy(_onStringifyServerArgs).not_called()
            end)

            it('logs an error if JSON encoding arguments fails', function()
                local _log = spy.on(Dispatcher, 'log')
                local req = ServerRequest:new({ channel = channel, args = { f = function() end } })

                channel:stringifyArgs(req)

                assert.spy(_log).called(1)
            end)
        end)

        describe('toPlayer', function()
            it('calls toPlayer on the dispatcher', function()
                local _toPlayer = stub(Dispatcher, 'toPlayer'):auto_revert()

                local player = {}
                local args = {}
                local source = {}
                channel:toPlayer(player --[[@as IsoPlayer]], args, source --[[@as Request]])

                assert.spy(_toPlayer).called(1)
                assert.spy(_toPlayer).called_with(
                    match.ref(dispatch),
                    match.ref(channel),
                    match.ref(player),
                    match.ref(args),
                    match.ref(source)
                )
            end)
        end)

        describe('toPlayerOrBroadcast', function()
            it('calls toPlayer on the dispatcher if a player is given', function()
                local _toPlayer = stub(Dispatcher, 'toPlayer'):auto_revert()

                local player = {}
                local args = {}
                local source = {}
                channel:toPlayerOrBroadcast(player --[[@as IsoPlayer]], args, source --[[@as Request]])

                assert.spy(_toPlayer).called(1)
                assert.spy(_toPlayer).called_with(
                    match.ref(dispatch),
                    match.ref(channel),
                    match.ref(player),
                    match.ref(args),
                    match.ref(source)
                )
            end)

            it('calls broadcast on the dispatcher if a player is not given', function()
                local _broadcast = stub(Dispatcher, 'broadcast'):auto_revert()

                local args = {}
                local source = {}
                channel:toPlayerOrBroadcast(nil, args, source --[[@as Request]])

                assert.spy(_broadcast).called(1)
                assert.spy(_broadcast).called_with(
                    match.ref(dispatch),
                    match.ref(channel),
                    match.ref(args),
                    match.ref(source)
                )
            end)
        end)

        describe('toServer', function()
            it('calls toServer on the dispatcher', function()
                local _toServer = stub(Dispatcher, 'toServer'):auto_revert()

                local args = {}
                local source = {}
                channel:toServer(args, source --[[@as Request]])

                assert.spy(_toServer).called(1)
                assert.spy(_toServer).called_with(
                    match.ref(dispatch),
                    match.ref(channel),
                    match.ref(args),
                    match.ref(source)
                )
            end)
        end)

        describe('validateOnClient', function()
            local _onValidate ---@type luassert.spy
            local _onClientValidate ---@type luassert.spy

            ---@diagnostic disable-next-line: missing-fields
            local req = { args = {} } --[[@as Request]]

            before_each(function()
                _onValidate = spy.new(function() return true end)
                _onClientValidate = spy.new(function() return true end)

                channel = dispatch:channel('CHANNEL', {
                    onValidate = _onValidate --[[@as function]],
                    onClientValidate = _onClientValidate --[[@as function]],
                })
            end)

            it('returns true if no callbacks are given', function()
                channel = dispatch:channel('CHANNEL')
                assert.is_true(channel:validateOnClient(req))
            end)

            it('calls the onValidate callback', function()
                channel:validateOnClient(req)
                assert.spy(_onValidate).called(1)
            end)

            it('calls the onClientValidate callback', function()
                channel:validateOnClient(req)
                assert.spy(_onClientValidate).called(1)
            end)

            it('does not the onClientValidate callback if the onValidate callback fails', function()
                local s = spy.new(function() return false end)
                channel = dispatch:channel('CHANNEL', {
                    onValidate = s --[[@as function]],
                    onClientValidate = _onClientValidate --[[@as function]],
                })

                channel:validateOnClient(req)
                assert.spy(s).called(1)
                assert.spy(_onClientValidate).not_called()
            end)
        end)

        describe('validateOnServer', function()
            local _onValidate ---@type luassert.spy
            local _onServerValidate ---@type luassert.spy

            ---@diagnostic disable-next-line: missing-fields
            local req = { args = {} } --[[@as Request]]

            before_each(function()
                _onValidate = spy.new(function() return true end)
                _onServerValidate = spy.new(function() return true end)

                channel = dispatch:channel('CHANNEL', {
                    onValidate = _onValidate --[[@as function]],
                    onServerValidate = _onServerValidate --[[@as function]],
                })
            end)

            it('returns true if no callbacks are given', function()
                channel = dispatch:channel('CHANNEL')
                assert.is_true(channel:validateOnServer(req))
            end)

            it('calls the onValidate callback', function()
                channel:validateOnServer(req)
                assert.spy(_onValidate).called(1)
            end)

            it('calls the onServerValidate callback', function()
                channel:validateOnServer(req)
                assert.spy(_onServerValidate).called(1)
            end)

            it('does not the onServerValidate callback if the onValidate callback fails', function()
                local s = spy.new(function() return false end)
                channel = dispatch:channel('CHANNEL', {
                    onValidate = s --[[@as function]],
                    onServerValidate = _onServerValidate --[[@as function]],
                })

                channel:validateOnServer(req)
                assert.spy(s).called(1)
                assert.spy(_onServerValidate).not_called()
            end)
        end)
    end)

    describe('#operation', function()
        describe('__tostring', function()
            it('returns the channel as a string', function()
                local result = tostring(channel)
                assert.is_string(result)
                assert.equal('Channel<CHANNEL>', result)
            end)
        end)
    end)
end)
