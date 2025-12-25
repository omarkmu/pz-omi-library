---Contains tests for the DiceRoller component.
---@using omi
---@using omi.dice
---@diagnostic disable: access-invisible

local dice = require 'OmiLibrary/Module/Dice'
local Cache = require 'OmiLibrary/Component/Cache/Cache'

local Roller = dice.Roller
local RollError = dice.RollError
local Parser = dice.Parser
local ParseError = dice.ParseError
local RollResult = dice.RollResult
local SimpleStringifier = dice.SimpleStringifier
local AdvType = dice.AdvType

-- expected error messages
local ERR_MANY_ROLLS = RollError.Messages.TooManyRolls
local ERR_DIV_ZERO = RollError.Messages.DivideByZero
local ERR_ZERO_SIDES = RollError.Messages.ZeroSides
local ERR_SELECTOR_MAX = function(s)
    return string.format(RollError.FormattedMessages.InvalidSelectorMaximum, s)
end
local ERR_SELECTOR_MIN = function(s)
    return string.format(RollError.FormattedMessages.InvalidSelectorMinimum, s)
end

describe('#component DiceRoller #method', function()
    local roller ---@type DiceRoller
    before_each(function() roller = Roller:new({ parser = Parser:new({ allowIdentifiers = true }) }) end)

    ---@param err unknown?
    ---@param code DiceParseError.Code?
    ---@return_cast e DiceParseError
    local function expectParseError(err, code)
        assert.is_not_nil(err) ---@cast err -?
        assert.is_instance(err, ParseError) ---@cast err DiceParseError

        if code then
            assert.equal(code, err.code)
        end
    end

    ---@param err unknown?
    ---@param code DiceRollError.Code?
    ---@return_cast e DiceRollError
    local function expectRollError(err, code)
        assert.is_not_nil(err) ---@cast err -?
        assert.is_instance(err, RollError) ---@cast err DiceRollError

        if code then
            assert.equal(code, err.code)
        end
    end

    ---@param strikethrough boolean?
    ---@param total boolean?
    ---@return SimpleStringifier
    local function plain(strikethrough, total)
        return SimpleStringifier:new({
            includeTotal = total or false,
            doStrikethrough = strikethrough or false,
        })
    end

    ---@param roll string
    ---@param message string?
    local function assertError(roll, message)
        assert.error(function() roller:roll(roll):getTotal() end, message)
    end

    ---@param expr string
    ---@param expected integer?
    ---@return integer
    local function roll(expr, expected)
        local result = roller:roll(expr)
        local total = result:getTotal()

        if expected then
            assert.equal(expected, total)
        end

        return total
    end

    ---@param expr string
    ---@param expectedMatch string?
    ---@param args Args.Roll?
    ---@return string
    local function rollString(expr, expectedMatch, args)
        args = args or {} --[[@as Args.Roll]]
        if not args.stringifier then
            args.stringifier = plain()
        end

        local result = roller:roll(expr, args)
        local str = tostring(result)

        if expectedMatch then
            assert.match(expectedMatch, str)
        end

        return str
    end

    ---@param expr string
    ---@param min integer
    ---@param max integer
    ---@return integer
    local function rollBetween(expr, min, max)
        local total = roll(expr)

        assert.between(min, max, total)
        return total
    end

    ---@generic T : ResolvableNumber
    ---@param text string
    ---@param expected T
    ---@return RollResult & { expression: RollExpression & { roll: T } }
    local function expectRollType(text, expected)
        local result = roller:roll(text)
        assert.is_instance(result.expression.roll, expected)

        return result
    end

    describe('countRoll', function()
        it('adds to the roll counter', function()
            assert.equal(0, roller._rolls)
            assert.is_nil(roller:countRoll())
            assert.equal(1, roller._rolls)
        end)

        it('returns a DiceRollError if the roll exceeds the maximum', function()
            roller = Roller:new({ maxRolls = 1 })
            assert.is_nil(roller:countRoll())
            expectRollError(roller:countRoll(), 'TooManyRolls')
        end)
    end)

    describe('parse', function()
        it('calls parse on a DiceParser', function()
            local s = stub(Parser, 'parse', {}):auto_revert()

            roller:parse('d20')
            assert.spy(s).called(1)
            assert.spy(s).called_with(match._, 'd20')
        end)

        it('updates the cache with its result', function()
            local s = stub(Cache, 'set'):auto_revert()

            local result = roller:parse('d20')
            assert.spy(s).called(1)
            assert.spy(s).called_with(match._, 'd20', match.same {
                key = 'd20',
                expression = result,
            })
        end)

        it('uses a cached result if present', function()
            local expected = {}
            local s = stub(Cache, 'get', { expression = expected }):auto_revert()

            local result = roller:parse('d20')
            assert.spy(s).called(1)
            assert.spy(s).called_with(match._, 'd20')
            assert.equal(expected, result)
        end)

        it('removes spaces from the expression before parsing', function()
            local s = stub(Parser, 'parse', {}):auto_revert()

            roller:parse('d20 + 5')
            assert.spy(s).called(1)
            assert.spy(s).called_with(match._, 'd20+5')
        end)

        it('collapses spaces in annotations before parsing', function()
            local s = stub(Parser, 'parse', {}):auto_revert()

            roller:parse('d20 [annotation   with  spaces] + 5 [five]')
            assert.spy(s).called(1)
            assert.spy(s).called_with(match._, 'd20[annotation with spaces]+5[five]')
        end)

        it('throws an error on failure', function()
            assert.error(function() roller:parse('d') end, 'Expected dice value')
        end)
    end)

    describe('roll', function()
        it('accepts a pre-parsed expression', function()
            local result = roller:roll(roller:parse('d20'))

            assert.is_instance(result, RollResult)
            assert.is_instance(result.expression, dice.RollExpression)
            assert.is_instance(result.expression.roll, dice.Dice)
        end)

        describe('returns a result containing', function()
            theory('a Literal expression for literal numbers', function(value)
                expectRollType(value, dice.Literal)
            end, '0', '100', '.5', '0.', '2.3')

            theory('a Dice expression for basic dice rolls', function(value)
                expectRollType(value, dice.Dice)
            end, 'd20', '4d6', '20d12', '2d%')

            theory('an Identifier expression for identifiers', function(value)
                expectRollType(value, dice.Identifier)
            end, 'strength', 'deception', 'Perception', 'Wisdom', 'Animal_Handling')

            theory('a Parenthetical expression for expressions in parentheses', function(value)
                expectRollType(value, dice.Parenthetical)
            end, '(1)', '(1 + 1)', '(d20)', '(d6 - 4)')

            theory('a DiceSet expression for expressions in parentheses separated by commas', function(value)
                expectRollType(value, dice.Set)
            end, '(1,)', '(d20,)', '(1,2,d4)', '(1 + 1, d10)', '(d20, d6, d4)', '(d6 - 4, d%)')

            theory('a UnaryOp expression for unary operations', function(value)
                expectRollType(value, dice.UnaryOp)
            end, '-42', '-8.2', '-d20', '+5', '+d10', '-(d5 - 5)')

            theory('a BinaryOp expression for a binary operation', function(value)
                expectRollType(value, dice.BinaryOp)
            end, '1 + 1', 'd20 + 5', '40 * d5', 'd2 == 1', '-d10 == 5')
        end)

        describe('when called with the advantage option', function()
            describe('unset', function()
                it('does not apply advantage', function()
                    rollString('d20', '^d20 %(%d+%)$')
                end)
            end)

            describe('set to an invalid value', function()
                it('does not apply advantage', function()
                    rollString('d20', '^d20 %(%d+%)$', { advantage = 0 })
                end)
            end)

            for i = 1, 2 do
                local isAdv = i == 1
                local name = isAdv and 'advantage' or 'disadvantage'
                local advDice = isAdv and '2d20kh1' or '2d20kl1'
                local advType = isAdv and AdvType.Advantage or AdvType.Disadvantage

                describe('set to AdvType.' .. (isAdv and 'Advantage' or 'Disadvantage'), function()
                    local options ---@type Args.Roll
                    before_each(function()
                        options = { advantage = advType }
                    end)

                    describe('applies ' .. name, function()
                        it('to basic dice rolls', function()
                            rollString('d20', '^' .. advDice .. ' %(%d+, %d+%)$', options)
                        end)

                        it('to dice sets starting with d20', function()
                            rollString('(1d20, d6)', '^%(' .. advDice .. ' %(%d+, %d+%), d6 %(%d+%)%)$', options)
                        end)

                        it('to binary operations starting with d20', function()
                            rollString('d20 + 5', '^' .. advDice .. ' %(%d+, %d+%) %+ 5$', options)
                        end)

                        it('to parentheticals starting with d20', function()
                            rollString('(d20 / 2)', '^%(' .. advDice .. ' %(%d+, %d+%) / 2%)$', options)
                        end)
                    end)

                    describe('does not apply ' .. name, function()
                        it('if the leftmost node is not a dice expression', function()
                            rollString('1 - d20', '^1 %- d20 %(%d+%)$', options)
                        end)

                        it('if the leftmost node is not a d20', function()
                            rollString('d4', '^d4 %(%d+%)$', options)
                        end)

                        it('if the leftmost node is a d20 with a count other than 1', function()
                            rollString('3d20', '^3d20 %(%d+, %d+, %d+%)$', options)
                        end)
                    end)
                end)
            end
        end)

        describe('when evaluating', function()
            describe('the total of', function()
                describe('a dice expression', function()
                    it('returns values in the dice range', function()
                        for _ = 1, 50 do
                            roll('d1', 1)
                            rollBetween('d20', 1, 20)
                            rollBetween('4d6kh3', 3, 18)
                            rollBetween('(((((1d6)))))', 1, 6)
                            rollBetween('(d4, 4, 3d6kl1)kh1', 4, 6)
                            rollBetween('d%', 0, 90)

                            assert.equal(0, roll('d%') % 10)
                            assert.between(0, 9, math.floor(roll('d%') / 10))
                        end
                    end)
                end)

                describe('a parenthetical expression', function()
                    it('returns the expected value', function()
                        roll('(5)', 5)
                        roll('(-1)', -1)
                        roll('(1 + 2) * 2', 6)
                        roll('(6)p6', 0)
                        rollBetween('(d6 + 1) * 2', 4, 14)
                    end)

                    it('throws an error caused by an operation', function()
                        stub(Roller, '_evalSetOperations', { message = 'forced error' }):auto_revert()
                        assertError('(d6)kh1', 'forced error')
                    end)

                    it('throws an error caused by its inner expression', function()
                        assertError('(d0)', ERR_ZERO_SIDES)
                        assertError('(1 / 0)', ERR_DIV_ZERO)
                    end)
                end)

                describe('a set expression', function()
                    it('returns the expected value', function()
                        roll('(2, 2)', 4)
                        roll('(-1, 1)', 0)
                        roll('(1, 1, 1, 1) * 2', 8)
                        roll('(2, 3, 4)kh1', 4)
                        rollBetween('(d6, 2)', 3, 8)
                    end)

                    it('throws an error caused by an operation', function()
                        stub(Roller, '_evalSetOperations', { message = 'forced error' }):auto_revert()
                        assertError('(d6, 2)kh1', 'forced error')
                    end)

                    it('throws an error caused by an inner expression', function()
                        assertError('(1, d0)', ERR_ZERO_SIDES)
                        assertError('(d4, 1 / 0)', ERR_DIV_ZERO)
                    end)
                end)

                describe('a unary operation', function()
                    it('returns the expected value', function()
                        roll('-1', -1)
                        roll('+1', 1)
                        roll('+(-5)', -5)
                        rollBetween('+d6', 1, 6)
                        rollBetween('-d6', -6, -1)
                    end)

                    it('throws an error caused by its value', function()
                        assertError('+d0', ERR_ZERO_SIDES)
                        assertError('-(1 / 0)', ERR_DIV_ZERO)
                    end)
                end)

                describe('a binary operation', function()
                    theory('returns the expected value', function(args)
                        roll(args.expr, args.value)
                    end, {
                        { expr = '1 + 1', value = 2 },
                        { expr = '3 / 2', value = 1 },
                        { expr = '1 / 2 + 0.5', value = 1 },
                        { expr = '1 // 2 + 0.5', value = 0 },
                        { expr = '1 == 2', value = 0 },
                        { expr = '1 != 2', value = 1 },
                        { expr = 'd2 > 5', value = 0 },
                        { expr = 'd2 < 5', value = 1 },
                        { expr = 'd4 >= 1', value = 1 },
                        { expr = 'd4 <= 4', value = 1 },
                        { expr = 'd4ma2 < 3', value = 1 },
                        { expr = 'd4ma2 > 2', value = 0 },
                        { expr = 'd4mi2 > 1', value = 1 },
                    })

                    theory('returns a value in the expected range', function(args)
                        rollBetween(args.expr, args.min, args.max)
                    end, {
                        { expr = 'd2 * 4', min = 4, max = 8 },
                        { expr = 'd10 + 3', min = 4, max = 13 },
                        { expr = 'd10 % 2', min = 0, max = 1 },
                    })

                    theory('respects the order of operations', function(args)
                        roll(args.expr, args.value)
                    end, {
                        { expr = '-2 - 3', value = -5 },
                        { expr = '-(2 - 3)', value = 1 },
                        { expr = '(1 + 3) * 6', value = 24 },
                        { expr = '1 + 2 == 2', value = 0 },
                        { expr = '1 + (2 == 2)', value = 2 },
                        { expr = '1 + 3 * 6', value = 19 },
                        { expr = '1 + (3 * 6)', value = 19 },
                        { expr = '1 + 2 + 3', value = 6 },
                        { expr = '(1 + 2) + 3', value = 6 },
                        { expr = '1 + (2 + 3)', value = 6 },
                    })

                    it('throws an error caused by its left value', function()
                        assertError('d0 + 1', ERR_ZERO_SIDES)
                        assertError('(d2 / 0) % 3', ERR_DIV_ZERO)
                    end)

                    it('throws an error caused by its right value', function()
                        assertError('1 - d0', ERR_ZERO_SIDES)
                    end)
                end)
            end)

            describe('the k operator', function()
                it('drops non-matching values', function()
                    roll('(1, 7, 3)k>3', 7)
                    roll('(2, 4, 10)kh1', 10)
                    roll('(2, 4, 10)kl2', 6)
                    for _ = 1, 50 do
                        rollBetween('d6k<4', 0, 3)
                        rollBetween('(-5, d6, 8)kh2', 7, 14)
                        rollBetween('(-5, d6, 8)kl2', -4, 1)
                    end
                end)
            end)

            describe('the p operator', function()
                it('drops matching values', function()
                    roll('(1, 4, 3, 4)p<4', 8)
                    roll('(2, 4, 10)pl2', 10)
                    roll('(2, 4, 10)ph1', 6)
                    for _ = 1, 50 do
                        rollBetween('d6p>3', 0, 3)
                        rollBetween('(9, d6, 8)ph2', 1, 6)
                    end
                end)
            end)

            describe('the rr operator', function()
                it('rerolls matching values', function()
                    for _ = 1, 50 do
                        assert.is_not_equal(1, roll('d6rr1'))
                    end
                end)

                it('throws an error for infinite rerolls', function()
                    assertError('d4rr<7', ERR_MANY_ROLLS)
                end)
            end)

            describe('the ro operator', function()
                it('rerolls matching values once', function()
                    local options = { stringifier = plain(true) }
                    for _ = 1, 50 do
                        rollString('d6ro>0', '^d6ro>0 %(~~%d+~~, %d+%)$', options)
                    end
                end)

                it('throws an error when exceeding the maximum rolls', function()
                    roller = Roller:new({ maxRolls = 1 })
                    assertError('d20ro>0', ERR_MANY_ROLLS)
                end)
            end)

            describe('the ra operator', function()
                it('explodes matching values once', function()
                    local options = { stringifier = plain(true) }
                    for _ = 1, 50 do
                        rollString('d20ra>0', '^d20ra>0 %(%d+!, %d+%)$', options)
                    end
                end)

                it('only operates on the first die in a dice set', function()
                    local options = { stringifier = plain(true) }
                    for _ = 1, 50 do
                        rollString('2d20ra>0', '^2d20ra>0 %(%d+!, %d+, %d+%)$', options)
                    end
                end)

                it('throws an error when exceeding the maximum rolls', function()
                    roller = Roller:new({ maxRolls = 1 })
                    assertError('d20ra>0', ERR_MANY_ROLLS)
                end)
            end)

            describe('the e operator', function()
                it('explodes matching values', function()
                    local options = { stringifier = plain(true) }
                    for _ = 1, 50 do
                        local result = roller:roll('d20e>1', options)
                        if result:getTotal() > 1 then
                            assert.match('^d20e>1 %(%d+!, %d+.*%)$', tostring(result))
                        else
                            assert.match('^d20e>1 %(1%)$', tostring(result))
                        end
                    end
                end)

                it('throws an error for infinite explosions', function()
                    assertError('d4e>0', ERR_MANY_ROLLS)
                end)
            end)

            describe('the mi operator', function()
                it('forces values to a minimum', function()
                    rollString('d1mi2', '^d1mi2 %(1 %-> 2%)$')
                    for _ = 1, 50 do
                        assert.is_true(roll('d20mi5') >= 5)
                    end
                end)

                it('throws an error when using a selector other than literal', function()
                    assertError('d20mil2', ERR_SELECTOR_MIN('l'))
                end)
            end)

            describe('the ma operator', function()
                it('forces values to a maximum', function()
                    for _ = 1, 50 do
                        assert.is_true(roll('d20ma15') <= 15)
                    end
                end)

                it('throws an error when using a selector other than literal', function()
                    assertError('d20ma>2', ERR_SELECTOR_MAX('>'))
                end)
            end)
        end)

        describe('throws an error', function()
            it('when attempting to roll a 0-sided die', function()
                assertError('d0', ERR_ZERO_SIDES)
                assertError('10d0', ERR_ZERO_SIDES)
            end)

            it('when the number of rolls exceeds the maximum', function()
                assertError('100000000d20', ERR_MANY_ROLLS)
            end)

            it('when attempting to divide by zero', function()
                assertError('1 % 0', ERR_DIV_ZERO)
                assertError('1 / 0', ERR_DIV_ZERO)
                assertError('1 // 0', ERR_DIV_ZERO)
            end)
        end)
    end)

    describe('tryParse', function()
        it('returns an AST on success', function()
            local result, err = roller:tryParse('d20')
            assert.is_nil(err)
            assert.is_not_nil(result) ---@cast result -?
            assert.equal('Dice', result.type)
        end)

        it('returns nil and an error on failure', function()
            local result, err = roller:tryParse('d')
            assert.is_nil(result)
            expectParseError(err, 'MissingDiceValue')
        end)
    end)

    describe('tryRoll', function()
        it('returns a RollResult on success', function()
            local result, err = roller:tryRoll('d20')
            assert.is_nil(err)
            assert.is_not_nil(result) ---@cast result -?
            assert.is_instance(result, RollResult)
            assert.is_instance(result.expression, dice.RollExpression)
            assert.is_instance(result.expression.roll, dice.Dice)
        end)

        it('returns nil and an error for a failed parse', function()
            local result, err = roller:tryRoll('d')
            assert.is_nil(result)
            expectParseError(err, 'MissingDiceValue')
        end)

        it('returns nil and an error for a failed roll', function()
            local result, err = roller:tryRoll('1000d20')
            assert.is_nil(result)
            expectRollError(err, 'TooManyRolls')
        end)
    end)
end)
