---Contains tests for the configuration module.
---@using omi
---@diagnostic disable: inject-field

local configuration = require 'OmiLibrary/Module/Configuration'

describe('#function configuration', function()
    it('calls the configuration.new function with the given arguments', function()
        local s = spy.on(configuration, 'new')
        local options = {
            schema = {},
        }

        configuration(options --[[@as Args.ConfigurationHelper]])
        assert.spy(s).called_with(match.ref(options))
    end)
end)

describe('#module configuration #function', function()
    describe('new', function()
        it('returns a ConfigurationHelper', function()
            local options = {
                schema = {},
            }

            local instance = configuration(options --[[@as Args.ConfigurationHelper]])
            assert.is_table(instance)
        end)
    end)
end)
