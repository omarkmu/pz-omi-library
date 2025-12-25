---Contains tests for the Field component.
---@using omi
---@diagnostic disable: access-invisible

require 'OmiLibrary/Module/Core'
local schema = require 'OmiLibrary/Module/Schema'

describe('#component Field #method', function()
    local intField ---@type schema.IntegerField
    local stringField ---@type schema.StringField
    local objectField ---@type schema.ObjectField
    local arrayField ---@type schema.ArrayField
    local objectField_getDefault = spy.new(function()
        return {
            age = 50,
            name = 'John Zomboid',
        }
    end)

    local instance ---@type Schema
    before_each(function()
        intField = schema.int(500)
        stringField = schema.string('string value')
        arrayField = schema.array {
            items = schema.string(),
        }

        objectField = schema.object({
            getDefault = objectField_getDefault --[[@as function]],
            properties = {
                age = schema.int(1),
                name = schema.string(),
            },
        })

        instance = schema.new {
            properties = {
                int = intField,
                string = stringField,
                object = objectField,
                array = arrayField,
            },
        }
    end)

    describe('fields', function()
        it('returns an iterator over child fields', function()
            local iterator = objectField:fields()

            local field = iterator()
            assert.is_instance(field, schema.IntegerField)

            field = iterator()
            assert.is_instance(field, schema.StringField)

            field = iterator()
            assert.is_nil(field)
        end)
    end)

    describe('getDefault', function()
        it('calls the given callback', function()
            local expected = {
                age = 50,
                name = 'John Zomboid',
            }

            local default = objectField:getDefault(instance)

            assert.same(expected, default)
            assert.spy(objectField_getDefault).called(1)
        end)
    end)

    describe('getEnumValues', function()
        it('returns an empty table for types without enumeration', function()
            assert.same({}, intField:getEnumValues())
            assert.same({}, stringField:getEnumValues())
            assert.same({}, objectField:getEnumValues())
            assert.same({}, arrayField:getEnumValues())
        end)
    end)

    describe('getFieldCount', function()
        it('returns the number of child fields', function()
            assert.equal(2, objectField:getFieldCount())
        end)
    end)

    describe('getFields', function()
        it('can return a copy of the field list', function()
            local fields = objectField:getFields()

            assert.same(objectField.fieldList, fields)
            assert.is_not_equal(objectField.fieldList, fields)
        end)
    end)

    describe('getKey', function()
        it('returns the key set by the schema', function()
            assert.equal('int', intField:getKey())
            assert.equal('string', stringField:getKey())
            assert.equal('object', objectField:getKey())
            assert.equal('array', arrayField:getKey())
        end)
    end)

    describe('getType', function()
        it('returns a string representing the field type', function()
            assert.equal('integer', intField:getType())
            assert.equal('string', stringField:getType())
            assert.equal('object', objectField:getType())
            assert.equal('array', arrayField:getType())
        end)
    end)

    describe('read', function()
        it('throws a not implemented error', function()
            assert.error(function()
                local opts = { schema = instance, skipMissing = false }
                schema.Field.read(objectField, opts)
            end, 'not implemented')
        end)
    end)
end)
