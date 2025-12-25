---Contains mixins with functionality that can be added to various elements.
---@namespace omi

---@class mixin
local Mixin = {}


---Mixin with functionality to perform events when destroying an element.
Mixin.Destroyable = require 'OmiLibrary/Component/UI/Mixin/Destroyable'

---Mixin with functionality for scrolling within an element.
Mixin.Scrollable = require 'OmiLibrary/Component/UI/Mixin/Scrollable'


return Mixin
