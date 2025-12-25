---Contains tests for dice expression components.
---@using omi
---@using omi.dice
---@diagnostic disable: access-invisible

local dice = require 'OmiLibrary/Module/Dice'

local Literal = dice.Literal
local Die = dice.Die
local Dice = dice.Dice
local BinaryOp = dice.BinaryOp
local UnaryOp = dice.UnaryOp
local DiceSet = dice.Set
local Parenthetical = dice.Parenthetical
local ResolvableNumber = dice.ResolvableNumber
local RollExpression = dice.RollExpression
local Roller = dice.Roller
local RollError = dice.RollError

describe('#component', function()
    describe('ResolvableNumber', function()
        local instance ---@type ResolvableNumber
        before_each(function()
            instance = ResolvableNumber:new()
        end)

        ---@param f function
        local function testThrowsNotImplemented(f)
            it('throws a not implemented error', function()
                assert.error(f, 'not implemented')
            end)
        end

        describe('#function', function()
            describe('_listToString', function()
                it('converts elements to strings', function()
                    local list = {
                        setmetatable({}, {
                            __tostring = function() return 'hello' end,
                        }),
                        'world',
                    }

                    assert.equal('[hello, "world"]', ResolvableNumber._listToString(list))
                end)
            end)

            describe('_operationsToString', function()
                it('converts simple operations', function()
                    ---@type Operation<string>[]
                    local list = {
                        {
                            type = 'p',
                            selectors = {
                                {
                                    type = 'l',
                                    value = 1,
                                },
                            },
                        },
                        {
                            type = 'mi',
                            selectors = {
                                {
                                    value = 5,
                                },
                            },
                        },
                    }

                    assert.equal('[pl1, mi5]', ResolvableNumber._operationsToString(list))
                end)

                it('converts operations with multiple selectors', function()
                    ---@type Operation<string>[]
                    local list = {
                        {
                            type = 'k',
                            selectors = {
                                {
                                    value = 1,
                                },
                                {
                                    value = 2,
                                },
                                {
                                    value = 3,
                                },
                            },
                        },
                    }

                    assert.equal('[k1, k2, k3]', ResolvableNumber._operationsToString(list))
                end)
            end)
        end)

        describe('#method', function()
            describe('drop', function()
                it('updates the value of the kept field', function()
                    assert.is_true(instance.kept)
                    instance:drop()
                    assert.is_false(instance.kept)
                end)
            end)

            describe('getChildren', function()
                it('returns an empty list', function()
                    assert.same({}, instance:getChildren())
                end)
            end)

            describe('getList', function()
                testThrowsNotImplemented(function() instance:getList() end)
            end)

            describe('getKeptList', function()
                it('returns a list of only kept expressions', function()
                    local kept = Literal:new({ value = 1 })
                    local dropped = Literal:new({ value = 20 })

                    dropped:drop()
                    stub(instance, 'getList', { dropped, kept })

                    assert.same({ kept }, instance:getKeptList())
                end)
            end)

            describe('getTotal', function()
                it('returns 0 if the expression is not kept', function()
                    instance:drop()
                    local total = instance:getTotal()
                    assert.equal(0, total)
                end)

                testThrowsNotImplemented(function() instance:getTotal() end)
            end)

            describe('getLeft', function()
                it('returns nil', function()
                    assert.is_nil(instance:getLeft())
                end)
            end)

            describe('getRight', function()
                it('returns nil', function()
                    assert.is_nil(instance:getRight())
                end)
            end)

            describe('toNetwork', function()
                it('converts to a plain table', function()
                    instance.annotation = '[Annotation]'
                    assert.same({
                        kept = true,
                        annotation = '[Annotation]',
                    }, instance:toNetwork())
                end)
            end)
        end)

        describe('#operation', function()
            describe('__tostring', function()
                testThrowsNotImplemented(function() tostring(instance) end)
            end)
        end)
    end)

    describe('RollExpression', function()
        local innerExpr ---@type Literal
        local instance ---@type RollExpression
        before_each(function()
            innerExpr = Literal:new({ value = 20 })
            instance = RollExpression:new({ roll = innerExpr })
        end)

        describe('#method', function()
            describe('getChildren', function()
                it('returns a list containing only the inner expression', function()
                    assert.same({ innerExpr }, instance:getChildren())
                end)
            end)

            describe('getList', function()
                it('returns a list containing only the inner expression', function()
                    assert.same({ innerExpr }, instance:getList())
                end)
            end)

            describe('toNetwork', function()
                it('converts to a plain table', function()
                    assert.same({
                        type = 'RollExpression',
                        kept = true,
                        annotation = '',
                        roll = innerExpr:toNetwork(),
                    }, instance:toNetwork())
                end)
            end)
        end)

        describe('#operation', function()
            describe('__tostring', function()
                it('returns a representation string for an instance', function()
                    assert.equal('<RollExpression roll=<Literal 20>>', tostring(instance))
                end)
            end)
        end)
    end)

    describe('Literal', function()
        local VALUE = 10
        local instance ---@type Literal
        before_each(function()
            instance = Literal:new({ value = VALUE })
        end)

        describe('#method', function()
            describe('explode', function()
                it('updates the value of the exploded field', function()
                    assert.is_false(instance.exploded)
                    instance:explode()
                    assert.is_true(instance.exploded)
                end)
            end)

            describe('getList', function()
                it('returns a list containing itself', function()
                    assert.same({ instance }, instance:getList())
                end)
            end)

            describe('getNumber', function()
                it('returns the literal value', function()
                    assert.equal(VALUE, instance:getNumber())
                end)
            end)

            describe('toNetwork', function()
                it('converts to a plain table', function()
                    assert.same({
                        type = 'Literal',
                        kept = true,
                        exploded = false,
                        annotation = '',
                        values = { VALUE },
                    }, instance:toNetwork())
                end)
            end)

            describe('update', function()
                it('updates the literal value', function()
                    assert.equal(VALUE, instance:getNumber())
                    instance:update(1)
                    assert.equal(1, instance:getNumber())
                end)
            end)
        end)

        describe('#operation', function()
            describe('__tostring', function()
                it('returns a representation string for an instance', function()
                    assert.equal('<Literal 10>', tostring(instance))
                end)

                it('returns a representation string for an instance with a fractional value', function()
                    assert.equal('<Literal 2.5>', tostring(Literal:new({ value = 2.5 })))
                end)
            end)
        end)
    end)

    describe('Die', function()
        local literal ---@type Literal
        local instance ---@type Die
        local SIZE = 20
        local TOTAL = 1
        before_each(function()
            literal = Literal:new({ value = TOTAL })
            instance = Die:new({
                size = SIZE,
                roller = Roller:new(),
                values = { literal },
            })
        end)

        describe('#function', function()
            describe('roll', function()
                it('returns a Die', function()
                    local die = Die.roll(SIZE, Roller:new())

                    assert.not_nil(die) ---@cast die -?
                    assert.is_instance(die, Die)
                    assert.equal(SIZE, die.size)
                end)

                it('returns nil and an error for an invalid roll', function()
                    local die, err = Die.roll(0, Roller:new())

                    assert.is_nil(die)
                    assert.not_nil(err) ---@cast err -?
                    assert.is_instance(err, RollError)
                end)
            end)
        end)

        describe('#method', function()
            describe('explode', function()
                it('calls explode on the literal', function()
                    local _explode = stub(literal, 'explode')

                    instance:explode()
                    assert.stub(_explode).called(1)
                end)
            end)

            describe('forceValue', function()
                it('calls update on the literal', function()
                    local _update = stub(literal, 'update')

                    instance:forceValue(10)
                    assert.stub(_update).called(1)
                    assert.stub(_update).called_with(literal, 10)
                end)
            end)

            describe('getChildren', function()
                it('returns a list containing only the literal', function()
                    assert.same({ literal }, instance:getChildren())
                end)
            end)

            describe('getList', function()
                it('returns a list containing only the literal', function()
                    assert.same({ literal }, instance:getList())
                end)
            end)

            describe('getNumber', function()
                it('calls getTotal on the literal', function()
                    local _getTotal = stub(literal, 'getTotal')

                    instance:getTotal()
                    assert.stub(_getTotal).called(1)
                end)

                it('returns the total from the literal', function()
                    local total = instance:getTotal()
                    assert.equal(TOTAL, total)
                end)
            end)

            describe('reroll', function()
                it('calls drop on the literal', function()
                    local _drop = stub(literal, 'drop')
                    stub(instance, '_addRoll')

                    instance:reroll()
                    assert.stub(_drop).called(1)
                end)

                it('calls _addRoll', function()
                    local _addRoll = stub(instance, '_addRoll')
                    stub(literal, 'drop')

                    instance:reroll()
                    assert.stub(_addRoll).called(1)
                end)
            end)

            describe('toNetwork', function()
                it('converts to a plain table', function()
                    assert.same({
                        type = 'Die',
                        kept = true,
                        annotation = '',
                        size = SIZE,
                        values = { literal:toNetwork() },
                    }, instance:toNetwork())
                end)
            end)
        end)

        describe('#operation', function()
            describe('__tostring', function()
                it('returns a representation string for an instance', function()
                    assert.equal('<Die size=20 values=[<Literal 1>]>', tostring(instance))
                end)
            end)
        end)
    end)

    describe('Dice', function()
        local roller = Roller:new()
        local instance ---@type Dice
        local _Die_roll ---@type luassert.stub

        local SIZE = 20
        before_each(function()
            instance = Dice:new({
                size = SIZE,
                roller = roller,
                operations = {},
            })

            _Die_roll = stub(Die, 'roll', function(_size, _roller)
                return Die:new({
                    size = _size,
                    roller = _roller,
                    values = { Literal:new({ value = _size }) },
                })
            end):auto_revert()
        end)

        describe('#method', function()
            describe('getChildren', function()
                it('returns an empty list', function()
                    assert.same({}, instance:getChildren())
                end)
            end)

            describe('roll', function()
                it('calls Die.roll for each die', function()
                    instance.count = 5
                    instance:roll()
                    assert.stub(_Die_roll).called(5)
                    assert.equal(5, #instance.values)
                end)

                it('returns an error returned by Die.roll', function()
                    local rollErr = RollError:new('ZeroSides')
                    _Die_roll.returns(nil, rollErr)

                    local err = instance:roll()
                    assert.not_nil(err)
                    assert.equal(rollErr, err)
                end)
            end)

            describe('rollAnother', function()
                it('calls Die.roll once', function()
                    instance.count = 5
                    instance:rollAnother()
                    assert.stub(_Die_roll).called(1)
                    assert.equal(1, #instance.values)
                end)

                it('returns the error returned by Die.roll', function()
                    local rollErr = RollError:new('ZeroSides')
                    _Die_roll.returns(nil, rollErr)

                    local err = instance:rollAnother()
                    assert.not_nil(err)
                    assert.equal(rollErr, err)
                end)
            end)

            describe('toNetwork', function()
                it('converts to a plain table', function()
                    assert.same({
                        type = 'Dice',
                        kept = true,
                        annotation = '',
                        count = 1,
                        size = SIZE,
                        operations = {},
                        values = {},
                    }, instance:toNetwork())
                end)
            end)
        end)

        describe('#operation', function()
            describe('__tostring', function()
                it('returns a representation string for an instance', function()
                    assert.equal('<Dice count=1 size=20 values=[] operations=[]>', tostring(instance))
                end)

                it('returns a representation string for an instance with a result roll', function()
                    local expected = '<Dice count=1 size=20 values=[<Die size=20 values=[<Literal 20>]>] operations=[]>'

                    instance:roll()
                    assert.equal(expected, tostring(instance))
                end)
            end)
        end)
    end)

    describe('DiceSet', function()
        local literal1 ---@type Literal
        local literal2 ---@type Literal
        local instance ---@type DiceSet
        before_each(function()
            literal1 = Literal:new({ value = 4 })
            literal2 = Literal:new({ value = 7 })
            instance = DiceSet:new({ values = { literal1, literal2 } })
        end)

        describe('#method', function()
            describe('getChildren', function()
                it('returns the value list', function()
                    assert.same({ literal1, literal2 }, instance:getChildren())
                end)
            end)

            describe('getList', function()
                it('returns the value list', function()
                    assert.same({ literal1, literal2 }, instance:getList())
                end)
            end)

            describe('toNetwork', function()
                it('converts to a plain table', function()
                    assert.same({
                        type = 'DiceSet',
                        kept = true,
                        annotation = '',
                        values = {
                            literal1:toNetwork(),
                            literal2:toNetwork(),
                        },
                        operations = {},
                    }, instance:toNetwork())
                end)
            end)
        end)

        describe('#operation', function()
            describe('__tostring', function()
                it('returns a representation string for an instance', function()
                    instance.values = {}
                    assert.equal('<DiceSet values=[] operations=[]>', tostring(instance))
                end)

                it('returns a representation string for an instance with values', function()
                    local expected = '<DiceSet values=[<Literal 4>, <Literal 7>] operations=[]>'
                    assert.equal(expected, tostring(instance))
                end)
            end)
        end)
    end)

    describe('Parenthetical', function()
        local instance ---@type Parenthetical
        local literal ---@type Literal
        before_each(function()
            literal = Literal:new({ value = 16 })
            instance = Parenthetical:new({ value = literal, operations = {} })
        end)

        describe('#method', function()
            describe('getChildren', function()
                it('returns a list containing only the inner expression', function()
                    assert.same({ literal }, instance:getChildren())
                end)
            end)

            describe('getList', function()
                it('returns the list for its value', function()
                    local expected = {}
                    stub(literal, 'getList', expected)
                    assert.equal(expected, instance:getList())
                end)
            end)

            describe('getTotal', function()
                it('returns the total for the literal', function()
                    local total = instance:getTotal()
                    assert.equal(16, total)
                end)

                it('returns zero if the parenthetical is not kept', function()
                    instance:drop()
                    local total = instance:getTotal()
                    assert.equal(0, total)
                end)
            end)

            describe('toNetwork', function()
                it('converts to a plain table', function()
                    assert.same({
                        type = 'Parenthetical',
                        kept = true,
                        annotation = '',
                        value = literal:toNetwork(),
                        operations = {},
                    }, instance:toNetwork())
                end)
            end)
        end)

        describe('#operation', function()
            describe('__tostring', function()
                it('returns a representation string for an instance', function()
                    assert.equal('<Parenthetical value=<Literal 16> operations=[]>', tostring(instance))
                end)
            end)
        end)
    end)

    describe('UnaryOp', function()
        local instance ---@type UnaryOp
        local literal ---@type Literal
        before_each(function()
            literal = Literal:new({ value = 5 })
            instance = UnaryOp:new({ value = literal, op = '-' })
        end)

        describe('#method', function()
            describe('getChildren', function()
                it('returns a list containing only the value', function()
                    assert.same({ literal }, instance:getChildren())
                end)
            end)

            describe('getList', function()
                it('returns a list containing itself', function()
                    assert.same({ instance }, instance:getList())
                end)
            end)

            describe('getNumber', function()
                it('returns the result of the operation', function()
                    local num = instance:getNumber()
                    assert.equal(-5, num)
                end)

                it('returns nil and an error if getting the value total fails', function()
                    local expectedErr = RollError:new('TooManyRolls')
                    stub(literal, 'getTotal', nil, expectedErr)

                    local result, err = instance:getNumber()
                    assert.is_nil(result)
                    assert.not_nil(err) ---@cast err -?
                    assert.equal(expectedErr, err)
                end)
            end)

            describe('toNetwork', function()
                it('converts to a plain table', function()
                    assert.same({
                        type = 'UnaryOp',
                        kept = true,
                        annotation = '',
                        op = instance.op,
                        value = literal:toNetwork(),
                    }, instance:toNetwork())
                end)
            end)
        end)

        describe('#operation', function()
            describe('__tostring', function()
                it('returns a representation string for an instance', function()
                    assert.equal('<UnaryOp op=- value=<Literal 5>>', tostring(instance))
                end)
            end)
        end)
    end)

    describe('BinaryOp', function()
        local instance ---@type BinaryOp
        local left ---@type Literal
        local right ---@type Literal
        before_each(function()
            left = Literal:new({ value = 8 })
            right = Literal:new({ value = 4 })
            instance = BinaryOp:new({ op = '+', left = left, right = right })
        end)

        describe('#method', function()
            describe('getChildren', function()
                it('returns a list containing only the left and right expressions', function()
                    assert.same({ left, right }, instance:getChildren())
                end)
            end)

            describe('getList', function()
                it('returns a list containing itself', function()
                    assert.same({ instance }, instance:getList())
                end)
            end)

            describe('getNumber', function()
                it('returns the result of the operation', function()
                    local num = instance:getNumber()
                    assert.equal(12, num)
                end)

                it('returns nil and an error if getting the left expression total fails', function()
                    local expectedErr = RollError:new('TooManyRolls')
                    stub(left, 'getTotal', nil, expectedErr)

                    local result, err = instance:getNumber()
                    assert.is_nil(result)
                    assert.not_nil(err) ---@cast err -?
                    assert.equal(expectedErr, err)
                end)

                it('returns nil and an error if getting the right expression total fails', function()
                    local expectedErr = RollError:new('ZeroSides')
                    stub(right, 'getTotal', nil, expectedErr)

                    local result, err = instance:getNumber()
                    assert.is_nil(result)
                    assert.not_nil(err) ---@cast err -?
                    assert.equal(expectedErr, err)
                end)
            end)

            describe('toNetwork', function()
                it('converts to a plain table', function()
                    assert.same({
                        type = 'BinaryOp',
                        kept = true,
                        annotation = '',
                        op = instance.op,
                        left = left:toNetwork(),
                        right = right:toNetwork(),
                    }, instance:toNetwork())
                end)
            end)
        end)

        describe('#operation', function()
            describe('__tostring', function()
                it('returns a representation string for an instance', function()
                    assert.equal('<BinaryOp op=+ left=<Literal 8> right=<Literal 4>>', tostring(instance))
                end)
            end)
        end)
    end)
end)
