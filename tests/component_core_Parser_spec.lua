---Contains tests for the Parser component.
---@using omi
---@diagnostic disable: access-invisible

local Parser = require 'OmiLibrary/Component/Core/Parser'

describe('#component Parser #method', function()
    local parser ---@type Parser
    local parserText = 'parser text'

    before_each(function()
        parser = Parser:new()
        parser:reset(parserText)
    end)

    describe('error', function()
        it('raises an error when passed the raiseErrors flag', function()
            parser = Parser:new({ raiseErrors = true })

            assert.error(
                function()
                    parser:error('parse error', { type = 'node', range = { 1, 1 } })
                end,
                'parse error'
            )
        end)
    end)

    describe('errorHere', function()
        it('produces an error at the current position', function()
            local s = spy.on(Parser, 'error')
            local node = { type = 'node', range = { 1, 1 } }

            parser:pos(4)
            parser:errorHere('error', node)

            assert.spy(s).called_with(
                match.ref(parser),
                'error',
                match.ref(node),
                4,
                4,
                nil
            )
        end)
    end)

    describe('forward', function()
        it('increments the pointer value', function()
            parser:forward()
            assert.equal(2, parser:pos())

            parser:forward()
            assert.equal(3, parser:pos())
        end)
    end)

    describe('parse', function()
        before_each(function()
            ---@diagnostic disable-next-line: duplicate-set-field, redundant-parameter
            parser.readExpression = function(self)
                local value = self:match('.+')
                local node = self:createNode('text', { value = value })
                self:setNodeEnd(node, self._ptr + #value - 1)
                self:forward(#value)

                return self:addNode(node)
            end
        end)

        it('returns a node tree', function()
            local expected = {
                type = 'tree',
                range = { 1, #parserText },
                children = {
                    {
                        type = 'text',
                        range = { 1, #parserText },
                        value = parserText,
                    },
                },
            }

            local result = parser:parse(parserText)
            assert.same(expected, result)
        end)

        it('produces an error if readExpression is not implemented', function()
            parser.readExpression = nil ---@diagnostic disable-line: duplicate-set-field
            assert.error(function() parser:parse(parserText) end, 'not implemented')
        end)
    end)

    describe('pos', function()
        it('returns the current pointer value', function()
            assert.equal(1, parser:pos())
        end)

        it('updates the pointer to the given value', function()
            assert.equal(3, parser:pos(3))
            assert.equal(3, parser:pos())
        end)
    end)

    describe('read', function()
        it('returns the given number of characters', function()
            local result = parser:read(3)
            assert.equal(3, #result)
        end)

        it('returns the remainder of the text when attempting to read beyond the end', function()
            local result = parser:read(#parserText + 1)
            assert.equal(parserText, result)
        end)
    end)

    describe('rewind', function()
        it('decrements the pointer value', function()
            parser:pos(3)

            parser:rewind()
            assert.equal(2, parser:pos())

            parser:rewind()
            assert.equal(1, parser:pos())
        end)
    end)

    describe('setNodeEnd', function()
        it('sets the end of a node range', function()
            local node = { type = 'node', range = { 1, 1 } }

            parser:pos(4)
            parser:setNodeEnd(node)
            assert.same({ 1, 4 }, node.range)
        end)

        it('does not throw if passed nil', function()
            parser:setNodeEnd(nil --[[@as any]])
        end)
    end)

    describe('setNodeStart', function()
        it('sets the start of a node range', function()
            local node = { type = 'node', range = { 1, 1 } }
            parser:pos(3)

            parser:setNodeStart(node)
            assert.same({ 3, 3 }, node.range)
        end)

        it('does not throw if passed nil', function()
            parser:setNodeStart(nil --[[@as any]])
        end)
    end)

    describe('warningHere', function()
        it('produces a warning at the current position', function()
            local s = spy.on(Parser, 'warning')
            local node = { type = 'node', range = { 1, 1 } }

            parser:pos(4)
            parser:warningHere('warning', node)

            assert.spy(s).called_with(
                match.ref(parser),
                'warning',
                match.ref(node),
                4,
                4,
                nil
            )
        end)
    end)
end)
