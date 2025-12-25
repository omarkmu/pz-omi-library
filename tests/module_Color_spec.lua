---Contains tests for the core utility module.

local color = require 'OmiLibrary/Module/Color'

describe('#module color #function', function()
    describe('black', function()
        it('returns a color table of zeroes', function()
            assert.same({ r = 0, g = 0, b = 0 }, color.black())
        end)
    end)

    describe('clamp', function()
        it('clamps the values between the maximum and minimum', function()
            local expected = { r = 10, g = 50, b = 50 }
            assert.same(expected, color.clamp({ r = 0, g = 255, b = 50 }, 10, 50))
        end)
    end)

    describe('clampRGBA', function()
        it('clamps the values between the maximum and minimum', function()
            local expected = { r = 10, g = 50, b = 50, a = 25 }
            assert.same(expected, color.clampRGBA({ r = 0, g = 255, b = 50, a = 25 }, 10, 50))
        end)
    end)

    describe('copy', function()
        it('returns a copy of the color table', function()
            local value = { r = 50, g = 50, b = 50 }
            local copy = color.copy(value)

            assert.same(copy, value)
            assert.is_not_equal(copy, value)
        end)
    end)

    describe('copyRGBA', function()
        it('returns a copy of the color table', function()
            local value = { r = 50, g = 50, b = 50, a = 255 }
            local copy = color.copyRGBA(value)

            assert.same(copy, value)
            assert.is_not_equal(copy, value)
        end)
    end)

    describe('decimalToInteger', function()
        it('converts a decimal color table into an integer color table', function()
            local expected = { r = 255, g = 255, b = 255 }
            assert.same(expected, color.decimalToInteger({ r = 1.0, g = 1.0, b = 1.0 }))
        end)
    end)

    describe('default', function()
        it('returns a given color table', function()
            local value = { r = 50, g = 50, b = 50 }
            local result = color.default(value, 10, 10, 10)

            assert.equal(result, value)
        end)

        it('returns a color table with the given values when the input is nil', function()
            local result = color.default(nil, 10, 10, 10)
            assert.same({ r = 10, g = 10, b = 10 }, result)
        end)
    end)

    describe('defaultRGBA', function()
        it('returns a given color table', function()
            local value = { r = 50, g = 50, b = 50, a = 255 }
            local result = color.defaultRGBA(value, 10, 10, 10, 255)

            assert.equal(result, value)
        end)

        it('returns a color table with the given values when the input is nil', function()
            local result = color.defaultRGBA(nil, 10, 10, 10, 255)
            assert.same({ r = 10, g = 10, b = 10, a = 255 }, result)
        end)
    end)

    describe('fromString', function()
        theory('can convert from a hex string', function(args)
            assert.same(args.expected, color.fromString(args.value))
        end, {
            { value = '#000000', expected = { r = 0, g = 0, b = 0 } },
            { value = '#FFFFFF', expected = { r = 255, g = 255, b = 255 } },
            { value = '#8FF', expected = { r = 136, g = 255, b = 255 } },
        })

        theory('can convert from an RGB string', function(args)
            assert.same(args.expected, color.fromString(args.value))
        end, {
            { value = '0,0,0', expected = { r = 0, g = 0, b = 0 } },
            { value = '255, 255, 255', expected = { r = 255, g = 255, b = 255 } },
            { value = '#8FF', expected = { r = 136, g = 255, b = 255 } },
        })

        it('fails for values greater than the maximum value', function()
            local result, err = color.fromString('256,255,255')
            assert.is_nil(result)
            assert.equal(color.ReadError.ABOVE_MAX, err)

            result, err = color.fromString('50,60,50', { maxColorValue = 50 })
            assert.is_nil(result)
            assert.equal(color.ReadError.ABOVE_MAX, err)
        end)

        it('fails for values less than the minimum value', function()
            local result, err = color.fromString('0,10,10', { minColorValue = 10 })
            assert.is_nil(result)
            assert.equal(color.ReadError.BELOW_MIN, err)
        end)

        it('fails for an empty string', function()
            local result, err = color.fromString('')
            assert.is_nil(result)
            assert.equal(color.ReadError.EMPTY, err)
        end)

        it('fails for an invalid format', function()
            local result, err = color.fromString('red=50,blue=255,green=10')
            assert.is_nil(result)
            assert.equal(color.ReadError.INVALID_FORMAT, err)
        end)

        it('uses a validate function if given', function()
            local _validate = spy.new(function() return 'invalid test color' end)
            local result, err = color.fromString('50,50,50', { validate = _validate --[[@as function]] })
            assert.is_nil(result)
            assert.equal('invalid test color', err)
        end)
    end)

    describe('integerToDecimal', function()
        it('converts an integer color table into a decimal color table', function()
            local expected = { r = 1.0, g = 1.0, b = 1.0 }
            assert.same(expected, color.integerToDecimal({ r = 255, g = 255, b = 255 }))
        end)
    end)

    describe('isValid', function()
        it('returns false for a non-table value', function()
            assert.is_false(color.isValid(('color')))
        end)

        theory('returns false if color values are not numbers', function(value)
            assert.is_false(color.isValid(value))
        end, {
            {},
            { r = 255 },
            { r = '1', g = 2, b = 3 },
            { r = 1, g = '2', b = 3 },
            { r = 1, g = 2, b = '3' },
        })

        theory('returns false if color values are not in [0, 255]', function(value)
            assert.is_false(color.isValid(value))
        end, {
            { r = -1, g = 50, b = 50 },
            { r = 50, g = -1, b = 50 },
            { r = 50, g = 50, b = -1 },
            { r = 256, g = 50, b = 50 },
            { r = 50, g = 256, b = 50 },
            { r = 50, g = 50, b = 256 },
        })

        theory('returns true for valid colors', function(value)
            assert.is_true(color.isValid(value))
        end, {
            { r = 0, g = 0, b = 0 },
            { r = 50, g = 50, b = 50 },
            { r = 255, g = 255, b = 255 },
        })
    end)

    describe('toHexString', function()
        theory('converts a color to a hexidecimal string', function(args)
            assert.equal(args.expected, color.toHexString(args.color --[[@as any]]))
        end, {
            { expected = '000000', color = { r = 0, g = 0, b = 0 } },
            { expected = '303030', color = { r = 48, g = 48, b = 48 } },
            { expected = 'ffffff', color = { r = 255, g = 255, b = 255 } },
            { expected = '30ff00', color = { r = 48, g = 255, b = 0 } },
        })
    end)

    describe('toRGBString', function()
        theory('converts a color to an RGB string', function(args)
            assert.equal(args.expected, color.toRGBString(args.color --[[@as any]], args.delimiter))
        end, {
            { expected = '0,0,0', color = { r = 0, g = 0, b = 0 } },
            { expected = '0 0 0', color = { r = 0, g = 0, b = 0 }, delimiter = ' ' },
            { expected = '255,255,255', color = { r = 255, g = 255, b = 255 } },
            { expected = '48,32,255', color = { r = 48, g = 32, b = 255 } },
        })
    end)

    describe('toRichText', function()
        theory('converts a color to a rich text RGB tag', function(args)
            assert.equal(args.expected, color.toRichText(args.color, args.push))
        end, {
            { expected = ' <RGB:0.0,0.0,0.0> ', color = { r = 0, g = 0, b = 0 } },
            { expected = ' <RGB:1.0,1.0,1.0> ', color = { r = 255, g = 255, b = 255 } },
            { expected = ' <PUSHRGB:0.0,0.0,0.0> ', color = { r = 0, g = 0, b = 0 }, push = true },
        })

        it('returns the empty string for an invalid color', function()
            assert.equal('', color.toRichText({ r = -10, g = -10, b = -10 }))
        end)
    end)

    describe('white', function()
        it('returns a color table with 255 for each component', function()
            assert.same({ r = 255, g = 255, b = 255 }, color.white())
        end)
    end)
end)
