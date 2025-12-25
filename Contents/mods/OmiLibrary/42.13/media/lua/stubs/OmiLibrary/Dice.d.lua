---Types for dice parsing and rolling.
---@meta _
---@namespace omi.dice
---@using omi

--#region Helper types

---@class CacheData
---@field key string
---@field expression AST.Expression

---@class Selector
---@field type? SelectorType The selector type, or `nil` for an exact number.
---@field value integer The number value for the selector.

---@class Operation<TOperator : string>
---@field type TOperator The operation type.
---@field selectors Selector[] Selectors for the operation.

---@alias Expression
---| Literal
---| UnaryOp
---| BinaryOp
---| Dice
---| Die
---| DiceSet
---| Parenthetical
---| Identifier
---| RollExpression

---@alias ExpressionType
---| 'Literal'
---| 'UnaryOp'
---| 'BinaryOp'
---| 'Dice'
---| 'Die'
---| 'DiceSet'
---| 'Parenthetical'
---| 'Identifier'
---| 'RollExpression'

---@alias OperatedExpression
---| Dice
---| DiceSet
---| Parenthetical

---@alias SetOperator
---| 'k' (keep) Keeps all matched values
---| 'p' (drop) Drops all matched values

---@alias DiceOperator
---| 'rr' (reroll) Rerolls matched values until none match
---| 'ro' (reroll once) Rerolls matched values once
---| 'ra' (reroll and add) Rerolls up to one matched value once & keeps original roll (i.e., explode once)
---| 'e'  (explode on) Rolls another die for each matched value
---| 'mi' (minimum) Minimum value for each die
---| 'ma' (maximum) Maximum value for each die
---| SetOperator

---@alias SelectorType
---| 'l' Lowest
---| 'h' Highest
---| '<' Less than
---| '>' Greater than

---@alias ComparisonOperator
---| '<'
---| '>'
---| '=='
---| '>='
---| '<='
---| '!='

---@alias BinaryOperator
---| '+'
---| '-'
---| '*'
---| '/'
---| '//'
---| '%'
---| ComparisonOperator

---@alias UnaryOperator
---| '-'
---| '+'

---@alias DiceEvaluator fun(self: DiceRoller, node: AST.Expression): Expression?, DiceRollError?

---@alias DiceOperation fun(self: DiceRoller, expr: OperatedExpression, sels: Selector[]): DiceRollError?

---@alias SelectorFunction fun(self: DiceRoller, expr: Expression, value: integer): Expression[]

---@alias StringifyFunction fun(self: dice.Stringifier, expr: Expression): string

--#endregion

--#region AST types

---@class AST.BaseNode : ParseNode
---@field range [integer, integer] The start and stop range of the node as a 2-element array.

---@class AST.HasAnnotations
---@field annotations string[] Annotations for the node.

---@class AST.HasOperations<TOperator : string>
---@field operations Operation<TOperator>[] Operations for the node.

---A unary operation.
---@class AST.UnOp : AST.BaseNode
---@field type 'UnOp' The type of the node.
---@field op UnaryOperator The operation type.
---@field value AST.Expression The value node of the operation.

---A binary operation.
---@class AST.BinOp : AST.BaseNode
---@field type 'BinOp' The type of the node.
---@field op BinaryOperator The operation type.
---@field left AST.Expression The left node of the operation.
---@field right AST.Expression The right node of the operation.

---A literal integer or decimal.
---@class AST.Literal : AST.BaseNode, AST.HasAnnotations
---@field type 'Literal' The type of the node.
---@field value number The literal value.

---An identifier expression.
---@class AST.Identifier : AST.BaseNode, AST.HasAnnotations
---@field type 'Identifier' The type of the node.
---@field name string The identifier value.

---A dice expression.
---@class AST.Dice : AST.BaseNode, AST.HasAnnotations, AST.HasOperations<DiceOperator>
---@field type 'Dice' The type of the node.
---@field count integer? The number of dice to roll. Defaults to `1`.
---@field size integer | '%' The die value, or '%' for a percentile dice.

---A set of expressions.
---@class AST.Set : AST.BaseNode, AST.HasAnnotations, AST.HasOperations<SetOperator>
---@field type 'Set' The type of the node.
---@field values AST.Expression[] The expressions in the set.

---An expression inside a set of parentheses.
---@class AST.Parenthetical : AST.BaseNode, AST.HasAnnotations, AST.HasOperations<SetOperator>
---@field type 'Parenthetical' The type of the node.
---@field value AST.Expression The value within the parentheses.


---@alias AST.NumberExpression
---| AST.Literal
---| AST.Dice
---| AST.Set
---| AST.Parenthetical
---| AST.Identifier

---@alias AST.Expression
---| AST.UnOp
---| AST.BinOp
---| AST.NumberExpression

--#endregion
