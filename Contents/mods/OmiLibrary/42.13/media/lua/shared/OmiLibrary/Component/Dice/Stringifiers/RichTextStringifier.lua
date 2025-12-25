---Rich text stringifier.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'
local color = require 'OmiLibrary/Module/Color'
local SimpleStringifier = require 'OmiLibrary/Component/Dice/Stringifiers/SimpleStringifier'

local concat = table.concat


---@class dice.RichTextStringifier : SimpleStringifier
---@field successColor string? The color string to use for maximum rolls.
---@field failureColor string? The color string to use when 1 is rolled.
---@field droppedColor string? The color string to use for a non-kept value.
local RichTextStringifier = SimpleStringifier:derive('RichTextStringifier')


---Associates strings to strings that should replace them.
---@private
RichTextStringifier._escapes = {
    ['<'] = '&lt;',
    ['<='] = '&lt;=',
    ['>'] = '&gt;',
    ['>='] = '&gt;=',
}


---Called to add an annotation to the expression, if present.
---@param str string
---@param expr Expression
---@return string
---@protected
function RichTextStringifier:_formatAnnotation(str, expr)
    return str .. ' ' .. core.escapeRichText(expr.annotation)
end

---Alters a stringified result to indicate that an expression is dropped.
---@param str string
---@param expr Expression
---@protected
function RichTextStringifier:_formatDropped(str, expr)
    if self.droppedColor then
        str = self.droppedColor .. str .. ' <POPRGB> '
    end

    if self._doStrikethrough then
        str = ' <STRIKE> ' .. str .. ' </STRIKE> '
    end

    return str
end

---Called to format an identifier name.
---@param name string
---@return string
---@protected
function RichTextStringifier:_formatIdentifierName(name)
    return core.escapeRichText(name)
end

---Called to format a binary or unary operator.
---@param op BinaryOperator | UnaryOperator
---@return string
---@protected
function RichTextStringifier:_formatOperator(op)
    return RichTextStringifier._escapes[op] or op
end

---Called to format a selector type.
---@param sel SelectorType?
---@return string
---@protected
function RichTextStringifier:_formatSelectorType(sel)
    if not sel then
        return ''
    end

    return RichTextStringifier._escapes[sel] or sel
end

---Converts a die to a string.
---@param expr Die
---@return string
---@protected
function RichTextStringifier:_stringifyDie(expr)
    local results = {}

    for i = 1, #expr.values do
        local value = expr.values[i]
        local str = self:_stringify(value)

        if not self._inDropped and (self.failureColor or self.successColor) then
            local n = value:getNumber()
            if n == 1 and self.failureColor then
                str = self.failureColor .. str .. ' <POPRGB> '
            elseif n == expr.size and self.successColor then
                str = self.successColor .. str .. ' <POPRGB> '
            end
        end

        results[#results + 1] = str
    end

    return concat(results, self._listSeparator)
end


---Creates a new stringifier.
---@param args Args.DiceRichTextStringifier? Arguments for creation of the stringifier.
---@return RichTextStringifier
function RichTextStringifier:new(args)
    args = args or {} --[[@as Args.DiceRichTextStringifier]]
    local this = core.new(self, SimpleStringifier.new, args)

    this._listSeparator = ', <SPACE> '

    if args.successColor ~= false then
        local clr = args.successColor or color.good
        this.successColor = color.toRichText(clr, true)
    end

    if args.failureColor ~= false then
        local clr = args.failureColor or color.bad
        this.failureColor = color.toRichText(clr, true)
    end

    if args.droppedColor ~= false then
        local clr = args.droppedColor or { r = 120, g = 120, b = 120 }
        this.droppedColor = color.toRichText(clr, true)
    end

    return this
end


return RichTextStringifier

--#region Type Definitions

---@class Args.DiceRichTextStringifier : Args.DiceSimpleStringifier
---@field successColor (ColorTable<integer> | false)? The color to use for maximum rolls.
---Defaults to the good highlight color. If `false`, maximums won't be colored.
---@field failureColor (ColorTable<integer> | false)? The color to use when 1 is rolled.
---Defaults to the bad highlight color. If `false`, failure rolls won't be colored.
---@field droppedColor (ColorTable<integer> | false)? The color to use when a value is not kept.
---Defaults to gray. If `false`, dropped rolls won't be colored.
---@field doStrikethrough boolean? Flag for whether dropped values should be
---indicated with a `<STRIKE>` rich text command. Defaults to `true`.
---
---The `<STRIKE>` command is only supported by the extended rich text panel.

--#endregion
