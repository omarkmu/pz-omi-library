---Contains tests for the PlayerCache component.
---@using omi

local cache = require 'OmiLibrary/Module/Cache'

local MOCK_ONLINE_ID = 0
local MOCK_USERNAME = 'MockUsername'
local MOCK_FORENAME = 'Bob'
local MOCK_SURNAME = 'Ross'
local MOCK_FACTION = 'Cool Faction'
local MOCK_COLOR = { r = 10, g = 20, b = 30 }

describe('#component PlayerCache #method', function()
    local player ---@type IsoPlayer
    local playerCache ---@type PlayerCache<PlayerCacheData>
    local expectedData ---@type table
    before_each(function()
        player = zomboid.player({
            onlineID = MOCK_ONLINE_ID,
            username = MOCK_USERNAME,
            forename = MOCK_FORENAME,
            surname = MOCK_SURNAME,
            speechColor = MOCK_COLOR,
            faction = MOCK_FACTION,
        })

        playerCache = cache.player()

        ---@type PlayerCacheData
        expectedData = {
            onlineID = MOCK_ONLINE_ID,
            username = MOCK_USERNAME,
            forename = MOCK_FORENAME,
            surname = MOCK_SURNAME,
            speechColor = MOCK_COLOR,
            faction = MOCK_FACTION,
        }
    end)

    after_each(zomboid.revert_players)

    describe('createPlayerData', function()
        it('creates player data matching a player', function()
            assert.same(expectedData, playerCache:createPlayerData(player))
        end)

        it('creates player data with a default color if no color is found', function()
            stub(player, 'getSpeakColour')

            expectedData.speechColor = { r = 255, g = 255, b = 255 }
            assert.same(expectedData, playerCache:createPlayerData(player))
        end)

        it('calls the onCreatePlayerData callback', function()
            local f = spy.new(function() return {} end)
            playerCache = cache.player({ onCreatePlayerData = f --[[@as function]] })

            playerCache:createPlayerData(player)

            assert.spy(f).called(1)
        end)
    end)

    describe('defaultCreateItemData', function()
        it('creates player data given a username', function()
            assert.is_table(playerCache:defaultCreateItemData('username', MOCK_USERNAME))
        end)

        it('creates player data given an online ID', function()
            assert.is_table(playerCache:defaultCreateItemData('onlineID', MOCK_ONLINE_ID))
        end)

        it('returns nil given an invalid index', function()
            assert.is_nil(playerCache:defaultCreateItemData('forename', MOCK_FORENAME))
        end)
    end)

    describe('get', function()
        it('creates cache items on cache miss', function()
            assert.equal(0, playerCache:count())
            assert.same(expectedData, playerCache:get(MOCK_ONLINE_ID))
            assert.equal(1, playerCache:count())
        end)
    end)

    describe('iterate', function()
        it('allows iteration over cache items', function()
            local otherOnlineID = 1
            zomboid.player({
                onlineID = otherOnlineID,
                username = 'PlayerTwo',
                forename = 'Kate',
            })

            playerCache:get(MOCK_ONLINE_ID)
            playerCache:get(otherOnlineID)

            assert.equal(2, playerCache:count())

            local iterator = playerCache:iterate()

            local key, value = iterator()
            assert.is_number(key)
            assert.is_table(value)

            key, value = iterator()
            assert.is_number(key)
            assert.is_table(value)

            key, value = iterator()
            assert.is_nil(key)
            assert.is_nil(value)
        end)
    end)

    describe('updatePlayer', function()
        it('updates the cache with information from a player', function()
            playerCache:get(MOCK_ONLINE_ID)
            assert.equal(1, playerCache:count())
            assert.same(expectedData, playerCache:get(MOCK_ONLINE_ID))

            stub(player, 'getSpeakColour', Color.new(100, 100, 100))
            playerCache:updatePlayer(player)

            expectedData.speechColor = { r = 100, g = 100, b = 100 }
            assert.same(expectedData, playerCache:get(MOCK_ONLINE_ID))
        end)
    end)
end)
