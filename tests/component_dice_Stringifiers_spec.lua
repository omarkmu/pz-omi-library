---Contains tests for dice expression components.
---@using omi
---@using omi.dice
---@diagnostic disable: access-invisible

local dice = require 'OmiLibrary/Module/Dice'

local Stringifier = dice.Stringifier
local SimpleStringifier = dice.SimpleStringifier
local RichTextStringifier = dice.RichTextStringifier

describe('#component', function()
    local instance ---@type Stringifier

    ---@param expr string
    local function roll(expr)
        return dice.roll(expr, { stringifier = instance })
    end

    describe('Stringifier', function()
        before_each(function()
            instance = Stringifier:new()
        end)

        describe('#method stringify', function()
            it('adds annotations to expressions', function()
                stub(Stringifier, '_stringifyDice', 'd20 (20)'):auto_revert()

                ---@param self Stringifier
                ---@param expr RollExpression
                stub(Stringifier, '_stringifyExpression', function(self, expr)
                    return self:_stringify(expr.roll) .. ' = 20'
                end):auto_revert()

                instance = Stringifier:new()
                local result = roll('d20 [attack] [fire]')
                assert.equal('d20 (20) [attack][fire] = 20', tostring(result))
            end)

            describe('throws a not implemented error', function()
                local _stringifyExpression ---@type luassert.stub
                setup(function()
                    ---@param self Stringifier
                    ---@param expr RollExpression
                    _stringifyExpression = stub(Stringifier, '_stringifyExpression', function(self, expr)
                        return self:_stringify(expr.roll)
                    end):auto_revert()
                end)

                ---@param desc string
                ---@param expr string
                local function testThrowsNotImplemented(desc, expr)
                    it('for ' .. desc, function()
                        local result = roll(expr)
                        assert.error(function() tostring(result) end, 'not implemented')
                    end)
                end

                testThrowsNotImplemented('a literal', '5')
                testThrowsNotImplemented('a dice expression', 'd20')
                testThrowsNotImplemented('a parenthetical', '(d20)')
                testThrowsNotImplemented('a unary operation', '-d8')
                testThrowsNotImplemented('a binary operation', 'd8 + 2')
                testThrowsNotImplemented('a dice set', '(d20, d6)')

                it('for a die', function()
                    ---@param self Stringifier
                    ---@param expr Dice
                    stub(Stringifier, '_stringifyDice', function(self, expr)
                        return self:_stringify(expr.values[1] --[[@as Die]])
                    end):auto_revert()

                    instance = Stringifier:new()
                    local result = roll('d20')
                    assert.error(function() tostring(result) end, 'not implemented')
                end)

                it('for a roll expression', function()
                    _stringifyExpression:revert()
                    instance = Stringifier:new()
                    local result = roll('d20')
                    assert.error(function() tostring(result) end, 'not implemented')
                end)
            end)
        end)
    end)

    describe('SimpleStringifier', function()
        before_each(function()
            instance = SimpleStringifier:new()
        end)

        describe('#method stringify', function()
            describe('with the default settings', function()
                it('can convert literal expressions to strings', function()
                    local result = roll('5')
                    assert.equal('5 = 5', tostring(result))
                end)

                it('can convert dice expressions to strings', function()
                    local result = roll('d20')
                    assert.match('^d20 %(%d+%) = %d+$', tostring(result))
                end)

                it('can convert dropped dice expressions to strings', function()
                    local result = roll('d20ro>0')
                    assert.match('^d20ro>0 %(~~%d+~~, %d+%) = %d+$', tostring(result))
                end)

                it('can convert exploded dice expressions to strings', function()
                    local result = roll('d20ra>0')
                    assert.match('^d20ra>0 %(%d+!, %d+%) = %d+$', tostring(result))
                end)

                it('can convert unary operations to strings', function()
                    local result = roll('-1')
                    assert.equal('-1 = -1', tostring(result))
                end)

                it('can convert binary operations to strings', function()
                    local result = roll('5 + 5')
                    assert.equal('5 + 5 = 10', tostring(result))
                end)

                it('can convert parenthetical expressions to strings', function()
                    local result = roll('(d20)')
                    assert.match('^%(d20 %(%d+%)%) = %d+$', tostring(result))
                end)

                it('can convert dice sets to strings', function()
                    local result = roll('(d20, d6)')
                    assert.match('^%(d20 %(%d+%), d6 %(%d+%)%) = %d+$', tostring(result))
                end)

                it('can convert dice sets with a single value to strings', function()
                    local result = roll('(d8,)')
                    assert.match('^%(d8 %(%d+%),%) = %d+$', tostring(result))
                end)

                it('can convert operations to strings', function()
                    local result = roll('d20mi21')
                    assert.match('^d20mi21 %(%d+ %-> 21%) = %d+$', tostring(result))

                    result = roll('d20ro<21ma0')
                    assert.match('^d20ro<21ma0 %(~~%d+~~, %d+ %-> 0%) = 0$', tostring(result))
                end)
            end)

            describe('with includeTotal set to false', function()
                before_each(function()
                    instance = SimpleStringifier:new({ includeTotal = false })
                end)

                it('does not include the total', function()
                    local result = roll('d20')
                    assert.match('^d20 %(%d+%)$', tostring(result))
                end)
            end)

            describe('with doStrikethrough set to false', function()
                before_each(function()
                    instance = SimpleStringifier:new({ doStrikethrough = false })
                end)

                it('does not indicate dropped values', function()
                    local result = roll('d20p>0')
                    assert.match('^d20p>0 %(%d+%) = 0$', tostring(result))
                end)
            end)
        end)
    end)

    describe('RichTextStringifier', function()
        before_each(function()
            instance = RichTextStringifier:new()
        end)

        describe('#method stringify', function()
            describe('with the default settings', function()
                it('can convert dice to strings', function()
                    local result = roll('d20')
                    assert.match('^d20 %(.-%) = %d+$', tostring(result))
                end)

                it('uses the default success color for maximum rolls', function()
                    local result = roll('d20mi20')
                    local expected = '^d20mi20 %( <PUSHRGB:0.0,1.0,0.0> .+ <POPRGB> %) = 20$'
                    assert.match(expected, tostring(result))
                end)

                it('uses the default failure color for minimum rolls', function()
                    local result = roll('d20ma1')
                    local expected = '^d20ma1 %( <PUSHRGB:1.0,0.0,0.0> .+ <POPRGB> %) = 1$'
                    assert.match(expected, tostring(result))
                end)

                it('uses the default dropped color for dropped rolls', function()
                    local result = roll('d20p>0')
                    assert.match(
                        '^d20p&gt;0 %( <STRIKE>  <PUSHRGB:0.4705882,0.4705882,0.4705882> .+ <POPRGB>  </STRIKE> %) = 0$',
                        tostring(result)
                    )
                end)

                it('can convert dice with literal selectors to strings', function()
                    local result = roll('d1mi1')
                    assert.match('^d1mi1 %(.+%) = 1$', tostring(result))
                end)

                it('escapes selector types for rich text', function()
                    local result = roll('d20p>20')
                    assert.match('^d20p&gt;20.+$', tostring(result))
                end)

                it('escapes the greater than operator for rich text', function()
                    local result = roll('d6 > 7')
                    assert.match('^d6 %(.+%) &gt; 7 = 0$', tostring(result))
                end)

                it('escapes the greater than or equal to operator for rich text', function()
                    local result = roll('d6 >= 7')
                    assert.match('^d6 %(.+%) &gt;= 7 = 0$', tostring(result))
                end)

                it('escapes the less than operator for rich text', function()
                    local result = roll('d6 < 7')
                    assert.match('^d6 %(.+%) &lt; 7 = 1$', tostring(result))
                end)

                it('escapes the less than or equal to operator for rich text', function()
                    local result = roll('d6 <= 7')
                    assert.match('^d6 %(.+%) &lt;= 7 = 1$', tostring(result))
                end)

                it('escapes annotations for rich text', function()
                    local result = roll('d20 [please be >1]')
                    assert.match('^d20 %(.+%) %[please be &gt;1%] = %d+$', tostring(result))
                end)
            end)

            describe('with includeTotal set to false', function()
                before_each(function()
                    instance = RichTextStringifier:new({
                        includeTotal = false,
                        successColor = false,
                        failureColor = false,
                    })
                end)

                it('does not include the total', function()
                    local result = roll('d20')
                    assert.match('^d20 %(%d+%)$', tostring(result))
                end)
            end)

            describe('with custom color settings', function()
                before_each(function()
                    instance = RichTextStringifier:new({
                        successColor = { r = 51, g = 51, b = 255 },
                        failureColor = { r = 255, g = 51, b = 51 },
                        droppedColor = { r = 255, g = 255, b = 255 },
                    })
                end)

                it('uses the configured success color for maximum rolls', function()
                    local result = roll('d20mi20')
                    local expected = '^d20mi20 %( <PUSHRGB:0.2,0.2,1.0> .+ <POPRGB> %) = 20$'
                    assert.match(expected, tostring(result))
                end)

                it('uses the configured failure color for minimum rolls', function()
                    local result = roll('d20ma1')
                    local expected = '^d20ma1 %( <PUSHRGB:1.0,0.2,0.2> .+ <POPRGB> %) = 1$'
                    assert.match(expected, tostring(result))
                end)

                it('uses the configured dropped color for dropped rolls', function()
                    local result = roll('d20p>0')
                    local expected = '^d20p&gt;0 %( <STRIKE>  <PUSHRGB:1.0,1.0,1.0> .+ <POPRGB>  </STRIKE> %) = 0$'
                    assert.match(expected, tostring(result))
                end)
            end)

            describe('with disabled color settings', function()
                before_each(function()
                    instance = RichTextStringifier:new({
                        successColor = false,
                        failureColor = false,
                        droppedColor = false,
                    })
                end)

                it('does not add color commands for maximum rolls', function()
                    local result = roll('d20mi20')
                    local expected = '^d20mi20 %([^<]+%) = 20$'
                    assert.match(expected, tostring(result))
                end)

                it('does not add color commands for minimum rolls', function()
                    local result = roll('d20ma1')
                    local expected = '^d20ma1 %([^<]+%) = 1$'
                    assert.match(expected, tostring(result))
                end)

                it('does not add color commands for dropped rolls', function()
                    local result = roll('d20p>0')
                    local expected = '^d20p&gt;0 %( <STRIKE> [^<]+ </STRIKE> %) = 0$'
                    assert.match(expected, tostring(result))
                end)
            end)
        end)
    end)
end)
