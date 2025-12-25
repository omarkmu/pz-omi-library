---Contains tests for the ClientRequest component.
---@using omi
---@diagnostic disable: access-invisible

local ClientRequest = require 'OmiLibrary/Component/Dispatch/ClientRequest'
local Dispatcher = require 'OmiLibrary/Component/Dispatch/Dispatcher'
local Topic = require 'OmiLibrary/Component/Dispatch/Topic'

describe('#component ClientRequest', function()
    describe('#constructor', function()
        it('throws an error if not given a player', function()
            ---@diagnostic disable-next-line: missing-fields, param-type-mismatch
            assert.error(function() ClientRequest:new({}) end, 'ClientRequest is missing player')
        end)
    end)

    describe('#method', function()
        local dispatch ---@type Dispatcher
        local topic ---@type Topic
        local adminTopic ---@type Topic
        local player ---@type IsoPlayer
        setup(function()
            dispatch = Dispatcher:new({ module = 'modname' })
            topic = dispatch:topic('TOPIC')
            adminTopic = dispatch:topic('ADMIN_TOPIC', { requireAdmin = true })

            player = zomboid.player()
        end)

        teardown(zomboid.revert_players)

        local req ---@type ClientRequest
        before_each(function()
            req = ClientRequest:new({ topic = topic, player = player })
        end)

        describe('canReceive', function()
            local validationErr
            local isValid = true
            before_each(function()
                isValid = true
                validationErr = nil
                stub(Topic, 'validateOnServer', function() return isValid, validationErr end):auto_revert()
            end)

            it('returns false and an error message if the player has insufficient permissions', function()
                req = ClientRequest:new({ topic = adminTopic, player = player })

                local canReceive, reason = req:canReceive()

                assert.is_false(canReceive)
                assert.equal('Insufficient permissions', reason)
            end)

            it('returns false and the validation error message when server validation fails', function()
                isValid = false
                validationErr = 'Invalid arguments'
                local canReceive, reason = req:canReceive()

                assert.is_false(canReceive)
                assert.equal('Invalid arguments', reason)
            end)

            it('returns false and a generic error message when server validation fails with no message', function()
                isValid = false
                local canReceive, reason = req:canReceive()

                assert.is_false(canReceive)
                assert.equal('Validation failed', reason)
            end)

            it('returns true when the request can be received', function()
                local canReceive, reason = req:canReceive()

                assert.is_true(canReceive)
                assert.is_nil(reason)
            end)

            it('returns true when receiving an admin-only topic from an admin player', function()
                req = ClientRequest:new({ topic = adminTopic, player = player })

                stub(player, 'isAccessLevel')
                    :auto_revert()
                    .on_call_with(player, 'Admin').returns(true)

                local canReceive, reason = req:canReceive()

                assert.is_true(canReceive)
                assert.is_nil(reason)
            end)
        end)

        describe('canSend', function()
            local _validateOnClient ---@type luassert.spy
            before_each(function() _validateOnClient = stub(Topic, 'validateOnClient', true) end)
            after_each(function() _validateOnClient:revert() end)

            it('returns false and an error message if the player has insufficient permissions', function()
                req = ClientRequest:new({ topic = adminTopic, player = player })

                local canSend, reason = req:canSend()

                assert.is_false(canSend)
                assert.equal('Insufficient permissions', reason)
            end)

            it('returns false and an error message for a dead player character', function()
                stub(player, 'isDead', true):auto_revert()

                local canSend, reason = req:canSend()

                assert.is_false(canSend)
                assert.equal('Player character is dead', reason)
            end)

            it('returns false and the validation error message when client validation fails', function()
                _validateOnClient:revert()
                _validateOnClient = stub(Topic, 'validateOnClient', false, 'Invalid arguments')

                local canSend, reason = req:canSend()

                assert.is_false(canSend)
                assert.equal('Invalid arguments', reason)
            end)

            it('returns false and a generic error message when client validation fails with no message', function()
                _validateOnClient:revert()
                _validateOnClient = stub(Topic, 'validateOnClient', false)

                local canSend, reason = req:canSend()

                assert.is_false(canSend)
                assert.equal('Validation failed', reason)
            end)

            it('returns true when the request can be send', function()
                local canSend, reason = req:canSend()

                assert.is_true(canSend)
                assert.is_nil(reason)
            end)

            it('returns true when sending an admin-only topic as an admin player', function()
                stub(player, 'isAccessLevel')
                    :auto_revert()
                    .on_call_with(player, 'Admin').returns(true)

                req = ClientRequest:new({ topic = adminTopic, player = player })
                local canSend, reason = req:canSend()

                assert.is_true(canSend)
                assert.is_nil(reason)
            end)
        end)

        describe('getPlayer', function()
            it('returns the player associated with the request', function()
                assert.equal(player, req:getPlayer())
            end)
        end)

        describe('isFromClient', function()
            it('returns true', function()
                assert.is_true(req:isFromClient())
            end)
        end)
    end)
end)
