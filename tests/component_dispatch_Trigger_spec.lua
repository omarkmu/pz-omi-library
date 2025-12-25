---Contains tests for the dispatch trigger helper functions.

local Trigger = require 'OmiLibrary/Component/Dispatch/Trigger'

describe('Trigger #function', function()
    describe('everyDay', function()
        it('creates an EveryDay trigger', function()
            local trigger = Trigger.everyDay()
            assert.same({
                type = 'EveryDay',
                options = {},
            }, trigger)
        end)
    end)

    describe('everyHour', function()
        it('creates an EveryHour trigger', function()
            local trigger = Trigger.everyHour()
            assert.same({
                type = 'EveryHour',
                options = {},
            }, trigger)
        end)
    end)

    describe('everyTenMinutes', function()
        it('creates an EveryTenMinutes trigger', function()
            local trigger = Trigger.everyTenMinutes()
            assert.same({
                type = 'EveryTenMinutes',
                options = {},
            }, trigger)
        end)
    end)

    describe('everyMinute', function()
        it('creates an EveryMinute trigger', function()
            local trigger = Trigger.everyMinute()
            assert.same({
                type = 'EveryMinute',
                options = {},
            }, trigger)
        end)
    end)

    describe('onInterval', function()
        it('creates an Interval trigger with the given value', function()
            local trigger = Trigger.onInterval(1000)
            assert.same({
                type = 'Interval',
                options = { interval = 1000 },
            }, trigger)
        end)
    end)

    describe('onPlayerJoined', function()
        it('creates a PlayerJoined trigger', function()
            local trigger = Trigger.onPlayerJoined()
            assert.same({
                type = 'PlayerJoined',
                options = {},
            }, trigger)
        end)
    end)

    describe('onPlayerDeath', function()
        it('creates a PlayerDeath trigger', function()
            local trigger = Trigger.onPlayerDeath()
            assert.same({
                type = 'PlayerDeath',
                options = {},
            }, trigger)
        end)

        it('creates a PlayerDeath trigger with the given options', function()
            local trigger = Trigger.onPlayerDeath({ onlyPlayer1 = true })
            assert.same({
                type = 'PlayerDeath',
                options = { onlyPlayer1 = true },
            }, trigger)
        end)
    end)
end)
