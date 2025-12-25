---Contains tests for the BooleanField component.

require 'OmiLibrary/Module/Core'
local schema = require 'OmiLibrary/Module/Schema'

describe('#component BooleanField #method', function()
    describe('read', function()
        it('returns the default value when no value is given', function()
            local boolField = schema.bool(true)
            local instance = schema.new {
                properties = {
                    bool = boolField,
                },
            }

            assert.equal(true, boolField:read({ schema = instance, skipMissing = false }))
        end)
    end)
end)
