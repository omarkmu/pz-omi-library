# Changelog

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
