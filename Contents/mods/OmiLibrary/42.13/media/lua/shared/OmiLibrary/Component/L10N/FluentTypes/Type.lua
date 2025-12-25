---Wrapped type for use in Fluent messages.
---@namespace omi.l10n
---@using omi
---@using omi.l10n.fluent

local core = require 'OmiLibrary/Module/Utils'

---@class FluentType<T> : Class
---@field value T The wrapped value.
local FluentType = core.class('FluentType')


---Format function to convert the value into a string.
---@return string converted
function FluentType:convert()
    return tostring(self.value)
end


---Converts the type into a string.
---@protected
function FluentType:__tostring()
    return self:convert()
end

---Creates a `FluentType` instance.
---@generic T
---@param value T The initial value.
---@return FluentType<T>
---@protected
function FluentType:new(value)
    local this = core.new(self)

    this.value = value or '???'

    return this
end


return FluentType
