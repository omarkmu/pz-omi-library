---Contains tests for the Logger component.
---@using omi
---@diagnostic disable: access-invisible

local Logger = require 'OmiLibrary/Component/Logging/Logger'

local MOD_ID = 'mod_id'

---Clears the table containing logger instances.
local function resetLoggers()
    Logger._instances = {}
end

describe('#component Logger', function()
    local _print ---@type luassert.stub
    local _error ---@type luassert.spy
    local instance ---@type Logger

    setup(function()
        _error = spy.on(_G, 'error')
        _print = stub(_G, 'print')
    end)

    before_each(function()
        instance = Logger.create({ id = MOD_ID, level = 'debug' })
        _error:clear()
        _print:clear()
    end)

    setup(resetLoggers)
    after_each(resetLoggers)

    describe('#constructor', function()
        describe('when in debug mode', function()
            setup(function()
                stub(_G, 'getDebug', true):auto_revert()
            end)

            it('defaults to the debug log level', function()
                resetLoggers()
                instance = Logger.create(MOD_ID)
                assert.equal('debug', instance.level)
            end)
        end)

        describe('when not in debug mode', function()
            it('defaults to the info log level', function()
                resetLoggers()
                instance = Logger.create(MOD_ID)
                assert.equal('info', instance.level)
            end)
        end)
    end)

    describe('#function', function()
        describe('log functions', function()
            describe('do not log when below the level', function()
                it('silent', function()
                    instance.level = 'silent'
                    instance.fatal('message')
                    instance.error('message')
                    instance.warn('message')
                    instance.info('message')
                    instance.http('message')
                    instance.verbose('message')
                    instance.debug('message')

                    assert.spy(_error).not_called()
                    assert.spy(_print).not_called()
                end)

                it('fatal', function()
                    instance.level = 'fatal'
                    instance.error('message')
                    instance.warn('message')
                    instance.info('message')
                    instance.http('message')
                    instance.verbose('message')
                    instance.debug('message')

                    assert.spy(_error).not_called()
                    assert.spy(_print).not_called()
                end)

                it('error', function()
                    instance.level = 'error'
                    instance.warn('message')
                    instance.info('message')
                    instance.http('message')
                    instance.verbose('message')
                    instance.debug('message')

                    assert.spy(_error).not_called()
                    assert.spy(_print).not_called()
                end)

                it('warn', function()
                    instance.level = 'warn'
                    instance.info('message')
                    instance.http('message')
                    instance.verbose('message')
                    instance.debug('message')

                    assert.spy(_error).not_called()
                    assert.spy(_print).not_called()
                end)

                it('info', function()
                    instance.level = 'info'
                    instance.http('message')
                    instance.verbose('message')
                    instance.debug('message')

                    assert.spy(_error).not_called()
                    assert.spy(_print).not_called()
                end)

                it('http', function()
                    instance.level = 'http'
                    instance.verbose('message')
                    instance.debug('message')

                    assert.spy(_error).not_called()
                    assert.spy(_print).not_called()
                end)

                it('verbose', function()
                    instance.level = 'verbose'
                    instance.debug('message')

                    assert.spy(_error).not_called()
                    assert.spy(_print).not_called()
                end)
            end)
        end)

        describe('create', function()
            it('returns a new logger', function()
                resetLoggers()
                instance = Logger.create(MOD_ID)
                assert.is_instance(instance, Logger)
            end)

            it('throws an error when attempting to overwrite an existing logger', function()
                assert.error(function() Logger.create(MOD_ID) end, 'Tried to overwrite logger with id mod_id')
            end)
        end)

        describe('exists', function()
            it('returns true for an existing logger', function()
                assert.is_true(Logger.exists(MOD_ID))
            end)

            it('returns false for an unknown logger', function()
                assert.is_false(Logger.exists('UnknownLogger'))
            end)
        end)

        describe('getOrCreate', function()
            it('returns an existing logger if it has already been created', function()
                assert.equal(instance, Logger.getOrCreate(MOD_ID))
            end)

            it('returns a new logger if a logger with the given ID does not exist', function()
                assert.is_instance(Logger.getOrCreate('OtherModName'), Logger)
            end)
        end)

        describe('get', function()
            it('returns an existing logger if it has already been created', function()
                assert.equal(instance, Logger.get(MOD_ID))
            end)

            it('returns nil for a logger that does not exist', function()
                assert.is_nil(Logger.get('OtherModName'))
            end)
        end)

        describe('fatal', function()
            it('throws the message as an error', function()
                assert.error(function() instance.fatal('oops') end, '[mod_id] [Fatal] oops')
            end)
        end)

        describe('error', function()
            it('calls the error function without throwing an error', function()
                instance.error('oops')
                assert.spy(_error).called_with('[mod_id] [Error] oops')
            end)
        end)

        describe('warn', function()
            it('logs a warning message', function()
                instance.warn('watch out')
                assert.spy(_print).called_with('[mod_id] [Warn] watch out')
            end)
        end)

        describe('http', function()
            it('logs an http message', function()
                instance.http('request failed')
                assert.spy(_print).called_with('[mod_id] [HTTP] request failed')
            end)
        end)

        describe('verbose', function()
            it('logs a verbose message', function()
                instance.verbose('start Greeting{target=world}')
                assert.spy(_print).called_with('[mod_id] [Verbose] start Greeting{target=world}')
            end)
        end)

        describe('debug', function()
            it('logs a debug message', function()
                instance.debug('debugging')
                assert.spy(_print).called_with('[mod_id] [Debug] debugging')
            end)
        end)

        describe('info', function()
            it('logs an info message', function()
                instance.info('hello world')
                assert.spy(_print).called_with('[mod_id] [Info] hello world')
            end)

            it('converts non-string, non-number arguments to strings', function()
                local value = setmetatable({}, {
                    __tostring = function()
                        return 'value'
                    end,
                })

                instance.info('%s %s %d', value, 'string', 1)
                assert.spy(_print).called_with('[mod_id] [Info] value string 1')
            end)
        end)

        describe('once', function()
            it('logs a message', function()
                instance.info.once('info message')

                assert.spy(_print).called(1)
                assert.spy(_print).called_with('[mod_id] [Info] info message')
            end)

            it('logs unique messages', function()
                instance.info.once('info message')
                instance.info.once('other info message')

                assert.spy(_print).called(2)
                assert.spy(_print).called_with('[mod_id] [Info] info message')
                assert.spy(_print).called_with('[mod_id] [Info] other info message')
            end)

            it('does not log the same message twice', function()
                instance.info.once('info message')
                instance.info.once('info message')
                assert.spy(_print).called(1)
                assert.spy(_print).called_with('[mod_id] [Info] info message')
            end)
        end)
    end)
end)
