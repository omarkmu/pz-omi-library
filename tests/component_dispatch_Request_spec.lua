---Contains tests for the Request component.
---@using omi
---@diagnostic disable: access-invisible

local Request = require 'OmiLibrary/Component/Dispatch/Request'
local ClientRequest = require 'OmiLibrary/Component/Dispatch/ClientRequest'
local ServerRequest = require 'OmiLibrary/Component/Dispatch/ServerRequest'
local Dispatcher = require 'OmiLibrary/Component/Dispatch/Dispatcher'
local Topic = require 'OmiLibrary/Component/Dispatch/Topic'

describe('#component Request', function()
    local dispatch ---@type Dispatcher
    local topic ---@type Topic
    local otherTopic ---@type Topic
    local player ---@type IsoPlayer
    local mockUsername = 'username'
    setup(function()
        dispatch = Dispatcher:new({ module = 'modname' })
        topic = dispatch:topic('TOPIC')
        otherTopic = dispatch:topic('OTHER_TOPIC')

        player = zomboid.player({ username = mockUsername }) --[[@as IsoPlayer]]
    end)

    teardown(zomboid.revert_players)

    describe('#method', function()
        local req ---@type Request
        before_each(function()
            req = ClientRequest:new({ topic = topic, player = player })
        end)

        describe('canReceive', function()
            it('returns true', function()
                assert.is_true(Request.canReceive(req))
            end)
        end)

        describe('canSend', function()
            it('returns true when the request can be sent', function()
                assert.is_true(Request.canSend(req))
            end)

            it('returns false and an error message for an incoming request', function()
                req = ClientRequest:new({ topic = topic, player = player, isIncoming = true })

                local canSend, reason = Request.canSend(req)
                assert.is_false(canSend)
                assert.equal('Request is incoming', reason)
            end)

            it('returns false and an error message for a request that has already been sent', function()
                req = ClientRequest:new({ topic = topic, player = player, isSent = true })

                local canSend, reason = Request.canSend(req)
                assert.is_false(canSend)
                assert.equal('Request has already been sent', reason)
            end)

            it('returns false and no error message for a cancelled request', function()
                req = ClientRequest:new({ topic = topic, player = player })
                req:cancel()

                local canSend, reason = Request.canSend(req)
                assert.is_false(canSend)
                assert.is_nil(reason)
            end)
        end)

        describe('broadcast', function()
            it('sends a broadcast on the request topic', function()
                local _broadcast = stub(Topic, 'broadcast'):auto_revert()

                local args = {}
                req:broadcast(args)

                assert.spy(_broadcast).called_with(match.ref(topic), match.ref(args), match.ref(req))
            end)
        end)

        describe('broadcastOn', function()
            it('sends a broadcast on the given topic', function()
                local _broadcast = stub(Topic, 'broadcast'):auto_revert()

                local args = {}
                req:broadcastOn(otherTopic, args)

                assert.spy(_broadcast).called_with(match.ref(otherTopic), match.ref(args), match.ref(req))
            end)
        end)

        describe('cancel', function()
            it('marks the request as cancelled', function()
                req:cancel()
                assert.is_true(req:isCancelled())
            end)
        end)

        describe('getErrors', function()
            it('returns a list of errors that occurred while trying to send', function()
                req:send()
                req:send()

                assert.same({ 'Request has already been sent' }, req:getErrors())
            end)
        end)

        describe('getExchangeId', function()
            it('returns a string identifier for the request exchange', function()
                assert.is_string(req:getExchangeId())
            end)
        end)

        describe('getLastError', function()
            it('returns nil when no error has occurred', function()
                assert.is_nil(req:getLastError())
            end)

            it('returns the last error that occurred while trying to send', function()
                req:send()
                req:send()

                assert.same('Request has already been sent', req:getLastError())
            end)
        end)

        describe('getPlayer', function()
            it('returns the player associated with the request', function()
                assert.equal(player, Request.getPlayer(req))
            end)
        end)

        describe('getSendAttempts', function()
            it('returns the number of times the request has attempted sending', function()
                assert.equal(0, req:getSendAttempts())

                req:send()
                assert.equal(1, req:getSendAttempts())

                req:send()
                assert.equal(2, req:getSendAttempts())
            end)
        end)

        describe('getTopic', function()
            it('returns the topic of the request', function()
                assert.equal(topic, req:getTopic())
            end)
        end)

        describe('hasTriedToSend', function()
            it('returns false if the request has not attempted sending', function()
                assert.is_false(req:hasTriedToSend())
            end)

            it('returns true if the request has attempted sending', function()
                req:send()
                assert.is_true(req:hasTriedToSend())
            end)
        end)

        describe('isCancelled', function()
            it('returns false if the request has not been cancelled', function()
                assert.is_false(req:isCancelled())
            end)

            it('returns true if the request has been cancelled', function()
                req:cancel()
                assert.is_true(req:isCancelled())
            end)
        end)

        describe('isFromClient', function()
            it('returns false', function()
                assert.is_false(Request.isFromClient(req))
            end)
        end)

        describe('isFromServer', function()
            it('returns false', function()
                assert.is_false(Request.isFromServer(req))
            end)
        end)

        describe('isIncoming', function()
            it('returns false for outgoing requests', function()
                assert.is_false(req:isIncoming())
            end)

            it('returns true for incoming requests', function()
                req = ClientRequest:new({ topic = topic, player = player, isIncoming = true })
                assert.is_true(req:isIncoming())
            end)
        end)

        describe('isReply', function()
            it('returns false for non-reply requests', function()
                assert.is_false(req:isReply())
            end)

            it('returns true for reply requests', function()
                req = ClientRequest:new({ topic = topic, player = player, isReply = true })
                assert.is_true(req:isReply())
            end)
        end)

        describe('isSent', function()
            it('returns false for unsent requests', function()
                assert.is_false(req:isSent())
            end)

            it('returns true for sent requests', function()
                req = ClientRequest:new({ topic = topic, player = player, isSent = true })
                assert.is_true(req:isSent())
            end)
        end)

        describe('reply', function()
            it('sends a reply on the request topic', function()
                local _replyWith = stub(Request, 'replyWith'):auto_revert()

                local args = {}
                req:reply(args)

                assert.spy(_replyWith).called_with(match.ref(req), match.ref(topic), match.ref(args))
            end)
        end)

        describe('replyWith', function()
            describe('on the client', function()
                it('calls toServer on the topic', function()
                    local _toServer = stub(Topic, 'toServer'):auto_revert()

                    local args = {}
                    req = ServerRequest:new({ topic = topic })
                    req:replyWith(otherTopic, args)

                    assert.spy(_toServer).called_with(match.ref(otherTopic), match.ref(args), match.ref(req))
                end)
            end)

            describe('on the server', function()
                before_each(function()
                    req = ClientRequest:new({ topic = topic, player = player })
                end)

                it('calls toPlayer on the topic', function()
                    local _toPlayer = stub(Topic, 'toPlayer'):auto_revert()

                    local args = {}

                    req:replyWith(otherTopic, args)

                    assert.spy(_toPlayer).called_with(
                        match.ref(otherTopic),
                        match.ref(player),
                        match.ref(args),
                        match.ref(req)
                    )
                end)

                it('fails if the request has no player', function()
                    req._player = nil

                    local success, err = req:replyWith(topic)

                    assert.is_false(success)
                    assert.equal('No target player', err)
                end)
            end)
        end)

        describe('send', function()
            it('adds the exchange ID to the request arguments', function()
                local args = {}
                local expected = { ['$__EXID'] = req:getExchangeId() }

                local s = spy.on(_G, 'sendClientCommand')

                req:send(args)

                assert.same({}, args)
                assert.spy(s).called_with('modname', 'TOPIC', expected)
            end)

            it('adds a flag to the request arguments for replies', function()
                req = ClientRequest:new({ topic = topic, player = player, isReply = true })

                local args = {}
                local expected = { ['$__EXID'] = req:getExchangeId(), ['$__REPLY'] = req:isReply() }

                local s = spy.on(_G, 'sendClientCommand')

                req:send(args)

                assert.same({}, args)
                assert.spy(s).called_with('modname', 'TOPIC', expected)
            end)

            it('calls sendClientCommand on the client', function()
                local s = spy.on(_G, 'sendClientCommand')

                req = ClientRequest:new({ topic = topic, player = player })
                req:send()

                assert.spy(s).called_with('modname', 'TOPIC', match.table())
            end)

            it('calls sendServerCommand with the request player on the server', function()
                local s = spy.on(_G, 'sendServerCommand')

                req = ServerRequest:new({ topic = topic, player = player })
                req:send()

                assert.spy(s).called_with(match.ref(player), 'modname', 'TOPIC', match.table())
            end)

            it('calls sendServerCommand as a broadcast when the request has no player on the server', function()
                local s = spy.on(_G, 'sendServerCommand')

                req = ServerRequest:new({ topic = topic })
                req:send()

                assert.spy(s).called_with('modname', 'TOPIC', match.table())
            end)
        end)
    end)

    describe('#operation', function()
        local req ---@type Request
        before_each(function()
            req = ClientRequest:new({ topic = topic, player = player, args = { flag = true } })
        end)

        describe('__tostring', function()
            it('returns the request as a string', function()
                assert.is_string(tostring(req))
            end)

            it('calls stringifyArgs on the request topic for request arguments', function()
                local _stringifyArgs = stub(Topic, 'stringifyArgs'):auto_revert()

                assert.is_string(tostring(req))

                assert.spy(_stringifyArgs).called_with(match.ref(topic), match.ref(req))
            end)
        end)
    end)
end)
