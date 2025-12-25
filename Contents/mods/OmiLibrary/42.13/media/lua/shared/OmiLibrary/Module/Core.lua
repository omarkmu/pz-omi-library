---Core library modules and utilities.
---@namespace omi

---@class(partial) core
local core = require 'OmiLibrary/Module/Utils'


---Contains functionality related to sets.
---When called as a function, creates a new set.
core.set = require 'OmiLibrary/Module/Set'

---Contains utilities for encoding and decoding JSON values.
core.json = require 'OmiLibrary/Module/JSON'

---Contains components and utilities related to caches.
core.cache = require 'OmiLibrary/Module/Cache'

---Contains utilities related to colors.
core.color = require 'OmiLibrary/Module/Color'

---Contains utilities related to dice expressions.
core.dice = require 'OmiLibrary/Module/Dice'

---Contains utilities for creating and invoking callbacks with context.
---When called as a function, builds a calback info object.
core.callback = require 'OmiLibrary/Module/Callback'

---Contains utilities for creation of configuration based on a schema.
---When called as a function, creates a new configuration helper.
core.configuration = require 'OmiLibrary/Module/Configuration'

---Contains utilities for dispatching and receiving commands.
---When called as a function, creates a new dispatcher.
core.dispatch = require 'OmiLibrary/Module/Dispatch'

---Contains functionality for string interpolation.
---When called as a function, performs string interpolation.
core.interpolate = require 'OmiLibrary/Module/Interpolation'

---Contains utilities for localization.
core.l10n = require 'OmiLibrary/Module/L10N'

---Contains utilities for creating configuration schemas.
---When called as a function, creates a new schema.
core.schema = require 'OmiLibrary/Module/Schema'


---Helper component for creating lists from delimited strings.
core.DelimitedList = require 'OmiLibrary/Component/Core/DelimitedList'

---Immutable set of key-value entries which permits multiple entries with the same key.
core.MultiMap = require 'OmiLibrary/Component/Core/MultiMap'

---Component for invoking callbacks after a delay.
core.Scheduler = require 'OmiLibrary/Component/Core/Scheduler'

---Component for logging messages with different log levels.
core.Logger = require 'OmiLibrary/Component/Logging/Logger'

---Base string parser component.
core.Parser = require 'OmiLibrary/Component/Core/Parser'


return core
