---Contains tests for the RollResult component.
---@using omi
---@using omi.dice
---@diagnostic disable: access-invisible

local dice = require 'OmiLibrary/Module/Dice'

local Literal = dice.Literal
local Dice = dice.Dice
local RollExpression = dice.RollExpression
local Roller = dice.Roller
local RollResult = dice.RollResult
local CritType = dice.CritType
local SimpleStringifier = dice.SimpleStringifier

describe('#component RollExpression', function()
    local literal ---@type Literal
    local rollExpr ---@type RollExpression
    local instance ---@type RollResult
    local stringifier ---@type Stringifier
    local roller ---@type DiceRoller

    before_each(function()
        literal = Literal:new({ value = 20 })
        rollExpr = RollExpression:new({ roll = literal })
        roller = Roller:new()

        stringifier = SimpleStringifier:new({
            includeTotal = false,
            doStrikethrough = true,
        })

        instance = RollResult:new({
            expression = rollExpr,
            stringifier = stringifier,
        })
    end)

    ---@param count integer
    ---@param size integer
    ---@param value integer?
    ---@return RollResult
    local function diceRollResult(count, size, value)
        local expr = Dice:new({
            size = size,
            count = count,
            roller = roller,
        })

        expr:roll()
        if value then
            local die = expr.values[#expr.values] --[[@as Die]]
            die:forceValue(value)
        end

        local result = RollResult:new({
            stringifier = stringifier,
            expression = RollExpression:new({ roll = expr }),
        })

        return result
    end

    describe('#function', function()
        describe('fromNetwork', function()
            local function roundTrip()
                return RollResult.fromNetwork(instance:toNetwork(), roller, stringifier)
            end

            it('restores a result converted into a plain table', function()
                local restored = roundTrip()
                assert.same(instance, restored)
                assert.is_instance(restored, RollResult)
            end)

            it('attaches the given stringifier', function()
                local restored = roundTrip()
                assert.equal(stringifier, restored.stringifier)
            end)

            it('attaches the given roller to dice expressions', function()
                rollExpr.roll = Dice:new({ roller = roller, size = '%' })
                local restored = roundTrip()

                local expr = restored.expression.roll --[[@as Dice]]
                assert.is_instance(expr, Dice)
                assert.equal(roller, expr._roller)
            end)

            it('throws an error for an unknown expression type', function()
                ---@diagnostic disable-next-line: assign-type-mismatch
                rollExpr.type = 'Unknown'
                local expected = 'Invalid expression type: Unknown'
                assert.error(roundTrip, expected)
            end)

            it('throws an error for a nil expression type', function()
                ---@diagnostic disable-next-line: assign-type-mismatch
                rollExpr.type = nil
                local expected = 'Invalid expression type: nil'
                assert.error(roundTrip, expected)
            end)
        end)
    end)

    describe('#method', function()
        describe('getCrit', function()
            it('returns nil for a non-Dice expression', function()
                assert.is_nil(instance:getCrit())
            end)

            it('returns nil for a dice expression with a size other than 20', function()
                instance = diceRollResult(1, 6, 6)
                assert.is_nil(instance:getCrit())
            end)

            it('returns nil for a dice expression with multiple kept values', function()
                instance = diceRollResult(2, 20, 20)
                assert.is_nil(instance:getCrit())
            end)

            it('returns nil for a d20 with a value other than 1 or 20', function()
                for i = 2, 19 do
                    instance = diceRollResult(1, 20, i)
                    assert.is_nil(instance:getCrit())
                end
            end)

            it('returns CritType.Success for a natural 20', function()
                instance = diceRollResult(1, 20, 20)
                assert.equal(CritType.Success, instance:getCrit())
            end)

            it('returns CritType.Success for d20kh1', function()
                instance = diceRollResult(2, 20, 20)

                local roll = instance.expression.roll --[[@as Dice]]

                local die = roll.values[1] --[[@as Die]]
                die:drop()

                assert.equal(CritType.Success, instance:getCrit())
            end)

            it('returns CritType.Failure for a natural 1', function()
                instance = diceRollResult(1, 20, 1)
                assert.equal(CritType.Failure, instance:getCrit())
            end)
        end)

        describe('getTotal', function()
            it('returns the total of the roll', function()
                assert.equal(20, instance:getTotal())
            end)

            it('returns a cached total if called more than once', function()
                local _tryGetTotal = spy.on(instance, 'tryGetTotal')

                instance:getTotal()
                instance:getTotal()
                instance:getTotal()

                assert.spy(_tryGetTotal).called(1)
            end)

            it('throws an error if the roll causes an error', function()
                local expected = 'error message'
                local _tryGetTotal = stub(instance, 'tryGetTotal', nil, { message = expected })

                assert.error(function() instance:getTotal() end, expected)
            end)
        end)

        describe('getString', function()
            it('returns a string representation of the roll result', function()
                assert.equal('20', instance:getString())
            end)
        end)

        describe('toNetwork', function()
            it('converts to a plain table', function()
                assert.same({
                    expression = rollExpr:toNetwork(),
                }, instance:toNetwork())
            end)

            it('converts to a plain table with a pre-computed total', function()
                local total = instance:getTotal()
                assert.same({
                    total = total,
                    expression = rollExpr:toNetwork(),
                }, instance:toNetwork())
            end)
        end)

        describe('tryGetTotal', function()
            it('returns the total of the roll', function()
                local total, err = instance:tryGetTotal()
                assert.equal(20, total)
                assert.is_nil(err)
            end)

            it('returns a cached total if called more than once', function()
                local _getTotal = spy.on(instance.expression, 'getTotal')

                instance:tryGetTotal()
                instance:tryGetTotal()
                instance:tryGetTotal()

                assert.spy(_getTotal).called(1)
            end)

            it('returns an error if the roll causes an error', function()
                local expected = { message = 'error message' }
                local _getTotal = stub(instance.expression, 'getTotal', nil, expected)

                local total, err = instance:tryGetTotal()
                assert.is_nil(total)
                assert.not_nil(err)
                assert.equal(expected, err)
            end)
        end)
    end)

    describe('#operation', function()
        describe('__tostring', function()
            it('returns a string representation of the roll result', function()
                assert.equal('20', tostring(instance))
            end)
        end)
    end)
end)
