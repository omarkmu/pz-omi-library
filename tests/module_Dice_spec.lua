---Contains tests for the Dice module.

local dice = require 'OmiLibrary/Module/Dice'

describe('#module dice #function', function()
    describe('parse', function()
        it('calls parse on a Roller', function()
            local s = spy.on(dice.Roller, 'parse')

            dice.parse('3d6')

            assert.spy(s).called_with(match._, '3d6')
        end)
    end)

    describe('roll', function()
        it('calls roll on a Roller', function()
            local s = spy.on(dice.Roller, 'roll')
            local args = {}

            dice.roll('d8 + 2', args)

            assert.spy(s).called_with(match._, 'd8 + 2', args)
        end)
    end)

    describe('tryParse', function()
        it('calls tryParse on a Roller', function()
            local s = spy.on(dice.Roller, 'tryParse')

            dice.tryParse('d20')

            assert.spy(s).called_with(match._, 'd20')
        end)
    end)

    describe('tryRoll', function()
        it('calls tryRoll on a Roller', function()
            local s = spy.on(dice.Roller, 'tryRoll')
            local args = {}

            dice.tryRoll('3d%', args)

            assert.spy(s).called_with(match._, '3d%', args)
        end)
    end)
end)
