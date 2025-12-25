---Contains tests for the DiceParser component.
---@using omi
---@using omi.dice

local Parser = require 'OmiLibrary/Component/Dice/DiceParser'

describe('#component DiceParser #method', function()
    local parser ---@type DiceParser
    before_each(function() parser = Parser:new({ allowIdentifiers = true }) end)

    ---@generic T : AST.BaseNode
    ---@param text string
    ---@param expected? omi.dice.AST.`T`
    ---@return T
    local function parse(text, expected)
        local node, err = parser:parse(text)
        if err then
            error(err.message)
        end

        assert.is_not_nil(node) ---@cast node -?
        if expected then
            assert.equal(expected, node.type)
        end

        return node
    end

    ---@generic T : AST.BaseNode
    ---@param node? AST.BaseNode
    ---@param expected omi.dice.AST.`T`
    ---@return T
    ---@return_cast node T
    local function expect(node, expected)
        assert.is_not_nil(node) ---@cast node -?
        assert.equal(expected, node.type)

        return node
    end

    describe('parse', function()
        it('returns an error for an unexpected character', function()
            assert.error(function() parse('!') end, 'Unexpected character "!"')
        end)

        it('returns an error for empty input', function()
            assert.error(function() parse('') end, 'Missing input')
        end)

        describe('when parsing literals', function()
            theory('returns a literal for numbers', function(args)
                assert.equal(args.expected, parse(args.expr, 'Literal').value)
            end, {
                { expected = 1, expr = '1' },
                { expected = 100, expr = '100.' },
                { expected = 0.5, expr = '.5' },
                { expected = 0.5, expr = '000.5000' },
                { expected = 2.8, expr = '2.8' },
            })
        end)

        describe('when parsing dice expressions', function()
            it('returns a dice node for a dice expression with a value', function()
                local expr = parse('d20', 'Dice')
                assert.equal(20, expr.size)
                assert.is_nil(expr.count)
            end)

            it('returns a dice node for a dice expression with a value and a count', function()
                local expr = parse('5d20', 'Dice')
                assert.equal(5, expr.count)
                assert.equal(20, expr.size)
            end)

            it('returns a dice node for a percentile die', function()
                local expr = parse('d%', 'Dice')
                assert.equal('%', expr.size)
                assert.is_nil(expr.count)
            end)

            it('returns a dice node for a percentile die with a count', function()
                local expr = parse('10d%', 'Dice')
                assert.equal(10, expr.count)
                assert.equal('%', expr.size)
            end)

            it('returns an error when no value is given', function()
                assert.error(function() parse('d') end, 'Expected dice value')
            end)
        end)

        describe('when parsing dice operations', function()
            it('handles all operation types', function()
                local expr = parse('d20k>5p1rr7ro10ra<11e20mi5ma15', 'Dice')

                assert.same({
                    { type = 'k', selectors = { { type = '>', value = 5 } } },
                    { type = 'p', selectors = { { value = 1 } } },
                    { type = 'rr', selectors = { { value = 7 } } },
                    { type = 'ro', selectors = { { value = 10 } } },
                    { type = 'ra', selectors = { { type = '<', value = 11 } } },
                    { type = 'e', selectors = { { value = 20 } } },
                    { type = 'mi', selectors = { { value = 5 } } },
                    { type = 'ma', selectors = { { value = 15 } } },
                }, expr.operations)
            end)

            it('combines consecutive operations of the same type', function()
                local expr = parse('d6k1k2k3e3k5', 'Dice')

                assert.same({
                    {
                        type = 'k',
                        selectors = {
                            { value = 1 },
                            { value = 2 },
                            { value = 3 },
                        },
                    },
                    { type = 'e', selectors = { { value = 3 } } },
                    { type = 'k', selectors = { { value = 5 } } },
                }, expr.operations)
            end)

            it('does not combine minimum or maximum operations', function()
                local expr = parse('d6ma6ma5mi2mi3', 'Dice')

                assert.same({
                    { type = 'ma', selectors = { { value = 6 } } },
                    { type = 'ma', selectors = { { value = 5 } } },
                    { type = 'mi', selectors = { { value = 2 } } },
                    { type = 'mi', selectors = { { value = 3 } } },
                }, expr.operations)
            end)

            theory('returns an error for a selector with no value', function(value)
                assert.error(function() parse(value) end, 'Expected selector value')
            end, 'd6ma', '(d20,)kh')
        end)

        describe('when parsing identifier expressions', function()
            it('returns an identifier node for a basic identifier', function()
                local expr = parse('Deception', 'Identifier')

                assert.equal('Deception', expr.name)
            end)
        end)

        describe('when parsing parenthetical expressions', function()
            it('returns a parenthetical node when no trailing comma is included for one value', function()
                local expr = parse('(d100)', 'Parenthetical')

                expect(expr.value, 'Dice')
                assert.equal(100, expr.value.size)
            end)

            it('returns a set expression with one value when a trailing comma is included for one value', function()
                local expr = parse('(d100,)', 'Set')
                assert.equal(1, #expr.values)

                local dice = expect(expr.values[1], 'Dice')
                assert.equal(100, dice.size)
            end)

            it('returns an error when no expression is given', function()
                assert.error(function() parse('()') end, 'Unexpected character ")"')
                assert.error(function() parse('(,') end, 'Unexpected character ","')
            end)

            it('returns an error when the parenthesis is not closed', function()
                assert.error(function() parse('(') end, 'Expected end parenthesis')
            end)
        end)

        describe('when parsing annotations', function()
            it('adds to the rightmost node', function()
                local dice = parse('d20 [Roll]', 'Dice')
                assert.same({ '[Roll]' }, dice.annotations)

                local binOp = parse('d20 + 5 [Strength]', 'BinOp')
                expect(binOp.right, 'Literal')
                assert.same({ '[Strength]' }, binOp.right.annotations)

                binOp = parse('d6 [Attack] + 5', 'BinOp')
                expect(binOp.left, 'Dice')
                assert.same({ '[Attack]' }, binOp.left.annotations)

                local unOp = parse('-d20 [Negative]', 'UnOp')
                expect(unOp.value, 'Dice')
                assert.same({ '[Negative]' }, unOp.value.annotations)

                local parenthesized = parse('(d20 + 1) [Expression]', 'Parenthetical')
                assert.same({ '[Expression]' }, parenthesized.annotations)
            end)

            it('adds multiple annotations in order', function()
                local expr = parse('d20 [Attack] [with cool] [weapon]', 'Dice')
                assert.same({
                    '[Attack]',
                    '[with cool]',
                    '[weapon]',
                }, expr.annotations)
            end)
        end)

        describe('when parsing unary operations', function()
            it('returns a unary operation node for -X', function()
                local expr = parse('-1', 'UnOp')
                assert.equal('-', expr.op)

                expect(expr.value, 'Literal')
                assert.equal(1, expr.value.value)
            end)

            it('returns a unary operation node for +X', function()
                local expr = parse('+d6', 'UnOp')
                assert.equal('+', expr.op)

                expect(expr.value, 'Dice')
                assert.equal(6, expr.value.size)
            end)

            theory('returns an error if no value is given', function(value)
                assert.error(function() parse(value) end, 'Expected expression after ' .. value)
            end, '+', '-')

            it('returns an error if the value has an error', function()
                assert.error(function() parse('+d') end, 'Expected dice value')
            end)
        end)

        describe('when parsing binary operations', function()
            it('returns a binary operation node for addition', function()
                local expr = parse('d20 + 1', 'BinOp')
                assert.equal('+', expr.op)
                assert.equal(20, expr.left.size)
                assert.equal(1, expr.right.value)
            end)

            it('returns a binary operation node for subtraction', function()
                local expr = parse('d20 - 5', 'BinOp')
                assert.equal('-', expr.op)
                assert.equal(20, expr.left.size)
                assert.equal(5, expr.right.value)
            end)

            it('returns a binary operation node for modulo', function()
                local expr = parse('d20 % 2', 'BinOp')
                assert.equal('%', expr.op)
                assert.equal(20, expr.left.size)
                assert.equal(2, expr.right.value)
            end)

            it('returns a binary operation node for multiplication', function()
                local expr = parse('d5 * 4', 'BinOp')
                assert.equal('*', expr.op)
                assert.equal(5, expr.left.size)
                assert.equal(4, expr.right.value)
            end)

            it('returns a binary operation node for division', function()
                local expr = parse('d20 / 4', 'BinOp')
                assert.equal('/', expr.op)
                assert.equal(20, expr.left.size)
                assert.equal(4, expr.right.value)
            end)

            it('returns a binary operation node for floor division', function()
                local expr = parse('d20 // 4', 'BinOp')
                assert.equal('//', expr.op)
                assert.equal(20, expr.left.size)
                assert.equal(4, expr.right.value)
            end)

            it('returns a binary operation node for greater than', function()
                local expr = parse('d20 > 10', 'BinOp')
                assert.equal('>', expr.op)
                assert.equal(20, expr.left.size)
                assert.equal(10, expr.right.value)
            end)

            it('returns a binary operation node for less than', function()
                local expr = parse('d20 < 10', 'BinOp')
                assert.equal('<', expr.op)
                assert.equal(20, expr.left.size)
                assert.equal(10, expr.right.value)
            end)

            it('returns a binary operation node for greater than or equal to', function()
                local expr = parse('d20 >= 5', 'BinOp')
                assert.equal('>=', expr.op)
                assert.equal(20, expr.left.size)
                assert.equal(5, expr.right.value)
            end)

            it('returns a binary operation node for less than or equal to', function()
                local expr = parse('d20 <= 15', 'BinOp')
                assert.equal('<=', expr.op)
                assert.equal(20, expr.left.size)
                assert.equal(15, expr.right.value)
            end)

            it('returns a binary operation node for equals', function()
                local expr = parse('d20 == 20', 'BinOp')
                assert.equal('==', expr.op)
                assert.equal(20, expr.left.size)
                assert.equal(20, expr.right.value)
            end)

            it('returns a binary operation node for not equals', function()
                local expr = parse('d20 != 20', 'BinOp')
                assert.equal('!=', expr.op)
                assert.equal(20, expr.left.size)
                assert.equal(20, expr.right.value)
            end)

            it('returns a binary operation node for multiple comparisons', function()
                local expr = parse('1 != 1 == 0', 'BinOp')
                assert.equal('==', expr.op)

                local right = expect(expr.right, 'Literal')
                assert.equal(0, right.value)

                local left = expect(expr.left, 'BinOp')
                assert.equal('!=', left.op)
                assert.equal(1, expect(left.left, 'Literal').value)
                assert.equal(1, expect(left.right, 'Literal').value)
            end)

            it('returns a binary operation node for multiple operations', function()
                local expr = parse('1 + 2 - 3', 'BinOp')
                assert.equal('-', expr.op)

                local right = expect(expr.right, 'Literal')
                assert.equal(3, right.value)

                local left = expect(expr.left, 'BinOp')
                assert.equal('+', left.op)
                assert.equal(1, expect(left.left, 'Literal').value)
                assert.equal(2, expect(left.right, 'Literal').value)
            end)

            it('returns an error when the right expression is invalid', function()
                assert.error(function() parse('1 - d') end, 'Expected dice value')
            end)

            theory('returns an error when no right expression is given', function(value)
                assert.error(function() parse('1 ' .. value) end, 'Expected expression after ' .. value)
            end, '+', '-', '%', '*', '/', '//', '>', '>=', '<', '<=', '==', '!=')
        end)
    end)
end)
