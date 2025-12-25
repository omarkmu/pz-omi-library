---Contains tests for the FluentParser component.
---@using omi
---@using omi.l10n
---@using omi.l10n.fluent

local FluentParser = require 'OmiLibrary/Component/L10N/FluentParser'

describe('#component FluentParser #method', function()
    local parser ---@type FluentParser
    before_each(function() parser = FluentParser:new() end)

    ---@generic T : AST.Node
    ---@param node AST.Node | nil
    ---@param expected omi.l10n.AST.`T`
    ---@return T node
    ---@return_cast node T
    local function expect(node, expected)
        assert.is_not_nil(node) ---@cast node -?
        assert.equal(expected, node.type)
        return node
    end

    describe('parse', function()
        describe('when parsing comments', function()
            it('allows empty comments if followed by a newline', function()
                local resource = parser:parse('#\n')

                local node = expect(resource.body[1], 'Comment')
                assert.equal('', node.content)
            end)

            it('returns a comment node for regular comments', function()
                local resource = parser:parse('# hello')

                local node = expect(resource.body[1], 'Comment')
                assert.equal('hello', node.content)
            end)

            it('returns a group comment node for group comments', function()
                local resource = parser:parse('## hello')

                local node = expect(resource.body[1], 'GroupComment')
                assert.equal('hello', node.content)
            end)

            it('returns a resource comment node for resource comments', function()
                local resource = parser:parse('### hello')

                local node = expect(resource.body[1], 'ResourceComment')
                assert.equal('hello', node.content)
            end)

            it('returns a single comment node for sequential comments', function()
                local resource = parser:parse('# hello\n# world')

                local node = expect(resource.body[1], 'Comment')
                assert.equal('hello\nworld', node.content)

                resource = parser:parse('# hello\n#\n# world')
                node = expect(resource.body[1], 'Comment')
                assert.equal('hello\n\nworld', node.content)
            end)

            it('returns multiple comment nodes for comments separated by blank lines', function()
                local resource = parser:parse('# hello\n\n# world')

                assert.equal(2, #resource.body)
                local node1 = expect(resource.body[1], 'Comment')
                local node2 = expect(resource.body[2], 'Comment')

                assert.equal('hello', node1.content)
                assert.equal('world', node2.content)
            end)

            it('produces an error if no space is included after hash character', function()
                assert.has_fluent_error_code(parser:parse('#oops'), 'E0003')
            end)
        end)

        describe('when parsing terms', function()
            it('reads a simple key = value term', function()
                local resource = parser:parse('-key = value')

                local node = expect(resource.body[1], 'Term')
                expect(node.id, 'Identifier')
                expect(node.value, 'Pattern')
                assert.equal(1, #node.value.elements)

                assert.equal('key', node.id.name)

                local pattern = expect(node.value.elements[1], 'TextElement')
                assert.equal('value', pattern.value)
            end)

            it('reads a term with a placeable', function()
                local resource = parser:parse('-key = { $var }')

                local node = expect(resource.body[1], 'Term')
                assert.equal('key', node.id.name)

                local pattern = expect(node.value.elements[1], 'Placeable')
                local var = expect(pattern.expression, 'VariableReference')
                assert.equal('var', var.id.name)
            end)

            it('reads a term with an attribute', function()
                local resource = parser:parse('-key = value\n  .attr = attrValue')

                local node = expect(resource.body[1], 'Term')
                assert.equal(1, #node.attributes)

                local attr = expect(node.attributes[1], 'Attribute')
                assert.equal('attr', attr.id.name)

                local el = expect(attr.value.elements[1], 'TextElement')
                assert.equal('attrValue', el.value)
            end)

            it('removes common indentation', function()
                local resource = parser:parse('-key = value\n  with\n  indent')

                local node = expect(resource.body[1], 'Term')
                local pattern = expect(node.value.elements[1], 'TextElement')
                assert.equal('value\nwith\nindent', pattern.value)
            end)

            it('removes common indentation from a block', function()
                local resource = parser:parse('-key =\n value\n  with\n indent')

                local node = expect(resource.body[1], 'Term')
                local el = expect(node.value.elements[1], 'TextElement')
                assert.equal('value\n with\nindent', el.value)
            end)

            it('produces an error if no value is given', function()
                assert.has_fluent_error_code(parser:parse('-key ='), 'E0006')
            end)
        end)

        describe('when parsing messages', function()
            it('reads a simple key = value messages', function()
                local resource = parser:parse('key = value')

                local node = expect(resource.body[1], 'Message')

                expect(node.id, 'Identifier')
                assert.equal('key', node.id.name)

                local pattern = expect(node.value, 'Pattern')
                assert.equal(1, #pattern.elements)

                local el = expect(pattern.elements[1], 'TextElement')
                assert.equal('value', el.value)
            end)

            it('reads a message with a placeable', function()
                local resource = parser:parse('key = { $var }')

                local node = expect(resource.body[1], 'Message')

                expect(node.id, 'Identifier')
                assert.equal('key', node.id.name)

                local pattern = expect(node.value, 'Pattern')
                local el = expect(pattern.elements[1], 'Placeable')
                local var = expect(el.expression, 'VariableReference')
                assert.equal('var', var.id.name)
            end)

            it('reads a message with an attribute', function()
                local resource = parser:parse('key = value\n  .attr = attrValue')

                local node = expect(resource.body[1], 'Message')
                assert.equal(1, #node.attributes)

                local attr = expect(node.attributes[1], 'Attribute')
                assert.equal('attr', attr.id.name)

                local el = expect(attr.value.elements[1], 'TextElement')
                assert.equal('attrValue', el.value)
            end)

            it('removes common indentation', function()
                local resource = parser:parse('key = value\n  with\n  indent')

                local node = expect(resource.body[1], 'Message')
                local pattern = expect(node.value, 'Pattern')
                local el = expect(pattern.elements[1], 'TextElement')
                assert.equal('value\nwith\nindent', el.value)
            end)

            it('removes common indentation from a block', function()
                local resource = parser:parse('key =\n value\n  with\n indent')

                local node = expect(resource.body[1], 'Message')
                local pattern = expect(node.value, 'Pattern')
                local el = expect(pattern.elements[1], 'TextElement')
                assert.equal('value\n with\nindent', el.value)
            end)

            it('produces an error if no value or attribute is given', function()
                assert.has_fluent_error_code(parser:parse('key ='), 'E0005')
            end)

            it('attaches directly preceding comments', function()
                local resource = parser:parse('# comment\nkey = value')

                local node = expect(resource.body[1], 'Message')
                local comment = expect(node.comment, 'Comment')
                assert.equal('comment', comment.content)
            end)
        end)

        describe('when parsing placeables', function()
            it('reads number literals', function()
                local resource = parser:parse('x = { -3.14 }')

                local node = expect(resource.body[1], 'Message')
                local pattern = expect(node.value, 'Pattern')
                local el = expect(pattern.elements[1], 'Placeable')

                local expr = expect(el.expression, 'NumberLiteral')
                assert.equal('-3.14', expr.value)
            end)

            it('reads string literals', function()
                local resource = parser:parse('x = { "hello \\"world\\" \\\\ \\u1000 \\U100000" }')

                local node = expect(resource.body[1], 'Message')
                local pattern = expect(node.value, 'Pattern')
                local el = expect(pattern.elements[1], 'Placeable')

                local expr = expect(el.expression, 'StringLiteral')
                assert.equal('hello \\"world\\" \\\\ \\u1000 \\U100000', expr.value)
            end)

            it('reads message references', function()
                local resource = parser:parse('x = { message }')

                local node = expect(resource.body[1], 'Message')
                local pattern = expect(node.value, 'Pattern')
                local el = expect(pattern.elements[1], 'Placeable')

                local expr = expect(el.expression, 'MessageReference')
                assert.equal('message', expr.id.name)
            end)

            it('reads message attribute references', function()
                local resource = parser:parse('x = { message.attr }')

                local node = expect(resource.body[1], 'Message')
                local pattern = expect(node.value, 'Pattern')
                local el = expect(pattern.elements[1], 'Placeable')

                local expr = expect(el.expression, 'MessageReference')
                assert.equal('message', expr.id.name)

                local attr = expect(expr.attribute, 'Identifier')
                assert.equal('attr', attr.name)
            end)

            it('reads term references', function()
                local resource = parser:parse('x = { -term }')

                local node = expect(resource.body[1], 'Message')
                local pattern = expect(node.value, 'Pattern')
                local el = expect(pattern.elements[1], 'Placeable')

                local expr = expect(el.expression, 'TermReference')
                assert.equal('term', expr.id.name)
            end)

            it('does not allow term attribute references', function()
                local resource = parser:parse('x = { -term.attr }')

                assert.has_fluent_error_code(resource, 'E0019')
            end)

            it('reads parameterized term references', function()
                local resource = parser:parse('x = { -term(attr: "value") }')

                local node = expect(resource.body[1], 'Message')
                local pattern = expect(node.value, 'Pattern')
                local el = expect(pattern.elements[1], 'Placeable')

                local expr = expect(el.expression, 'TermReference')
                assert.equal('term', expr.id.name)

                local args = expr.arguments
                assert.is_not_nil(args) ---@cast args -?

                assert.equal(1, #args.named)

                local namedArg = expect(args.named[1], 'NamedArgument')
                assert.equal('attr', namedArg.name.name)

                local value = expect(namedArg.value, 'StringLiteral')
                assert.equal('value', value.value)
            end)

            it('reads functions', function()
                local resource = parser:parse('x = { NUMBER(1) }')

                local node = expect(resource.body[1], 'Message')
                local pattern = expect(node.value, 'Pattern')
                local el = expect(pattern.elements[1], 'Placeable')

                local expr = expect(el.expression, 'FunctionReference')
                assert.equal('NUMBER', expr.id.name)

                local args = expr.arguments
                assert.equal(1, #args.positional)

                local firstArg = expect(args.positional[1], 'NumberLiteral')
                assert.equal('1', firstArg.value)
            end)

            it('reads functions with arguments', function()
                local resource = parser:parse('x = { GETTEXT("string_id", $var) }')

                local node = expect(resource.body[1], 'Message')
                local pattern = expect(node.value, 'Pattern')
                local el = expect(pattern.elements[1], 'Placeable')

                local expr = expect(el.expression, 'FunctionReference')
                assert.equal('GETTEXT', expr.id.name)

                local args = expr.arguments
                assert.equal(2, #args.positional)

                local firstArg = expect(args.positional[1], 'StringLiteral')
                assert.equal('string_id', firstArg.value)

                local secondArg = expect(args.positional[2], 'VariableReference')
                assert.equal('var', secondArg.id.name)
            end)

            it('reads variants', function()
                local resource = parser:parse('x = { $var ->\n  [one] value for 1\n  *[other] value for other\n}')

                local node = expect(resource.body[1], 'Message')
                local pattern = expect(node.value, 'Pattern')
                local placeable = expect(pattern.elements[1], 'Placeable')

                local expr = expect(placeable.expression, 'SelectExpression')
                local selector = expect(expr.selector, 'VariableReference')
                assert.equal('var', selector.id.name)

                assert.equal(2, #expr.variants)

                local oneVariant = expect(expr.variants[1], 'Variant')
                local otherVariant = expect(expr.variants[2], 'Variant')

                assert.is_false(oneVariant.default)
                assert.is_true(otherVariant.default)

                assert.equal('one', oneVariant.key.name)
                assert.equal('other', otherVariant.key.name)
            end)
        end)
    end)
end)
