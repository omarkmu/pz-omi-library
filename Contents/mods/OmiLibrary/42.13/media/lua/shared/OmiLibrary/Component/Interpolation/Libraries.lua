---Built-in interpolator function libraries.
---@namespace omi

---@class(partial) interpolate.libraries
local Libraries = require 'OmiLibrary/Component/Interpolation/Libraries/Core'

require 'OmiLibrary/Component/Interpolation/Libraries/Math'
require 'OmiLibrary/Component/Interpolation/Libraries/Boolean'
require 'OmiLibrary/Component/Interpolation/Libraries/String'
require 'OmiLibrary/Component/Interpolation/Libraries/Map'
require 'OmiLibrary/Component/Interpolation/Libraries/Mutate'
require 'OmiLibrary/Component/Interpolation/Libraries/PZ'


return Libraries
