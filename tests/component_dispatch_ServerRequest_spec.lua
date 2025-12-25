---Contains tests for the ServerRequest component.
---@using omi
---@diagnostic disable: access-invisible

local Dispatcher = require 'OmiLibrary/Component/Dispatch/Dispatcher'
local ServerRequest = require 'OmiLibrary/Component/Dispatch/ServerRequest'

describe('#component ServerRequest', function()
    describe('#method', function()
        local dispatch ---@type Dispatcher
        local topic ---@type Topic
        setup(function()
            dispatch = Dispatcher:new({ module = 'modname' })
            topic = dispatch:topic('TOPIC')
        end)

        local req ---@type ServerRequest
        before_each(function()
            req = ServerRequest:new({ topic = topic })
        end)

        describe('isFromServer', function()
            it('returns true', function()
                assert.is_true(req:isFromServer())
            end)
        end)
    end)
end)
