---Contains tests for the IntegerField component.
---@using omi

require 'OmiLibrary/Module/Core'
local schema = require 'OmiLibrary/Module/Schema'

describe('#component IntegerField #method', function()
    local intField ---@type schema.IntegerField
    local instance ---@type Schema
    before_each(function()
        intField = schema.int(0)
        instance = schema.new {
            properties = {
                int = intField,
            },
        }
    end)

    describe('read', function()
        it('returns a floored integer value', function()
            assert.equal(7, intField:read({ schema = instance, skipMissing = false, value = 7.89 }))
        end)
    end)
end)
