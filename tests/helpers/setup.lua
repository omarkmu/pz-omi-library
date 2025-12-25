---Runs before tests to set up assertions.
---@using omi
---@using omi.l10n

local util = require 'luassert.util'
local helpers = require 'zombusted.helpers'

local interpolate ---@type interpolate

---Container for custom assertions.
local Assertions = {}

---Determines whether a junk node matching the given code exists.
---@param res AST.Resource
---@param code string
---@return boolean isMatch
---@return string[]? seenCodes
local function hasMatchingJunkNode(res, code)
    local codes = {}

    for i = 1, #res.body do
        local node = res.body[i]
        if node.type == 'Junk' then
            ---@cast node AST.Junk
            local annot = node.annotations[1]
            local annotCode = annot and annot.code or 'nil'
            if annotCode == code then
                return true
            end

            codes[#codes + 1] = annotCode
        end
    end

    if #codes == 0 then
        return false
    end

    return false, codes
end

---Checks for class membership. Copied from core utilities.
---@see core.isinstance
---@param obj any
---@param cls any
---@return boolean
local function isinstance(obj, cls)
    if not cls or type(obj) ~= 'table' then
        return false
    end

    local seen = {}
    local meta = getmetatable(obj)
    while meta and not seen[meta] do
        if type(meta) ~= 'table' then
            return false
        end

        if rawget(meta, '__index') == cls then
            return true
        end

        seen[meta] = true
        meta = getmetatable(meta)
    end

    return false
end

---Custom assertion for checking for a Fluent parse error with a matching code.
---@param state table
---@param args table
---@param level integer
---@return boolean
function Assertions.fluent_error_code(state, args, level)
    level = level + 1
    local name = 'fluent_error_code'
    helpers.argCount(2, args.n, name, level)

    ---@type AST.Resource
    local resource = helpers.argIsTable(args[1], 1, name, level, 'Resource node')
    assert(type(resource.body) == 'table', helpers.badArg(resource, 1, name, 'Resource node'))

    local code = helpers.argIsString(args[2], 2, name, level)
    helpers.setFailureMessage(state, args[3])

    local found, seenCodes = hasMatchingJunkNode(resource, code)

    args.nofmt = args.nofmt or {}
    args.nofmt[1] = true
    args.nofmt[2] = true

    local seenErrors
    if not seenCodes then
        seenErrors = 'no errors'
    elseif #seenCodes == 1 then
        seenErrors = 'error code ' .. seenCodes[1]
    else
        seenErrors = 'error codes: ' .. table.concat(seenCodes, ', ')
    end

    args[1] = 'Resource with ' .. seenErrors
    args[2] = 'Resource with error code ' .. code

    return found
end

---Custom assertion for checking the class membership of `obj`.
---@param args table
---@param level integer
---@return boolean
function Assertions.instance(_, args, level)
    level = level + 1
    helpers.argCount(2, args.n, 'instance', level)

    local obj = args[1]
    local cls = args[2]
    helpers.setFailureMessage(util.tremove(args, 3))

    -- avoid __tostring on class tables
    local clsString
    local clsMt = debug.getmetatable(cls)
    if clsMt then
        local success

        debug.setmetatable(cls, nil)
        success, clsString = pcall(tostring, cls)
        debug.setmetatable(cls, clsMt)

        if not success then
            clsString = ''
        end
    else
        clsString = tostring(cls)
    end

    args.nofmt = args.nofmt or {}
    args.nofmt[2] = true
    args[2] = '(class) ' .. clsString

    return isinstance(obj, cls)
end

---Custom assertion to check whether the result of interpolation matches an expected value.
---@param state table
---@param args table
---@param level integer
---@return boolean
function Assertions.interpolate_match(state, args, level)
    level = level + 1

    local argCount = args.n
    helpers.argCount(2, argCount, 'interpolate_match', level)

    local pattern = helpers.argIsString(args[1], 1, 'interpolate_match', level)
    local expected = tostring(args[2])

    local tokensIdx = 3
    local optionsIdx = 4
    local msg
    for i = 3, argCount do
        if args[i] and type(args[i]) ~= 'table' then
            if i == 3 then
                tokensIdx = 4
                optionsIdx = 5
            elseif i == 4 then
                tokensIdx = 3
                optionsIdx = 5
            end

            msg = util.tremove(args, i)
            break
        end
    end

    local tokens = helpers.argIsTableOrNil(args[3], tokensIdx, 'interpolate_match', level)
    local options = helpers.argIsTableOrNil(args[4], optionsIdx, 'interpolate_match', level)

    helpers.setFailureMessage(state, msg)
    util.tremove(args, 3)
    util.tremove(args, 4)

    interpolate = interpolate or require 'OmiLibrary/Module/Interpolation'
    local interpolator = interpolate.Interpolator:new(options)
    local result = interpolator:interpolate(pattern, tokens)

    args.nofmt = args.nofmt or {}
    args.nofmt[1] = true
    args[1] = string.format('%q', args[1])

    util.tinsert(args, 2, result)

    return result == expected
end


return function(...)
    require 'zombusted' (...)

    for k, v in pairs(Assertions) do
        helpers.register(k, v)
    end

    local s = require 'say'
    s:set_namespace('en')

    s:set('assertion.fluent_error_code.positive',
        'Expected Junk node with matching error code.\nPassed in:\n%s\nExpected:\n%s')
    s:set('assertion.fluent_error_code.negative',
        'Expected no Junk node with matching error code.\nPassed in:\n%s\nDid not expect:\n%s')

    s:set('assertion.instance.positive',
        'Expected object to be an instance of class.\nPassed in:\n%s\nExpected:\n%s')
    s:set('assertion.instance.negative',
        'Expected object to not be an instance of class.\nPassed in:\n%s\nDid not expect:\n%s')

    s:set('assertion.interpolate_match.positive',
        'Expected interpolation of %s to yield expected result.\nResult:\n%s\nExpected:\n%s')
    s:set('assertion.interpolate_match.negative',
        'Expected interpolation of %s to yield a different result.\nResult:\n%s\nDid not expect:\n%s')

    return true
end
