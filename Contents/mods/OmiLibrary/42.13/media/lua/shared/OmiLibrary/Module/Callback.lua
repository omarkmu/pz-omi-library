---Helpers for creating and invoking callbacks with context.
---@namespace omi

local select = select
local unpack = unpack
local pcall = pcall

---@class callback
---@overload fun(target: any, f: function?, ...: any): CallbackInfo?
local callback = {}


---Builds a callback info object.
---@param target any? The first argument to pass to the callback function.
---@param cb function? The callback function.
---@param ...any Callback arguments.
---@return CallbackInfo?
function callback.create(target, cb, ...)
    if not cb then
        return
    end

    local args = { n = select('#', ...) }
    for i = 1, args.n do
        args[i] = select(i, ...)
    end

    ---@type CallbackInfo
    local info = {
        target = target,
        callback = cb,
        args = args,
    }

    return info
end

---Invokes a callback given an info table.
---@param info CallbackInfo? The callback info object.
---@param ...any Prefix arguments to include after the target and before the callback arguments.
---@return any...
function callback.invoke(info, ...)
    if not info or not info.callback then
        return
    end

    local count = select('#', ...)
    if count == 0 then
        -- no prefix args → just invoke with info args
        return info.callback(info.target, unpack(info.args, 1, info.args.n))
    end

    local args = {}
    for i = 1, count do
        args[i] = select(i, ...)
    end

    local infoArgs = info.args
    for i = 1, infoArgs.n do
        count = count + 1
        args[count] = infoArgs[i]
    end

    return info.callback(info.target, unpack(args, 1, count))
end

---Invokes a callback given an info table, suppressing errors.
---@param info CallbackInfo? The callback info object.
---@param ...any Prefix arguments to include after the target and before the callback arguments.
---@return boolean success
---@return any...
function callback.safeInvoke(info, ...)
    return pcall(callback.invoke, info, ...)
end


setmetatable(callback, { __call = function(self, ...) return self.create(...) end })
return callback

--#region Type Definitions

---@class CallbackInfo
---@field target? any The first argument to pass to the callback function.
---@field callback? function The function to call when invoking the callback.
---@field args table Additional arguments to pass to the callback function.

--#endregion
