---Contains tests for the ArrayField component.
---@using omi

require 'OmiLibrary/Module/Core'
local schema = require 'OmiLibrary/Module/Schema'

describe('#component ArrayField #method', function()
    local innerField ---@type schema.StringField
    local arrayField ---@type schema.ArrayField
    local instance ---@type Schema
    before_each(function()
        innerField = schema.string('default')
        arrayField = schema.array {
            maxItems = 3,
            items = innerField,
        }

        instance = schema.new {
            properties = {
                array = arrayField,
            },
        }
    end)

    describe('getItemsField', function()
        it('returns the field used for items', function()
            assert.equal(innerField, arrayField:getItemsField())
        end)
    end)

    describe('getMaximumItems', function()
        it('returns the maximum number of items', function()
            assert.equal(3, arrayField:getMaximumItems())
        end)
    end)

    describe('read', function()
        it('returns an empty list when no value is given', function()
            assert.same({}, arrayField:read({ schema = instance, skipMissing = false }))
        end)

        it('respects the max items field', function()
            local result = arrayField:read({
                value = {
                    'hello',
                    'hi',
                    'greetings',
                    'salutations',
                },
                schema = instance,
                skipMissing = false,
            })

            local expected = {
                'hello',
                'hi',
                'greetings',
            }

            assert.same(expected, result)
        end)
    end)
end)
