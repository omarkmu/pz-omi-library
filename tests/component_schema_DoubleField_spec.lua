---Contains tests for the DoubleField component.
---@using omi

require 'OmiLibrary/Module/Core'
local schema = require 'OmiLibrary/Module/Schema'

describe('#component DoubleField #method', function()
    local doubleField ---@type schema.DoubleField
    local instance ---@type Schema
    before_each(function()
        doubleField = schema.double(3.14, 1, 10)
        instance = schema.new {
            properties = {
                double = doubleField,
            },
        }
    end)

    describe('getMaximum', function()
        it('returns the maximum value', function()
            assert.equal(10, doubleField:getMaximum())
        end)
    end)

    describe('getMinimum', function()
        it('returns the minimum value', function()
            assert.equal(1, doubleField:getMinimum())
        end)
    end)

    describe('read', function()
        it('returns the default value when no value is given', function()
            assert.equal(3.14, doubleField:read({ schema = instance, skipMissing = false }))
        end)

        it('clamps values between the min and max', function()
            local result = doubleField:read({
                value = -10,
                schema = instance,
                skipMissing = false,
            })
            assert.equal(1, result)

            result = doubleField:read({
                value = 50,
                schema = instance,
                skipMissing = false,
            })
            assert.equal(10, result)
        end)
    end)
end)
