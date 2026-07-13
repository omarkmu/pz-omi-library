---Handler for dice rolls.
---@namespace omi
---@using omi.dice

local core = require 'OmiLibrary/Module/Utils'
local set = require 'OmiLibrary/Module/Set'
local Cache = require 'OmiLibrary/Component/Cache/Cache'
local Parser = require 'OmiLibrary/Component/Dice/DiceParser'
local Dice = require 'OmiLibrary/Component/Dice/Expressions/Dice'
local DiceSet = require 'OmiLibrary/Component/Dice/Expressions/DiceSet'
local RollExpression = require 'OmiLibrary/Component/Dice/Expressions/RollExpression'
local UnaryOp = require 'OmiLibrary/Component/Dice/Expressions/UnaryOp'
local BinaryOp = require 'OmiLibrary/Component/Dice/Expressions/BinaryOp'
local Literal = require 'OmiLibrary/Component/Dice/Expressions/Literal'
local Parenthetical = require 'OmiLibrary/Component/Dice/Expressions/Parenthetical'
local Identifier = require 'OmiLibrary/Component/Dice/Expressions/Identifier'
local RollResult = require 'OmiLibrary/Component/Dice/RollResult'
local RollError = require 'OmiLibrary/Component/Dice/DiceRollError'

local type = type
local sort = table.sort

---@class DiceRoller : Class
---@field protected _rolls integer The current count of dice rolls.
---@field protected _maxRolls integer? The maximum number of rolls.
---@field protected _cache Cache<CacheData> Cache for parsed dice expressions.
---@field protected _evaluators table<AST.NodeType, DiceEvaluator> Associates node types to
---handlers for evaluating them into expression objects.
---@field protected _operators table<DiceOperator, DiceOperation> Associates dice operators to
---handlers for performing the operation.
---@field protected _selectors table<SelectorType, SelectorFunction> Associates selector types to
---handlers for selecting values.
---@field protected _vars table<string, number> Associates variable names to values that can be used in the current expression.
---@field protected _globalVars table<string, number> Associates variable names to values that can be used in any expression.
---@field protected _getVariableCb? fun(name: string): number Callback provided to `roll` for getting variable values.
local Roller = core.class('Roller')


---Shared dice expression parser instance.
---@private
Roller._parser = Parser:new()


---Helper to replace spaces in an annotation with `&nbsp;`.
---@param annotation string
---@return string
local function escapeAnnotation(annotation)
    return (annotation:gsub('%s+', '&nbsp;'))
end


---Adds to the running count of dice rolls.
---Called before rolling a die.
---
---Returns an error if the count exceeds the maximum.
---@return DiceRollError?
function Roller:countRoll()
    self._rolls = self._rolls + 1
    if self._maxRolls and self._rolls > self._maxRolls then
        return RollError:new('TooManyRolls')
    end
end

---Parses a dice expression.
---Throws an error for an invalid expression.
---@param expr string The expression string.
---@return AST.Expression result The result of parsing.
function Roller:parse(expr)
    local result, err = self:tryParse(expr)
    if not result then
        assert(err ~= nil)
        error(err.message)
    end

    return result
end

---Evaluates a dice expression.
---@param expr string | AST.Expression The dice expression to roll.
---@param args Args.Roll? Additional options for the roll.
---@return RollResult result The result of the roll.
function Roller:roll(expr, args)
    local result, err = self:tryRoll(expr, args)
    if not result then
        assert(err ~= nil)
        error(err.message)
    end

    return result
end

---Parses a dice expression, returning `nil` and an error on failure.
---@param expr string The expression string.
---@return AST.Expression? result The result of parsing, or `nil` if an error occurred.
---@return DiceParseError? error The error that occurred.
function Roller:tryParse(expr)
    expr = expr:gsub('%[.-%]', escapeAnnotation)
        :gsub('%s+', '')
        :gsub('&nbsp;', ' ')

    local cached = self._cache:get(expr)
    if cached then
        return cached.expression
    end

    local result, err = self._parser:parse(expr)
    if not result then
        return nil, err
    end

    self._cache:set(expr, {
        key = expr,
        expression = result,
    })

    return result
end

---Evaluates a dice expression, returning `nil` and an error on failure.
---@param expr string | AST.Expression The dice expression to roll.
---@param args Args.Roll? Additional options for the roll.
---@return RollResult? result The result of the roll, or `nil` if an error occurred.
---@return (DiceRollError | DiceParseError)? error The error that occurred.
function Roller:tryRoll(expr, args)
    self._rolls = 0
    self._getVariableCb = args and args.getVariable

    local ast ---@type AST.Expression
    if type(expr) == 'string' then
        local parsed, err = self:tryParse(expr --[[@as string]])
        if not parsed then
            return nil, err
        end

        ast = parsed
    else
        ast = expr
    end

    if args and args.advantage then
        ast = self:_applyAdvantage(ast, args.advantage)
    end

    self._vars = args and args.variables or {}

    local evaluated, err = self:_eval(ast)
    if not evaluated then
        return nil, err
    end

    return RollResult:new({
        expression = RollExpression:new({ roll = evaluated }),
        stringifier = args and args.stringifier,
    })
end


---Creates a copy of an AST, with modifications based on advantage.
---@param expr AST.Expression
---@param adv AdvType
---@return AST.Expression
---@protected
function Roller:_applyAdvantage(expr, adv)
    local root = core.copy(expr)
    if adv ~= 1 and adv ~= 2 then
        return root
    end

    -- copy the left side of the tree down, get a clone of the leftmost node
    local parent = root ---@type AST.Expression?
    local child = root ---@type AST.Expression?
    while parent do
        if parent.type == 'BinOp' then
            ---@cast parent AST.BinOp
            parent.left = core.copy(parent.left)
            child = parent.left
        elseif parent.type == 'Set' then
            ---@cast parent AST.Set
            parent.values[1] = core.copy(parent.values[1])
            child = parent.values[1]
        elseif parent.type == 'UnOp' or parent.type == 'Parenthetical' then
            ---@cast parent AST.UnOp & AST.Parenthetical
            parent.value = core.copy(parent.value)
            child = parent.value
        else
            break
        end

        parent = child
    end

    if not child or child.type ~= 'Dice' then
        return root
    end

    ---@cast child AST.Dice
    if child.size ~= 20 or (child.count and child.count ~= 1) then
        return root
    end

    -- change to 2d20
    child.count = 2

    -- add operation
    local selType = adv == 1 and 'h' or 'l'

    child.operations = core.copyList(child.operations)
    child.operations[#child.operations + 1] = {
        type = 'k',
        selectors = { { type = selType, value = 1 } },
    }

    return root
end

---Gets the value to use for an identifier.
---@param name string The identifier name.
---@return number
---@protected
function Roller:_getVariable(name)
    local cb = self._getVariableCb
    local result = cb and cb(name)

    return result or self._vars[name] or self._globalVars[name] or 0
end

---Evaluates an AST expression node.
---@param node AST.Expression
---@return Expression?
---@return DiceRollError?
---@protected
function Roller:_eval(node)
    local handler = self._evaluators[node.type]
    return handler(self, node)
end

---Evaluates an AST binary operation node.
---@param node AST.BinOp
---@return BinaryOp?
---@return DiceRollError?
---@protected
function Roller:_evalBinOp(node)
    local left, right, err

    left, err = self:_eval(node.left)
    if not left then
        return nil, err
    end

    right, err = self:_eval(node.right)
    if not right then
        return nil, err
    end

    return BinaryOp:new({
        op = node.op,
        left = left,
        right = right,
    })
end

---Evaluates an AST dice node.
---@param node AST.Dice
---@return Dice?
---@return DiceRollError?
---@protected
function Roller:_evalDice(node)
    ---@type Args.Dice
    local args = {
        count = node.count,
        size = node.size,
        annotations = node.annotations,
        operations = node.operations,
        roller = self,
    }

    local dice = Dice:new(args)
    local err = dice:roll()

    if not err and #dice.operations > 0 then
        err = self:_evalSetOperations(dice)
    end

    if err then
        return nil, err
    end

    return dice
end

---Evaluates an AST identifier node.
---@param node AST.Identifier
---@return Identifier?
---@return DiceRollError?
---@protected
function Roller:_evalIdentifier(node)
    local name = node.name

    local literal = Literal:new({ value = self:_getVariable(name) })
    return Identifier:new({ name = name, value = literal })
end

---Evaluates an AST literal node.
---@param node AST.Literal
---@return Literal
---@protected
function Roller:_evalLiteral(node)
    return Literal:new({
        value = node.value,
        annotations = node.annotations,
    })
end

---Evaluates an AST parenthetical node.
---@param node AST.Parenthetical
---@return Parenthetical?
---@return DiceRollError?
---@protected
function Roller:_evalParenthetical(node)
    local value, err = self:_eval(node.value)
    if not value then
        return nil, err
    end

    local expr = Parenthetical:new({
        value = value,
        annotations = node.annotations,
        operations = node.operations,
    })

    if #expr.operations > 0 then
        err = self:_evalSetOperations(expr)
        if err then
            return nil, err
        end
    end

    return expr
end

---Evaluates an AST set node.
---@param node AST.Set
---@return dice.DiceSet?
---@return DiceRollError?
---@protected
function Roller:_evalSet(node)
    local values = {} ---@type Expression[]

    for i = 1, #node.values do
        local value, err = self:_eval(node.values[i])
        if not value then
            return nil, err
        end

        values[#values + 1] = value
    end

    ---@type Args.DiceSet
    local args = {
        values = values,
        annotations = node.annotations,
        operations = node.operations,
    }

    local expr = DiceSet:new(args)

    if #expr.operations > 0 then
        local err = self:_evalSetOperations(expr)
        if err then
            return nil, err
        end
    end

    return expr
end

---Evaluates dice or set operations.
---@param expr OperatedExpression
---@return DiceRollError?
---@protected
function Roller:_evalSetOperations(expr)
    for i = 1, #expr.operations do
        local op = expr.operations[i]
        local operation = self._operators[op.type]
        local err = operation(self, expr, op.selectors)
        if err then
            return err
        end
    end
end

---Evaluates an AST unary operation node.
---@param node AST.UnOp
---@return UnaryOp?
---@return DiceRollError?
---@protected
function Roller:_evalUnOp(node)
    local value, err = self:_eval(node.value)
    if not value then
        return nil, err
    end

    return UnaryOp:new({
        op = node.op,
        value = value,
    })
end

---Performs the `p` operation.
---@param expr OperatedExpression
---@param selectors Selector[]
---@protected
function Roller:_opDrop(expr, selectors)
    for node in self:_select(expr, selectors):elements() do
        node:drop()
    end
end

---Performs the `e` operation.
---@param dice Dice
---@param selectors Selector[]
---@return DiceRollError?
---@protected
function Roller:_opExplode(dice, selectors)
    local toExplode = self:_select(dice, selectors)
    local exploded = set() --[[@as Set<Die>]]

    while toExplode:size() > 0 do
        for die in toExplode:elements() do
            die:explode()
            local err = dice:rollAnother()
            if err then
                return err
            end
        end

        exploded:updateFromSet(toExplode)
        toExplode = self:_select(dice, selectors):difference(exploded)
    end
end

---Performs the `ra` operation.
---@param dice Dice
---@param selectors Selector[]
---@return DiceRollError?
---@protected
function Roller:_opExplodeOnce(dice, selectors)
    for die in self:_select(dice, selectors, 1):elements() do
        die:explode()
        local err = dice:rollAnother()
        if err then
            return err
        end
    end
end

---Performs the `k` operation.
---@param expr OperatedExpression
---@param selectors Selector[]
---@protected
function Roller:_opKeep(expr, selectors)
    local toKeep = self:_select(expr, selectors)
    for kept in expr:iterateKept() do
        if not toKeep:has(kept) then
            kept:drop()
            toKeep = self:_select(expr, selectors)
        end
    end
end

---Performs the `ma` operation.
---@param expr OperatedExpression
---@param selectors Selector[]
---@return DiceRollError?
---@protected
function Roller:_opMaximum(expr, selectors)
    local sel = selectors[#selectors] ---@as Selector
    if sel.type then
        return RollError:new('InvalidSelectorMaximum', sel.type)
    end

    for die in expr:iterateKept() do
        ---@cast die Die
        if die:getNumber() > sel.value then
            die:forceValue(sel.value)
        end
    end
end

---Performs the `mi` operation.
---@param expr OperatedExpression
---@param selectors Selector[]
---@return DiceRollError?
---@protected
function Roller:_opMinimum(expr, selectors)
    local sel = selectors[#selectors] ---@as Selector
    if sel.type then
        return RollError:new('InvalidSelectorMinimum', sel.type)
    end

    for die in expr:iterateKept() do
        ---@cast die Die
        if die:getNumber() < sel.value then
            die:forceValue(sel.value)
        end
    end
end

---Performs the `rr` operation.
---@param dice Dice
---@param selectors Selector[]
---@return DiceRollError?
---@protected
function Roller:_opReroll(dice, selectors)
    local toReroll = self:_select(dice, selectors)

    while toReroll:size() > 0 do
        for die in toReroll:elements() do
            local err = die:reroll()
            if err then
                return err
            end
        end

        toReroll = self:_select(dice, selectors)
    end
end

---Performs the `ro` operation.
---@param dice Dice
---@param selectors Selector[]
---@return DiceRollError?
---@protected
function Roller:_opRerollOnce(dice, selectors)
    local toReroll = self:_select(dice, selectors)
    for die in toReroll:elements() do
        local err = die:reroll()
        if err then
            return err
        end
    end
end

---Selects the kept values that match the selectors.
---@param expr OperatedExpression
---@param selectors Selector[]
---@param maxTargets integer?
---@return Set<Expression>
---@protected
---@overload fun(dice: Dice, selectors: Selector[]): Set<Die>
---@overload fun(dice: Dice, selectors: Selector[], maxTargets: integer?): Set<Die>
function Roller:_select(expr, selectors, maxTargets)
    local out = set.ordered() --[[@as OrderedSet<Expression>]]

    for i = 1, #selectors do
        local batchMax = maxTargets and (maxTargets - #out) or nil
        if batchMax and batchMax <= 0 then
            break
        end

        local sel = selectors[i]
        local handler = sel.type and self._selectors[sel.type] or self._selectLiteral

        local selected = handler(self, expr, sel.value)
        if batchMax and #selected > batchMax then
            selected[batchMax + 1] = nil
        end

        out:updateFromList(selected)
    end

    return out
end

---Selector for values greater than a target value.
---@param expr Expression
---@param value integer
---@return Expression[]
---@protected
function Roller:_selectGreaterThan(expr, value)
    local list = {} ---@type Expression[]

    for kept in expr:iterateKept() do
        if kept:getTotal() > value then
            list[#list + 1] = kept
        end
    end

    return list
end

---Selector for highest values.
---@param expr Expression
---@param value integer
---@return Expression[]
---@protected
function Roller:_selectHighestN(expr, value)
    local totals = {} ---@type table<Expression, number?>
    local keptList = expr:getKeptList()
    sort(keptList, function(a, b)
        local aTotal = totals[a]
        local bTotal = totals[b]

        if not aTotal then
            aTotal = a:getTotal()
            totals[a] = aTotal
        end

        if not bTotal then
            bTotal = b:getTotal()
            totals[b] = bTotal
        end

        return aTotal > bTotal
    end)

    return core.slice(keptList, 1, value)
end

---Selector for exact literal values.
---@param expr Expression
---@param value integer
---@return Expression[]
---@protected
function Roller:_selectLiteral(expr, value)
    local list = {} ---@type Expression[]

    for kept in expr:iterateKept() do
        if kept:getTotal() == value then
            list[#list + 1] = kept
        end
    end

    return list
end

---Selector for values less than a target value.
---@param expr Expression
---@param value integer
---@return Expression[]
---@protected
function Roller:_selectLessThan(expr, value)
    local list = {} ---@type Expression[]

    for kept in expr:iterateKept() do
        if kept:getTotal() < value then
            list[#list + 1] = kept
        end
    end

    return list
end

---Selector for lowest values.
---@param expr Expression
---@param value integer
---@return Expression[]
---@protected
function Roller:_selectLowestN(expr, value)
    local totals = {} ---@type table<Expression, number?>
    local keptList = expr:getKeptList()
    sort(keptList, function(a, b)
        local aTotal = totals[a]
        local bTotal = totals[b]

        if not aTotal then
            aTotal = a:getTotal()
            totals[a] = aTotal
        end

        if not bTotal then
            bTotal = b:getTotal()
            totals[b] = bTotal
        end

        return aTotal < bTotal
    end)

    return core.slice(keptList, 1, value)
end


---Creates a new dice roller.
---@param args Args.Roller? Arguments for creation of the roller.
---@return DiceRoller
function Roller:new(args)
    local this = core.new(self)

    local maxRolls = args and args.maxRolls
    if not maxRolls or maxRolls >= 0 then
        this._maxRolls = maxRolls or 200
    end

    this._rolls = 0
    this._parser = args and args.parser
    this._globalVars = args and args.variables or {}

    this._cache = Cache:new({
        capacity = 256,
        primaryKey = 'key',
        lru = true,
    })

    this._evaluators = {
        BinOp = self._evalBinOp,
        Dice = self._evalDice,
        Literal = self._evalLiteral,
        Parenthetical = self._evalParenthetical,
        Set = self._evalSet,
        UnOp = self._evalUnOp,
        Identifier = self._evalIdentifier,
    }

    this._operators = {
        k = self._opKeep,
        p = self._opDrop,

        -- dice only
        rr = self._opReroll,
        ro = self._opRerollOnce,
        ra = self._opExplodeOnce,
        e = self._opExplode,
        mi = self._opMinimum,
        ma = self._opMaximum,
    }

    this._selectors = {
        l = self._selectLowestN,
        h = self._selectHighestN,
        ['<'] = self._selectLessThan,
        ['>'] = self._selectGreaterThan,
    }

    return this
end


return Roller

--#region Type Definitions

---@class Args.Roller
---@field maxRolls? integer The maximum rolls the roller should perform before throwing an error.
---Defaults to `200`. A value of `-1` indicates no maximum.
---@field parser? DiceParser The parser to use.
---@field variables? table<string, number> Variables that can be referenced in expressions.
---This will have no effect if the parser in use does not allow identifiers.

---@class Args.Roll
---@field advantage AdvType? The type of advantage to apply. Defaults to no advantage.
---@field stringifier Stringifier? The stringifier to use for the result. Defaults to `RichTextStringifier`.
---@field variables? table<string, number> Variables that can be referenced in the roll's expression.
---This will have no effect if the parser in use does not allow identifiers.
---@field getVariable? fun(name: string): number? Callback used to get the value of a variable.
---This takes precedence over `variables`. If this returns `nil`, `variables` will be checked, then global variables.

--#endregion
