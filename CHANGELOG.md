# Changelog

## 0.5.0

### Added
- Added utility functions for getting the current game version and comparing with it
- Added flag to `SimpleStringifier` for whether the rolled value should be included

## 0.4.0

### Added
- Added locale tag corrections for new languages
- Added `utils.ui.injectSandboxPage`, for adding pages to the sandbox menu
- Added support for now-unbounded `getText`
- Added support for higher UI scales

### Changed
- Updated `json.tryRead` to always default `create` to false
- Updated component UI types to default `keepOnScreen` to false
- Updated `ConfigurationHelper:loadFile` to accept an options table as an argument

### Fixed
- Fixed rich text panel sometimes not including scrollbar
- Fixed dialogs extending beyond screen size
- Fixed Die objects failing to convert back from network tables

## 0.3.0

### Added
- Added `targetSelf` parameter for functions with callbacks
    - This is a shortcut for setting the `target` parameter to the created instance.
- Added mod-specific L10N helpers to proxy tables
- Added `UI.initListBox` function
- Added `core.writeFile` function

### Changed
- Renamed `Topic` to `Channel` in dispatch module
- Renamed files to reduce repeated `Core.lua` filenames
- Moved files to `src` folder
    - The expectation is that the Contents subfolders are symlinked for local development.
- Updated to latest CLDR data
- MultiMaps now throw an error when given an invalid entry table

### Removed
- Removed `core.getClassFieldByName` (relied on removed Reflection features)
- Removed `l10n.setText` (relied on removed Reflection features)
- Removed features related to mod ID backslash

## 0.2.0

### Added
- Added `schema.fromJsonFile` helper to generate a schema from a JSON file
    - Like forms, top-level properties currently can only be objects.
- Added `onSingleplayerSend` callback for dispatch topics
    - This is called instead of `onClientSend` or `onServerSend`, if specified.
- Added export of base error type (for `FluentParseError`, `DiceParseError`, and `DiceRollError`)
- Added `getVariable` callback to `Roller.tryRoll`

### Changed
- Improved handling for singleplayer in `dispatch` module
- Moved `schema.read` to `json` module and renamed it to `tryReadObject`
- Renamed `paddingTop` and `paddingBottom` form rules to `padTop` and `padBottom`
- Renamed `KR_PARTICLE` and `KR_WITH_PARTICLE` Fluent built-in functions to `KO_PARTICLE` and `KO_WITH_PARTICLE`
    - This is to better match the locale name, `ko`.
- Changed `l10n.setText` to detect the string category from the key
    - The `category` parameter was removed due to this.
- Changed default primary key of `PlayerCache` to `onlineID` (instead of `username`)
- Changed interpolation strings to only interpret escapes for backticks within backtick-delimited strings

### Fixed
- Fixed an issue preventing added `ListEntry` values from being included in the list
- Fixed `pretty` argument to `configuration.new` only defaulting to `true` in debug mode
- Fixed `GETTEXT` Fluent built-in function passing the string ID as an argument

## 0.1.0
- Initial beta release
