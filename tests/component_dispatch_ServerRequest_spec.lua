---Contains tests for the ServerRequest component.
---@using omi
---@diagnostic disable: access-invisible

local Dispatcher = require 'OmiLibrary/Component/Dispatch/Dispatcher'
local ServerRequest = require 'OmiLibrary/Component/Dispatch/ServerRequest'

describe('#component ServerRequest', function()
    describe('#method', function()
        local dispatch ---@type Dispatcher
        local channel ---@type Channel
        setup(function()
            dispatch = Dispatcher:new({ module = 'modname' })
            channel = dispatch:channel('CHANNEL')
        end)

        local req ---@type ServerRequest
        before_each(function()
            req = ServerRequest:new({ channel = channel })
        end)

        describe('isFromServer', function()
            it('returns true', function()
                assert.is_true(req:isFromServer())
            end)
        end)
    end)
end)
