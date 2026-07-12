---Contains tests for the ClientRequest component.
---@using omi
---@diagnostic disable: access-invisible

local ClientRequest = require 'OmiLibrary/Component/Dispatch/ClientRequest'
local Dispatcher = require 'OmiLibrary/Component/Dispatch/Dispatcher'
local Channel = require 'OmiLibrary/Component/Dispatch/Channel'

describe('#component ClientRequest', function()
    describe('#constructor', function()
        it('throws an error if not given a player', function()
            ---@diagnostic disable-next-line: missing-fields, param-type-mismatch
            assert.error(function() ClientRequest:new({}) end, 'ClientRequest is missing player')
        end)
    end)

    describe('#method', function()
        local dispatch ---@type Dispatcher
        local channel ---@type Channel
        local adminChannel ---@type Channel
        local player ---@type IsoPlayer
        setup(function()
            dispatch = Dispatcher:new({ module = 'modname' })
            channel = dispatch:channel('CHANNEL')
            adminChannel = dispatch:channel('ADMIN_CHANNEL', { requireAdmin = true })

            player = zomboid.player()
        end)

        teardown(zomboid.revert_players)

        local req ---@type ClientRequest
        before_each(function()
            req = ClientRequest:new({ channel = channel, player = player })
        end)

        describe('canReceive', function()
            local validationErr
            local isValid = true
            before_each(function()
                isValid = true
                validationErr = nil
                stub(Channel, 'validateOnServer', function() return isValid, validationErr end):auto_revert()
            end)

            it('returns false and an error message if the player has insufficient permissions', function()
                req = ClientRequest:new({ channel = adminChannel, player = player })

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

            it('returns true when receiving a request on an admin-only channel from an admin player', function()
                req = ClientRequest:new({ channel = adminChannel, player = player })

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
            before_each(function() _validateOnClient = stub(Channel, 'validateOnClient', true) end)
            after_each(function() _validateOnClient:revert() end)

            it('returns false and an error message if the player has insufficient permissions', function()
                req = ClientRequest:new({ channel = adminChannel, player = player })

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
                _validateOnClient = stub(Channel, 'validateOnClient', false, 'Invalid arguments')

                local canSend, reason = req:canSend()

                assert.is_false(canSend)
                assert.equal('Invalid arguments', reason)
            end)

            it('returns false and a generic error message when client validation fails with no message', function()
                _validateOnClient:revert()
                _validateOnClient = stub(Channel, 'validateOnClient', false)

                local canSend, reason = req:canSend()

                assert.is_false(canSend)
                assert.equal('Validation failed', reason)
            end)

            it('returns true when the request can be send', function()
                local canSend, reason = req:canSend()

                assert.is_true(canSend)
                assert.is_nil(reason)
            end)

            it('returns true when sending a request on an admin-only channel as an admin player', function()
                stub(player, 'isAccessLevel')
                    :auto_revert()
                    .on_call_with(player, 'Admin').returns(true)

                req = ClientRequest:new({ channel = adminChannel, player = player })
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
