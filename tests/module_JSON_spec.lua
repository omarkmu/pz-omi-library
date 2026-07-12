---Contains tests for the JSON module.

local json = require 'OmiLibrary/Module/JSON'

describe('#module json #function', function()
    describe('decode', function()
        it('calls decode on a Decoder', function()
            local s = spy.on(json.Decoder, 'decode')

            json.decode('{}')

            assert.spy(s).called_with(match._, '{}')
        end)
    end)

    describe('encode', function()
        it('calls encode on an Encoder', function()
            local s = spy.on(json.Encoder, 'encode')

            local tab = {}
            local options = {}
            json.encode(tab, options)

            assert.spy(s).called_with(match._, match.ref(tab), match.ref(options))
        end)
    end)

    describe('tryReadObject', function()
        after_each(zomboid.revert_files)

        it('can use a given file reader', function()
            zomboid.set_cache_file('test.json', '{"field": "value"}')
            local result, err = json.tryReadObject({ reader = getFileReader('test.json', false) })

            assert.same({ field = 'value' }, result)
            assert.is_nil(err)
        end)

        it('returns the JSON-decoded file content', function()
            zomboid.set_cache_file('test.json', '{"field": "value"}')
            local result, err = json.tryReadObject('test.json')

            assert.same({ field = 'value' }, result)
            assert.is_nil(err)
        end)

        it('returns an error if the file could not be opened', function()
            stub(_G, 'getFileReader'):auto_revert()

            local result, err = json.tryReadObject('unknown.json')

            assert.is_nil(result)
            assert.equal('could not open file unknown.json', err)
        end)

        it('returns an empty object for an empty file', function()
            zomboid.set_cache_file('empty.json', '')

            local result, err = json.tryReadObject('empty.json')

            assert.same({}, result)
            assert.is_nil(err)
        end)

        it('returns an error for non-JSON content', function()
            zomboid.set_cache_file('not.json', 'hello!')

            local result, err = json.tryReadObject('not.json')

            assert.is_nil(result)
            assert.is_string(err)
        end)

        it('returns an error for an invalid JSON type', function()
            zomboid.set_cache_file('string.json', '"hello, world!"')

            local result, err = json.tryReadObject('string.json')

            assert.is_nil(result)
            assert.equal('invalid file content', err)
        end)
    end)

    describe('tryDecode', function()
        it('calls tryDecode on a Decoder', function()
            local s = spy.on(json.Decoder, 'tryDecode')

            json.tryDecode('{}')

            assert.spy(s).called_with(match._, '{}')
        end)
    end)

    describe('tryEncode', function()
        it('calls tryEncode on an Encoder', function()
            local s = spy.on(json.Encoder, 'tryEncode')

            local tab = {}
            local options = {}
            json.tryEncode(tab, options)

            assert.spy(s).called_with(match._, match.ref(tab), match.ref(options))
        end)
    end)
end)
