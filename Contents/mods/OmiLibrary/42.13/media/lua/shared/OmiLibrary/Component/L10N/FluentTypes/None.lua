---Fluent type representing no correct value.
---@namespace omi.l10n
---@using omi
---@using omi.l10n.fluent

local core = require 'OmiLibrary/Module/Utils'
local FluentType = require 'OmiLibrary/Component/L10N/FluentTypes/Type'

---@class FluentNone : FluentType<string>
local FluentNone = FluentType:derive('FluentNone')


---Creates an instance of `FluentNone` with the given fallback value.
---@param value string? The fallback value. Defaults to `???`.
---@return FluentNone
function FluentNone:new(value)
    return core.new(self, FluentType.new, value or '???')
end


return FluentNone
