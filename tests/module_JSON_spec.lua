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
