# OmiLibrary

OmiLibrary is a library mod for [Project Zomboid](https://projectzomboid.com) that adds various utilities for use in other mods.

This was primarily developed for my own use, but anyone can use it as a dependency.
If you intend to do so, keep in mind that the API is not to be considered stable yet; things may change depending on my needs.

## Features

> [!NOTE]
> There is currently no external documentation (this will change in the future).
> There are documentation comments for all public functions.
> If something is unclear, create an issue or just ask me on Discord (@omiyomy)—you can find me in the official PZ Discord or the unofficial PZ modding Discord.

### Modules

- `cache`: Cache helpers. Includes generic cache and player cache components.
- `callback`: Utilities for creating callbacks with argument context tables.
- `color`: Utilities for working with RGB and RGBA color tables.
- `configuration`: Helper for creating a configuration object based on a schema.
    - This is intended primarily as a replacement for sandbox options, but can be used for anything.
    It supports complex objects and saving to (and loading from) files or mod data.
- `dice`: Dice parsing and rolling, based on [d20](https://github.com/avrae/d20).
- `dispatch`: Utilities and components for handling server and client commands.
- `interpolate`: String interpolation, including tokens and functions.
    - The [documentation](https://omarkmu.github.io/pz-omichat/format-strings/index.html) for OmiChat has an explanation of the syntax.
    Not all of the functions listed there are in the library by default, but most are.
- `json`: JSON helpers, based on [rxi/json](github.com/rxi/json.lua). Includes utilities and components for encoding and decoding.
- `l10n`: Utilities for localization, including support for [Fluent](https://projectfluent.org) translation files.
    - This is intended to replace the vanilla translation system for most uses. It cannot replace all of them.
    - It also includes a `setText` function, which sets the value of a vanilla translation. If a translation is retrieved before this is called, there's no way to alter its value.
- `schema`: Contains utilities for creating schemas.
    - This is primarily useful when used with the `configuration` module.
    It can also be used with the `forms` UI module to generate a form UI that can save to a corresponding table.
- `set`: Basic set functionality. Includes `Set` and `OrderedSet` components, and a utility function for creating a set table (a table associating items to `true`).

### Client-only modules

- `chat`: Includes a few utility functions for working with chat and for checking for the presence of [OmiChat](https://github.com/omarkmu/pz-omichat).
- `ui`: Various UI components, including an extended rich text panel. Most are analogous to existing vanilla components.

### Other components

- `DelimitedList`: Helper for creating self-updating delimited lists.
- `MultiMap`: Set of key-value entries that permits multiple entries with the same key. Used for interpolation.
- `Scheduler`: component used for the `setTimeout`, `setInterval`, and `setIntervalUI` utility functions.
- `Logger`: component for logging messages of varying severity levels.
- `Parser`: base string parser component.

## Usage

The library contains various modules that are included in the parent `OmiLibrary` module (or `OmiLibrary/Client`, for client modules).

To use them, require the parent module. For example:

```lua
local lib = require 'OmiLibrary'

lib.setTimeout(1000, function(args)
    print(lib.interpolate('Hello $greeted', args))
end, { greeted = 'world' })
```

For client-only modules, require `OmiLibrary/Client` instead.
You can also require specific modules or components, but the internal structure of the library is subject to change.

This project also includes unit tests.
To run them, install [zombusted](https://github.com/omarkmu/zombusted) and use the `busted` command.
