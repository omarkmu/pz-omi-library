---Contains tests for the interpolation module.
---@diagnostic disable: access-invisible

local interpolate = require 'OmiLibrary/Module/Interpolation'

describe('#function interpolate', function()
    it('calls the interpolate.run function with the given arguments', function()
        local _run = spy.on(interpolate, 'run')

        interpolate('$token')

        assert.spy(_run).called_with('$token')
    end)
end)

describe('#module interpolate #function', function()
    describe('register', function()
        it('calls Interpolator.register', function()
            local _register = spy.on(interpolate.Interpolator, 'register')

            local f = function() end
            interpolate.register('Function', f)

            assert.spy(_register).called_with('Function', f)
        end)
    end)

    describe('run', function()
        it('calls Interpolator.interpolate', function()
            local _interpolate = spy.on(interpolate.Interpolator, 'interpolate')

            local tokens = { name = 'Amir' }
            interpolate.run('Hello, $name!', tokens)

            assert.spy(_interpolate).called_with(match._, 'Hello, $name!', match.ref(tokens))
        end)

        it('calls Interpolator.interpolate when given options', function()
            local _interpolate = spy.on(interpolate.Interpolator, 'interpolate')

            local tokens = { name = 'Phoebe' }
            local options = { caseSensitiveFunctions = true }
            interpolate.run('Goodbye, $name.', tokens, options)

            assert.spy(_interpolate).called_with(match._, 'Goodbye, $name.', match.ref(tokens))
        end)
    end)
end)
