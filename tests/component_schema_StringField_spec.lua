---Contains tests for the StringField component.
---@using omi

require 'OmiLibrary/Module/Core'
local schema = require 'OmiLibrary/Module/Schema'

describe('#component StringField #method', function()
    local stringField ---@type schema.StringField
    local instance ---@type Schema
    before_each(function()
        stringField = schema.string('default')
        instance = schema.new {
            properties = {
                string = stringField,
            },
        }
    end)

    describe('read', function()
        it('returns the default value when no value is given', function()
            assert.equal('default', stringField:read({ schema = instance, skipMissing = false }))
        end)

        it('returns a string', function()
            assert.equal('true', stringField:read({ value = true, schema = instance, skipMissing = false }))
            assert.equal('10', stringField:read({ value = 10, schema = instance, skipMissing = false }))
        end)
    end)
end)
