---Contains tests for the ConfigurationHelper component.
---@using omi
---@diagnostic disable: undefined-field, inject-field

local core = require 'OmiLibrary/Module/Core'
local schema = require 'OmiLibrary/Module/Schema'
local configuration = require 'OmiLibrary/Module/Configuration'
local ConfigurationHelper = require 'OmiLibrary/Component/Core/ConfigurationHelper'

local FILENAME = 'config.json'
local MOD_DATA_KEY = 'mod_id.config'

describe('#component ConfigurationHelper', function()
    local instance ---@type ConfigurationHelper
    local schemaInstance ---@type Schema
    before_each(function()
        schemaInstance = schema.new {
            properties = {
                str = schema.string('DEFAULT'),
                int = schema.int(0),
            },
        }

        instance = configuration.new({
            filename = FILENAME,
            modDataKey = MOD_DATA_KEY,
            schema = schemaInstance,
        })
    end)

    after_each(function()
        zomboid.revert_files()
        zomboid.revert_mod_data()
    end)

    describe('#method', function()
        describe('getDefaults', function()
            it('returns a table of defaults', function()
                local expected = {
                    int = 0,
                    str = 'DEFAULT',
                }

                assert.same(expected, instance:getDefaults())
            end)
        end)

        describe('getFilename', function()
            it('returns the given filename', function()
                assert.equal(FILENAME, instance:getFilename())
            end)
        end)

        describe('getSchema', function()
            it('returns the given schema', function()
                assert.equal(schemaInstance, instance:getSchema())
            end)
        end)

        describe('getModDataKey', function()
            it('returns the mod data key', function()
                assert.equal(MOD_DATA_KEY, instance:getModDataKey())
            end)
        end)

        describe('init', function()
            it('sets the initialized flag', function()
                assert.is_false(instance:isInitialized())
                instance:init()
                assert.is_true(instance:isInitialized())
            end)

            it('calls the init callback', function()
                local f = spy.new()
                instance = configuration.new({
                    filename = FILENAME,
                    modDataKey = MOD_DATA_KEY,
                    schema = schemaInstance,
                    init = f --[[@as function]],
                })

                instance:init()
                assert.spy(f).called(1)
            end)

            it('only initializes once', function()
                local s = spy.on(ConfigurationHelper, '_init')
                instance:init()
                instance:init()

                assert.spy(s).called(1)
            end)

            it('loads from a file if a filename is given', function()
                zomboid.set_cache_file(FILENAME, '{"str":"hello world","int":100}')
                instance:init()

                local expected = {
                    int = 100,
                    str = 'hello world',
                }

                assert.same(expected, instance:getValues())
            end)

            it('loads from defaults if no filename is given', function()
                instance = configuration.new({
                    modDataKey = MOD_DATA_KEY,
                    schema = schemaInstance,
                })

                instance:init()

                local expected = {
                    int = 0,
                    str = 'DEFAULT',
                }

                assert.same(expected, instance:getValues())
            end)
        end)

        describe('load', function()
            it('reads configuration values from a table', function()
                instance:load({ str = 'hello', int = 900 })

                local expected = { str = 'hello', int = 900 }
                assert.same(expected, instance:getValues())
            end)

            it('calls the onLoad callback', function()
                local f = spy.new()
                instance = configuration.new({
                    filename = FILENAME,
                    modDataKey = MOD_DATA_KEY,
                    schema = schemaInstance,
                    onLoad = f --[[@as function]],
                })

                instance:load({})
                assert.spy(f).called(1)
            end)
        end)

        describe('loadDefaults', function()
            it('loads the default schema values', function()
                instance:loadDefaults()

                local expected = {
                    int = 0,
                    str = 'DEFAULT',
                }

                assert.same(expected, instance:getValues())
            end)
        end)

        describe('loadFile', function()
            it('returns false when no filename was given', function()
                instance = configuration.new({
                    modDataKey = MOD_DATA_KEY,
                    schema = schemaInstance,
                })

                assert.is_false(instance:loadFile())
            end)

            it('returns false when reading the file fails', function()
                stub(_G, 'getFileReader', function() error('test error') end):auto_revert()
                assert.is_false(instance:loadFile())
            end)

            it('calls the onLoad callback', function()
                local f = spy.new()
                instance = configuration.new({
                    filename = FILENAME,
                    modDataKey = MOD_DATA_KEY,
                    schema = schemaInstance,
                    onLoad = f --[[@as function]],
                })

                instance:load({})
                assert.spy(f).called(1)
            end)
        end)

        describe('loadModData', function()
            it('fails when no mod data key is specified', function()
                instance = configuration.new({
                    schema = schemaInstance,
                })

                assert.is_false(instance:loadModData())
            end)

            it('fails when data is not a JSON object', function()
                ModData.add(MOD_DATA_KEY, { data = '"hello!"' })
                assert.is_false(instance:loadModData())
            end)

            it('fails when data is not valid JSON', function()
                ModData.add(MOD_DATA_KEY, { data = 'invalid' })
                assert.is_false(instance:loadModData())
            end)

            it('loads data from JSON stored in mod data', function()
                ModData.add(MOD_DATA_KEY, { data = '{"str":"from mod data","int": 200}' })
                instance:init()

                local expected = {
                    str = 'from mod data',
                    int = 200,
                }

                assert.is_true(instance:loadModData())
                assert.same(expected, instance:getValues())
            end)
        end)

        describe('saveFile', function()
            it('fails when no filename was given', function()
                instance = configuration.new({
                    modDataKey = MOD_DATA_KEY,
                    schema = schemaInstance,
                })

                assert.is_false(instance:saveFile())
            end)

            it('fails when encoding the configuration as JSON fails', function()
                stub(core.json, 'tryEncode', false, 'test error'):auto_revert()
                assert.is_false(instance:saveFile())
            end)

            it('calls the onSaveFile callback', function()
                local f = spy.new()
                instance = configuration.new({
                    filename = FILENAME,
                    modDataKey = MOD_DATA_KEY,
                    schema = schemaInstance,
                    onSaveFile = f --[[@as function]],
                })

                instance:saveFile()
                assert.spy(f).called(1)
            end)

            it('logs errors using the given logger', function()
                local f = spy.new()
                local logger = { error = f }

                instance = configuration.new({
                    modDataKey = MOD_DATA_KEY,
                    schema = schemaInstance,
                    logger = logger --[[@as Logger]],
                })

                instance:init()
                instance:saveFile()

                assert.spy(f).called_with('Failed to write %s: %s', 'configuration', 'no filename specified')
            end)
        end)

        describe('saveModData', function()
            it('fails when no mod data key is specified', function()
                instance = configuration.new({
                    schema = schemaInstance,
                })

                assert.is_false(instance:saveModData())
            end)

            it('fails when encoding the configuration as JSON fails', function()
                stub(core.json, 'tryEncode', false, 'test error'):auto_revert()
                assert.is_false(instance:saveModData())
            end)

            it('saves encoded data to a mod data table', function()
                instance:init()
                instance:load({ str = 'test data', int = 40 })
                assert.is_true(instance:saveModData())

                local expected = {
                    int = 40,
                    str = 'test data',
                }

                local tab = ModData.get(MOD_DATA_KEY)
                assert.is_table(tab)
                assert.is_string(tab.data)
                assert.same(expected, core.json.decode(tab.data))
            end)

            it('calls the onSaveModData callback', function()
                local f = spy.new()
                instance = configuration.new({
                    filename = FILENAME,
                    modDataKey = MOD_DATA_KEY,
                    schema = schemaInstance,
                    onSaveModData = f --[[@as function]],
                })

                instance:saveModData()
                assert.spy(f).called(1)
            end)
        end)
    end)

    describe('#operation', function()
        it('__index can be used to access configuration values', function()
            instance:init()

            assert.equal('DEFAULT', instance.str)
            assert.equal(0, instance.int)
        end)

        it('__newindex can be used to set configuration values', function()
            instance:init()
            instance.str = 'new value'

            local expected = {
                int = 0,
                str = 'new value',
            }

            assert.same(expected, instance:getValues())
        end)
    end)
end)
