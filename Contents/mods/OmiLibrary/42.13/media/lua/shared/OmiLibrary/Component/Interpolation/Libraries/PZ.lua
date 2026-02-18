---Contains interpolation functions specific to Project Zomboid.
---@namespace omi

local Helpers = require 'OmiLibrary/Component/Interpolation/Libraries/Helpers'

---@class(partial) interpolate.libraries
local Libraries = require 'OmiLibrary/Component/Interpolation/Libraries/Core'


---@class interpolate.libraries.Translate
local PZLib = {}


---Returns the access level of the given player.
---@param _ Interpolator Unused.
---@param playerNum string?
---@return string
PZLib.AccessLevel = function(_, playerNum)
    local index = tonumber(playerNum) or 0
    local player = getSpecificPlayer(index --[[@as integer]])
    return player and player:getAccessLevel() or 'none'
end

---Gets the translation with the given ID.
---Additional arguments up to 4 are passed as translation substitutions.
---@type fun(interpolator: Interpolator, id: any, ...: any): string
PZLib.GetText = Helpers.argsToStrings(getText, 5)

---Gets the translation with the given ID. If the string is not found, returns `nil`.
---Additional arguments up to 4 are passed as translation substitutions.
---@type fun(interpolator: Interpolator, id: any, ...: any): string?
PZLib.GetTextOrNull = Helpers.argsToStrings(getTextOrNull, 5)


Libraries.pz = PZLib
return PZLib
