---Contains tests for the ObjectField component.
---@using omi

require 'OmiLibrary/Module/Core'
local schema = require 'OmiLibrary/Module/Schema'

describe('#component ObjectField #method', function()
    local innerField ---@type schema.IntegerField
    local objectField ---@type schema.ObjectField
    local instance ---@type Schema
    before_each(function()
        innerField = schema.int(0)
        objectField = schema.object({
            properties = {
                int = innerField,
            },
        })
        instance = schema.new {
            properties = {
                object = objectField,
            },
        }
    end)

    describe('read', function()
        it('returns a default object when no value is given', function()
            assert.same({ int = 0 }, objectField:read({ schema = instance, skipMissing = false }))
        end)

        it('only includes known properties', function()
            local result = objectField:read({
                schema = instance,
                skipMissing = false,
                value = {
                    int = 10,
                    bool = false,
                },
            })

            assert.same({ int = 10 }, result)
        end)

        it('includes extra properties of any type if the option is set to true', function()
            objectField = schema.object({
                additionalProperties = true,
                properties = {
                    int = innerField,
                },
            })
            instance = schema.new {
                properties = {
                    object = objectField,
                },
            }

            local result = objectField:read({
                schema = instance,
                skipMissing = false,
                value = {
                    int = 10,
                    bool = false,
                    string = 'hello',
                },
            })

            local expected = {
                int = 10,
                bool = false,
                string = 'hello',
            }

            assert.same(expected, result)
        end)

        it('includes extra properties as a given field type if the option is set to a field', function()
            objectField = schema.object({
                additionalProperties = schema.string('default'),
                properties = {
                    int = innerField,
                },
            })
            instance = schema.new {
                properties = {
                    object = objectField,
                },
            }

            local result = objectField:read({
                schema = instance,
                skipMissing = false,
                value = {
                    int = 10,
                    bool = false,
                    string = 'hello',
                },
            })

            local expected = {
                int = 10,
                bool = 'false',
                string = 'hello',
            }

            assert.same(expected, result)
        end)
    end)
end)
