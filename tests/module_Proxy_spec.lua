---Contains tests for the proxy module function.
---@using omi
---@diagnostic disable: access-invisible

local proxy = require 'OmiLibrary/Module/Proxy'
local Logger = require 'OmiLibrary/Component/Logging/Logger'

describe('#module #function proxy', function()
    before_each(function()
        Logger._instances = {}
    end)

    it('returns a proxy table for core utilities given a string', function()
        local instance = proxy('mod_id')
        assert.is_table(instance)
    end)

    it('returns a proxy table for core utilities given a table', function()
        local instance = proxy({ id = 'mod_id' })
        assert.is_table(instance)
    end)

    it('uses the provided logger if given', function()
        local t = {}
        local instance = proxy { id = 'mod_id', logger = t --[[@as Logger]] }

        assert.equal(t, instance.log)
    end)

    it('creates a logger if not given', function()
        local instance = proxy { id = 'mod_id' }

        assert.is_instance(instance.log, Logger)
    end)

    it('creates a logger with the given name if not given', function()
        local instance = proxy { id = 'mod_id', name = 'ModName' }

        local logger = instance.log
        assert.is_instance(logger, Logger) ---@cast logger -?
        assert.equal('ModName', logger.name)
    end)
end)
