---Contains tests for the StringEnumField component.
---@using omi
---@diagnostic disable: access-invisible

require 'OmiLibrary/Module/Core'
local schema = require 'OmiLibrary/Module/Schema'

describe('#component StringEnumField #method', function()
    local enumField ---@type schema.StringEnumField
    local instance ---@type Schema
    before_each(function()
        enumField = schema.stringEnum({ values = { 'A', 'B', 'C', 'D' } })
        instance = schema.new {
            properties = {
                enum = enumField,
            },
        }
    end)

    describe('getEnumValues', function()
        it('returns a copy of the value list', function()
            local values = enumField:getEnumValues()

            assert.same(enumField.valueList, values)
            assert.is_not_equal(enumField.valueList, values)
        end)
    end)

    describe('read', function()
        it('returns the default value when no value is given', function()
            assert.equal('', enumField:read({ schema = instance, skipMissing = false }))
        end)

        it('returns the default value when the value is invalid', function()
            assert.equal('', enumField:read({ value = 'Z', schema = instance, skipMissing = false }))
        end)
    end)
end)
