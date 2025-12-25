---Contains tests for the ColorField component.
---@using omi

require 'OmiLibrary/Module/Core'
local schema = require 'OmiLibrary/Module/Schema'

describe('#component ColorField #method', function()
    local colorField ---@type schema.ColorField
    local instance ---@type Schema
    before_each(function()
        colorField = schema.color({ default = { r = 50, g = 50, b = 50 } })
        instance = schema.new {
            properties = {
                color = colorField,
            },
        }
    end)

    describe('read', function()
        it('returns the default value when no value is given', function()
            local expected = { r = 50, g = 50, b = 50 }
            local result = colorField:read({ schema = instance, skipMissing = false })
            assert.same(expected, result)
        end)

        it('returns the given value if it is a color table', function()
            local expected = { r = 100, g = 100, b = 150 }
            local result = colorField:read({ value = expected, schema = instance, skipMissing = false })
            assert.same(expected, result)
        end)

        it('returns white if the given value is not a color table', function()
            local value = { r = 500, g = -40, b = 256 }
            local expected = { r = 255, g = 255, b = 255 }
            local result = colorField:read({ value = value, schema = instance, skipMissing = false })
            assert.same(expected, result)
        end)
    end)
end)
