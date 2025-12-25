---Contains tests for the schema module.
---@diagnostic disable: access-invisible, inject-field, need-check-nil

require 'OmiLibrary/Module/Core'
local schema = require 'OmiLibrary/Module/Schema'

describe('#function schema', function()
    it('calls the schema.new function with the given arguments', function()
        local s = spy.on(schema, 'new')

        local options = { properties = {} }
        schema(options)
        assert.spy(s).called_with(options)
    end)
end)

describe('#module schema #function', function()
    describe('array', function()
        it('returns an ArrayField', function()
            local field = schema.array { items = schema.string() }
            assert.is_instance(field, schema.ArrayField)
        end)
    end)

    describe('bool', function()
        it('returns a BooleanField', function()
            assert.is_instance(schema.bool(), schema.BooleanField)
        end)

        it('accepts a boolean argument for the default value', function()
            local trueBool = schema.bool(true)
            local falseBool = schema.bool(false)

            local instance = schema.new({
                properties = {
                    truthy = trueBool,
                    falsy = falseBool,
                },
            })

            assert.is_true(trueBool:getDefault(instance))
            assert.is_false(falseBool:getDefault(instance))
        end)
    end)

    describe('color', function()
        it('returns a ColorField', function()
            assert.is_instance(schema.color(), schema.ColorField)
        end)
    end)

    describe('compatibility', function()
        it('returns a CompatibilityField', function()
            assert.is_instance(schema.compatibility(), schema.CompatibilityField)
        end)

        it('accepts a string argument for the default value', function()
            local field = schema.compatibility('Disable')

            local instance = schema.new({
                properties = { compat = field },
            })

            assert.equal('Disable', field:getDefault(instance))
        end)
    end)

    describe('container', function()
        it('returns an ObjectField', function()
            assert.is_instance(schema.container({}), schema.ObjectField)
        end)
    end)

    describe('double', function()
        it('returns a DoubleField', function()
            assert.is_instance(schema.double(1), schema.DoubleField)
        end)

        it('accepts number arguments for the default, minimum, and maximum values', function()
            local field = schema.double(5, 0, 10)

            local instance = schema.new({
                properties = { num = field },
            })

            assert.equal(5, field:getDefault(instance))
            assert.equal(0, field:getMinimum())
            assert.equal(10, field:getMaximum())
        end)

        it('does not mutate the input options table with minimum and maximum values', function()
            local options = { default = 5 }
            local field = schema.double(options, 0, 10)

            assert.same({ default = 5 }, options)

            assert.equal(0, field:getMinimum())
            assert.equal(10, field:getMaximum())
        end)
    end)

    describe('int', function()
        it('returns an IntegerField', function()
            assert.is_instance(schema.int(1), schema.IntegerField)
        end)

        it('accepts integer arguments for the default, minimum, and maximum values', function()
            local field = schema.int(5, 0, 10)

            local instance = schema.new({
                properties = { num = field },
            })

            assert.equal(5, field:getDefault(instance))
            assert.equal(0, field:getMinimum())
            assert.equal(10, field:getMaximum())
        end)

        it('does not mutate the input options table with minimum and maximum values', function()
            local options = { default = 5 }
            local field = schema.int(options, 0, 10)

            assert.same({ default = 5 }, options)

            assert.equal(0, field:getMinimum())
            assert.equal(10, field:getMaximum())
        end)
    end)

    describe('object', function()
        it('returns an ObjectField', function()
            assert.is_instance(schema.object({}), schema.ObjectField)
        end)
    end)

    describe('read', function()
        after_each(zomboid.revert_files)

        it('can use a given file reader', function()
            zomboid.set_cache_file('test.json', '{"field": "value"}')
            local result, err = schema.read({ reader = getFileReader('test.json', false) })

            assert.same({ field = 'value' }, result)
            assert.is_nil(err)
        end)

        it('returns the JSON-decoded file content', function()
            zomboid.set_cache_file('test.json', '{"field": "value"}')
            local result, err = schema.read('test.json')

            assert.same({ field = 'value' }, result)
            assert.is_nil(err)
        end)

        it('returns an error if the file could not be opened', function()
            stub(_G, 'getFileReader', function() error('test error') end):auto_revert()

            local result, err = schema.read('unknown.json')

            assert.is_nil(result)
            assert.equal('could not open file unknown.json', err)
        end)

        it('returns an empty object for an empty file', function()
            zomboid.set_cache_file('empty.json', '')

            local result, err = schema.read('empty.json')

            assert.same({}, result)
            assert.is_nil(err)
        end)

        it('returns an error for non-JSON content', function()
            zomboid.set_cache_file('not.json', 'hello!')

            local result, err = schema.read('not.json')

            assert.is_nil(result)
            assert.is_string(err)
        end)

        it('returns an error for an invalid JSON type', function()
            zomboid.set_cache_file('string.json', '"hello, world!"')

            local result, err = schema.read('string.json')

            assert.is_nil(result)
            assert.equal('invalid file content', err)
        end)
    end)

    describe('set', function()
        it('returns a SetField', function()
            assert.is_instance(schema.set({ items = schema.string() }), schema.SetField)
        end)
    end)

    describe('string', function()
        it('returns a StringField', function()
            assert.is_instance(schema.string(), schema.StringField)
        end)

        it('accepts a string argument for the default value', function()
            local field = schema.string('DEFAULT')
            local instance = schema.new({
                properties = {
                    str = field,
                },
            })

            assert.equal('DEFAULT', field:getDefault(instance))
        end)
    end)

    describe('stringEnum', function()
        it('returns an StringEnumField', function()
            assert.is_instance(schema.stringEnum({}), schema.StringEnumField)
        end)
    end)
end)
