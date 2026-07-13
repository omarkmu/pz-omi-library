---Base expression type for dice evaluation.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'

local concat = table.concat
local format = string.format

---@class dice.ResolvableNumber : Class
---@field kept boolean Flag for whether the value was kept.
---@field annotation string An annotation for the value.
local ResolvableNumber = core.class('ResolvableNumber')


---Converts a list to a string representation.
---@param list any[]
---@return string
---@protected
function ResolvableNumber._listToString(list)
    local result = { '[' }

    for i = 1, #list do
        local el = list[i]

        if #result > 1 then
            result[#result + 1] = ', '
        end

        if type(el) == 'string' then
            result[#result + 1] = format('%q', el)
        else
            result[#result + 1] = tostring(el)
        end
    end

    result[#result + 1] = ']'
    return concat(result)
end

---Converts a list of operations into a string representation.
---@param operations Operation<string>[]
---@return string
---@protected
function ResolvableNumber._operationsToString(operations)
    local result = { '[' } ---@type (string | number)[]

    for i = 1, #operations do
        local op = operations[i]

        for j = 1, #op.selectors do
            local sel = op.selectors[j]

            if #result > 1 then
                result[#result + 1] = ', '
            end

            result[#result + 1] = op.type

            if sel.type then
                result[#result + 1] = sel.type
            end

            result[#result + 1] = sel.value
        end
    end

    result[#result + 1] = ']'
    return concat(result)
end


---Marks the expression as not kept,
---so it does not count towards the total roll value.
function ResolvableNumber:drop()
    self.kept = false
end

---Returns the list of child expressions.
---@return Expression[]
function ResolvableNumber:getChildren()
    return {}
end

---Returns the list representation of the object,
---including only elements whose values were kept.
---@return Expression[]
function ResolvableNumber:getKeptList()
    local full = self:getList()
    local list = {}

    for i = 1, #full do
        local el = full[i]
        if el.kept then
            list[#list + 1] = el
        end
    end

    return list
end

---Returns the expression's leftmost child, or `nil` if there are no children.
---@return Expression? left
function ResolvableNumber:getLeft()
    return self:getChildren()[1]
end

---Returns the list representation of the object.
---@return Expression[]
function ResolvableNumber:getList()
    error('not implemented')
end

---Returns the numerical value of the expression.
---@return number?
---@return DiceRollError?
function ResolvableNumber:getNumber()
    local list = self:getList()
    local sum = 0.0

    for i = 1, #list do
        local el = list[i]
        if el.kept then
            local num, err = el:getNumber()
            if not num then
                return nil, err
            end

            sum = sum + num
        end
    end

    return sum
end

---Returns the expression's rightmost child, or `nil` if there are no children.
---@return Expression? right
function ResolvableNumber:getRight()
    local children = self:getChildren()
    return children[#children]
end

---Returns the numerical value of the expression if it's kept.
---
---This is generally preferred compared to `getNumber`,
---since this returns 0 if the node was dropped.
---@return number?
---@return DiceRollError?
function ResolvableNumber:getTotal()
    if not self.kept then
        return 0
    end

    return self:getNumber()
end

---Returns an iterator over kept elements.
---The iterator has the same elements returned by `getKeptList`.
---@return fun(): Expression?
function ResolvableNumber:iterateKept()
    local i = 0
    local list = self:getList()

    return function()
        while i <= #list do
            local el = list[i]
            i = i + 1

            if el and el.kept then
                return el
            end
        end
    end
end

---Converts the expression into a plain table that can be sent over the network.
---@return table plain
function ResolvableNumber:toNetwork()
    return {
        type = self.type, ---@diagnostic disable-line: undefined-field
        kept = self.kept,
        annotation = self.annotation,
    }
end


---Returns the expression as a string.
---@protected
function ResolvableNumber:__tostring()
    error('not implemented')
end


---Creates an expression.
---@param args Args.DiceBase? Arguments for creation of the expression.
---@return ResolvableNumber
---@protected
function ResolvableNumber:new(args)
    local this = core.new(self)

    this.kept = (args and args.kept) ~= false
    this.annotation = concat(args and args.annotations or {})

    return this
end

return ResolvableNumber

--#region Type Definitions

---@class Args.DiceBase
---@field kept boolean? Flag for whether the value was kept. Defaults to `true`.
---@field annotations string[]? Annotations for the value.

--#endregion
