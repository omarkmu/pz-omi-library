---Type stub for custom assertions.
---@meta _
---@using omi
---@using omi.l10n

---@class(partial) luassert.internal.assert
local internal = {}


---Asserts that a Fluent resource contains a matching Junk node.
---@param res AST.Resource The resource to check.
---@param code string The expected error code.
---@param msg string? The failure message.
function internal.has_fluent_error_code(res, code, msg) end

---Asserts that interpolation of a string results in the expected value.
---@param pattern string The interpolation pattern.
---@param expected any The expected value. This is converted to a string.
---@param tokens table? Tokens for the interpolation.
---@param options InterpolationOptions? Options for the interpolation.
---@param msg string? The failure message.
---@overload fun(pattern: string, expected: any, msg: string, tokens?: table, options?: InterpolationOptions)
---@overload fun(pattern: string, expected: any, tokens: table, msg: string, options?: InterpolationOptions)
function internal.interpolate_match(pattern, expected, tokens, options, msg) end

---Asserts that an object is an instance of a class.
---@param obj any The object to check.
---@param cls any The expected class.
---@param msg string? The failure message.
function internal.is_instance(obj, cls, msg) end

---Asserts that an object is not an instance of a class.
---@param obj any The object to check.
---@param cls any The class to check against.
---@param msg string? The failure message.
function internal.is_not_instance(obj, cls, msg) end
