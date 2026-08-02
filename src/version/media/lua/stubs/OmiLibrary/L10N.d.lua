---Localization types.
---@meta _
---@namespace omi.l10n
---@using omi

--#region Helper types

---@alias FluentFunction fun(positional: FluentValue[], named: table<string, FluentValue>, resolver: FluentResolver): FluentValue

---@alias FluentValue FluentType<any> | string

---@alias FluentVariable
---| FluentValue
---| number
---| string
---| Date
---| LocalDateTime

--#endregion

--#region Fluent parsed types

---@class fluent.Message
---@field id string The message or term identifier.
---@field value? fluent.Pattern The message or term value.
---@field attributes table<string, fluent.Pattern> Associates attribute names to their values.

---@class fluent.Variant
---@field key fluent.Literal The variant key.
---@field value fluent.Pattern The variant value.

---@class fluent.SelectExpression
---@field type 'select' The expression type.
---@field selector fluent.Expression The variant selector expression.
---@field variants fluent.Variant[] The selector variants.
---@field defaultIndex integer The index of the default variant.

---@class fluent.VariableReference
---@field type 'var' The expression type.
---@field name string The variable name.

---@class fluent.TermReference
---@field type 'term' The expression type.
---@field name string The name of the referenced term.
---@field attr? string The name of the referenced term attribute.
---@field args (fluent.Expression | fluent.NamedArgument)[] The arguments for the parameterized term.

---@class fluent.MessageReference
---@field type 'message' The expression type.
---@field name string The name of the referenced message.
---@field attr? string The name of the referenced message attribute.

---@class fluent.FunctionReference
---@field type 'func' The expression type.
---@field name string The name of the referenced functon.
---@field args (fluent.Expression | fluent.NamedArgument)[] The arguments for the function.

---@class fluent.StringLiteral
---@field type 'str' The expression type.
---@field value string The string value.

---@class fluent.NumberLiteral
---@field type 'num' The expression type.
---@field value number The value of the number.
---@field precision integer The minimum number of fraction digits for the number.

---@class fluent.NamedArgument
---@field type 'namedArg' The expression type.
---@field name string The argument name.
---@field value fluent.Literal The argument value.


---@alias fluent.Pattern string | fluent.ComplexPattern

---@alias fluent.ComplexPattern fluent.PatternElement[]

---@alias fluent.PatternElement string | fluent.Expression

---@alias fluent.Literal
---| fluent.StringLiteral
---| fluent.NumberLiteral

---@alias fluent.Expression
---| fluent.SelectExpression
---| fluent.VariableReference
---| fluent.TermReference
---| fluent.MessageReference
---| fluent.FunctionReference
---| fluent.Literal

--#endregion

--#region Fluent resolution types

---@class fluent.DateTimeFormatOptions
---@field dateStyle? DateTimeFormatStyle The style to use for date formatting. Defaults to `short` if `timeStyle` is not provided.
---@field timeStyle? DateTimeFormatStyle The style to use for time formatting. Defaults to none.

---@class fluent.NumberFormatOptions
---@field minimumFractionDigits? integer The minimum fraction digits to include in the stringified number.
---@field maximumFractionDigits? integer The maximum fraction digits to include in the stringified number.

---@class fluent.PluralRulesOptions : fluent.NumberFormatOptions
---@field type? PluralRuleType The type of number to use for pluralization.

--#endregion

--#region AST types

---@class AST.Node : ParseNode
---@field type FluentNodeType The type of the node.

---@class AST.Resource : AST.Node
---@field body AST.Entry[] The entries of the resource.
---@field source string The source text.

---@class AST.Message : AST.Node
---@field type 'Message' The type of the node.
---@field id AST.Identifier The identifier for the message.
---@field value? AST.Pattern The value of the message.
---@field attributes AST.Attribute[] Attributes of the message.
---@field comment? AST.Comment The comment attached to the message.

---@class AST.Term : AST.Node
---@field type 'Term' The type of the node.
---@field id AST.Identifier The identifier for the term.
---@field value AST.Pattern The value of the term.
---@field attributes AST.Attribute[] Attributes of the term.
---@field comment? AST.Comment The comment attached to the message.

---@class AST.Identifier : AST.Node
---@field type 'Identifier' The type of the node.
---@field name string The identifier name.

---@class AST.Attribute : AST.Node
---@field type 'Attribute' The type of the node.
---@field id AST.Identifier The identifier for the attribute.
---@field value AST.Pattern The value of the attribute.

---@class AST.Pattern : AST.Node
---@field type 'Pattern' The type of the node.
---@field elements AST.PatternElement[] Elements of the pattern.

---@class AST.TextElement : AST.Node
---@field type 'TextElement' The type of the node.
---@field value string The text contents.

---@class AST.Placeable : AST.Node
---@field type 'Placeable' The type of the node.
---@field expression AST.Expression The placeable expression.

---@class AST.SelectExpression : AST.Node
---@field type 'SelectExpression' The type of the node.
---@field selector AST.InlineExpression The selector expression.
---@field variants AST.Variant[] Variants for the selector.

---@class AST.Variant : AST.Node
---@field type 'Variant' The type of the node.
---@field key AST.Identifier | AST.NumberLiteral The key of the variant.
---@field value AST.Pattern The pattern of the variant.
---@field default boolean Flag for whether the variant is the default variant.

---@class AST.BaseLiteral : AST.Node
---@field value string The value of the literal.

---@class AST.StringLiteral : AST.BaseLiteral
---@field type 'StringLiteral' The type of the node.

---@class AST.NumberLiteral : AST.BaseLiteral
---@field type 'NumberLiteral' The type of the node.

---@class AST.FunctionReference : AST.Node
---@field type 'FunctionReference' The type of the node.
---@field id AST.Identifier The identifier.
---@field arguments AST.CallArguments Arguments for the function call.

---@class AST.MessageReference : AST.Node
---@field type 'MessageReference' The type of the node.
---@field id AST.Identifier The identifier of the message.
---@field attribute? AST.Identifier The identifier of the message attribute.

---@class AST.TermReference : AST.Node
---@field type 'TermReference' The type of the node.
---@field id AST.Identifier The identifier of the term.
---@field attribute? AST.Identifier The identifier of the term attribute.
---@field arguments? AST.CallArguments Arguments to provide to the term.

---@class AST.VariableReference : AST.Node
---@field type 'VariableReference' The type of the node.
---@field id AST.Identifier The identifier of the variable.

---@class AST.CallArguments : AST.Node
---@field type 'CallArguments' The type of the node.
---@field positional AST.InlineExpression[] Positional arguments for the function.
---@field named AST.NamedArgument[] Named arguments for the function.

---@class AST.NamedArgument : AST.Node
---@field type 'NamedArgument' The type of the node.
---@field name AST.Identifier The argument name.
---@field value AST.Literal The value to pass for the argument.

---@class AST.Junk : AST.Node
---@field type 'Junk' The type of the node.
---@field content string The content of the junk node.
---@field annotations AST.Annotation[] Errors that occurred.

---@class AST.Annotation : AST.Node
---@field type 'Annotation' The type of the node.
---@field code string The error code.
---@field arguments any[] Arguments for the error message.
---@field message string The error message.

---@class AST.BaseComment : AST.Node
---@field content string The content of the comment.

---@class AST.Comment : AST.BaseComment
---@field type 'Comment' The type of the node.

---@class AST.GroupComment : AST.BaseComment
---@field type 'GroupComment' The type of the node.

---@class AST.ResourceComment : AST.BaseComment
---@field type 'ResourceComment' The type of the node.

---@class AST.Indent
---@field type 'Indent' The identifier of the indent.
---@field value string The indent string. This is made up of spaces.
---@field range [integer, integer] The range of the indent.

---@alias AST.Comments
---| AST.Comment
---| AST.GroupComment
---| AST.ResourceComment

---@alias AST.Literal
---| AST.StringLiteral
---| AST.NumberLiteral

---@alias AST.PatternElement
---| AST.TextElement
---| AST.Placeable

---@alias AST.Expression
---| AST.InlineExpression
---| AST.SelectExpression

---@alias AST.InlineExpression
---| AST.StringLiteral
---| AST.NumberLiteral
---| AST.FunctionReference
---| AST.MessageReference
---| AST.TermReference
---| AST.VariableReference
---| AST.Placeable

---@alias AST.Entry
---| AST.Message
---| AST.Term
---| AST.Comments
---| AST.Junk

--#endregion
