---Contains tests for the SetField component.
---@using omi

require 'OmiLibrary/Module/Core'
local schema = require 'OmiLibrary/Module/Schema'

describe('#component SetField #method', function()
    local innerField ---@type schema.StringEnumField
    local setField ---@type schema.SetField
    local instance ---@type Schema
    before_each(function()
        innerField = schema.stringEnum({ values = { 'A', 'B', 'C', 'D' } })
        setField = schema.set { items = innerField }
        instance = schema.new {
            properties = {
                set = setField,
            },
        }
    end)

    describe('getEnumValues', function()
        it('returns the enumeration values of the items field', function()
            local s = spy.on(schema.StringEnumField, 'getEnumValues')

            local values = setField:getEnumValues()

            assert.spy(s).called(1)
            assert.same({ 'A', 'B', 'C', 'D' }, values)
        end)
    end)

    describe('getItemsField', function()
        it('returns the field used for items', function()
            assert.equal(innerField, setField:getItemsField())
        end)
    end)

    describe('read', function()
        it('returns an empty table when no value is given', function()
            assert.same({}, setField:read({ schema = instance, skipMissing = false }))
        end)

        it('reads the given values as a set', function()
            local expected = { A = true, C = true }
            local value = { A = true, C = 'something' }
            assert.same(expected, setField:read({ value = value, schema = instance, skipMissing = false }))
        end)
    end)
end)
