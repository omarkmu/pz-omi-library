---Contains tests for the Schema component.
---@using omi
---@diagnostic disable: access-invisible, inject-field

require 'OmiLibrary/Module/Core'
local schema = require 'OmiLibrary/Module/Schema'

describe('#component Schema #method', function()
    local instance ---@type Schema
    before_each(function()
        instance = schema.new {
            properties = {
                x = schema.int(100),
                y = schema.double(200),
                z = schema.string('300'),
            },
        }
    end)

    describe('fields', function()
        it('returns an iterator over fields', function()
            local iterator = instance:fields()

            local field = iterator()
            assert.is_instance(field, schema.IntegerField)

            field = iterator()
            assert.is_instance(field, schema.DoubleField)

            field = iterator()
            assert.is_instance(field, schema.StringField)

            field = iterator()
            assert.is_nil(field)
        end)
    end)

    describe('getDefaults', function()
        it('returns a table of default values', function()
            local expected = {
                x = 100,
                y = 200,
                z = '300',
            }

            local result = instance:getDefaults()
            assert.same(expected, result)
        end)
    end)

    describe('getFieldCount', function()
        it('returns the field count', function()
            assert.equal(3, instance:getFieldCount())
        end)
    end)

    describe('getFields', function()
        it('returns a copy of the field list', function()
            local fields = instance:getFields()

            assert.same(instance.fieldList, fields)
            assert.is_not_equal(instance.fieldList, fields)
        end)
    end)

    describe('getFormGenerator', function()
        it('returns a form generator', function()
            local expected = {}
            local _generator = spy.new(function() return expected end)

            stub.module('OmiLibrary', {
                ui = {
                    forms = { generator = _generator },
                },
            }):auto_revert()

            local result = instance:getFormGenerator()

            assert.spy(_generator).called(1)
            assert.equal(expected, result)
        end)

        it('throws an error when called on the server', function()
            stub(_G, 'isServer', true):auto_revert()

            assert.error(function() instance:getFormGenerator() end, 'Forms can only be generated client-side.')
        end)
    end)

    describe('generateForm', function()
        it('calls generate on the form generator', function()
            local expected = {}
            local s = spy.new(function() return expected end)

            local generator = { generate = s }
            local _generator = spy.new(function() return generator end)
            stub.module('OmiLibrary', {
                ui = {
                    forms = { generator = _generator },
                },
            }):auto_revert()

            local result = instance:generateForm()

            assert.spy(s).called(1)
            assert.spy(_generator).called(1)
            assert.equal(expected, result)
        end)

        it('throws an error when called on the server', function()
            stub(_G, 'isServer', true):auto_revert()

            assert.error(function() instance:generateForm() end, 'Forms can only be generated client-side.')
        end)
    end)

    describe('read', function()
        it('calls the read method on all fields', function()
            local _IntegerField_read = spy.on(schema.IntegerField, 'read')
            local _DoubleField_read = spy.on(schema.DoubleField, 'read')
            local _StringField_read = spy.on(schema.StringField, 'read')

            instance:read({ source = {} })

            assert.spy(_IntegerField_read).called(1)
            assert.spy(_DoubleField_read).called(2) -- integer field uses double field read
            assert.spy(_StringField_read).called(1)
        end)

        it('calls transform functions to modify source data', function()
            local transform1 = spy.new(function(values)
                values.x = values.x + 1
                return values
            end)
            local transform2 = spy.new(function(values)
                values.x = values.x * 3
                return values
            end)

            instance = schema.new {
                properties = {
                    x = schema.int(10),
                },
                transforms = {
                    transform1 --[[@as function]],
                    transform2 --[[@as function]],
                },
            }

            local result = instance:read({ source = { x = 10 } })
            assert.same({ x = 33 }, result)
            assert.spy(transform1).called(1)
            assert.spy(transform2).called(1)
        end)

        it('calls the onRead callback', function()
            local _onRead = spy.new()

            instance = schema.new {
                onRead = _onRead --[[@as function]],
                properties = {},
            }

            instance:read({ source = {} })
            assert.spy(_onRead).called(1)
        end)
    end)

    describe('readFile', function()
        it('reads a table from a JSON file', function()
            zomboid.set_cache_file('table.json', '{"x": 10, "y": 20, "z": "30"}')
            finally(zomboid.revert_files)

            local decoded, err = instance:readFile('table.json')
            assert.is_table(decoded) ---@cast decoded table
            assert.is_nil(err)

            assert.equal(10, decoded.x)
            assert.equal(20, decoded.y)
            assert.equal('30', decoded.z)
        end)

        it('returns nil and an error when reading a JSON file fails', function()
            local _getFileReader = stub(_G, 'getFileReader'):auto_revert()

            local decoded, err = instance:readFile('table.json')
            assert.is_nil(decoded)
            assert.is_string(err)
        end)

        it('returns the given destination table', function()
            local dest = {}
            local expected = {
                x = 1,
                y = 200,
                z = '300',
            }

            instance:read({ dest = dest, source = { x = 1 } })
            assert.same(expected, dest)
        end)

        it('returns a new table when no destination is given', function()
            local expected = {
                x = 100,
                y = 2,
                z = '300',
            }

            local result = instance:read({ source = { y = 2 } })
            assert.same(expected, result)
        end)
    end)

    describe('sanitize', function()
        it('calls the sanitize callback', function()
            local _sanitize = spy.new()

            instance = schema.new {
                sanitize = _sanitize --[[@as function]],
                properties = {},
            }

            instance:sanitize({})
            assert.spy(_sanitize).called(1)
        end)
    end)
end)
