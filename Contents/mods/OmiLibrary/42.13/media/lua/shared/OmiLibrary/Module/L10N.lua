---Contains localization utilities and components.
---@namespace omi
---@using omi.l10n
---@using omi.l10n.fluent

local core = require 'OmiLibrary/Module/Utils'
local Logger = require 'OmiLibrary/Component/Logging/Logger'
local log = require 'OmiLibrary/Component/Logging/LibraryLogger'

local concat = table.concat
local getFileReader = getFileReader
local getModFileReader = getModFileReader


---@class l10n : l10n.core
local L10N = require 'OmiLibrary/Module/Core/L10N'

---Parser for the `.ftl` syntax.
L10N.FluentParser = require 'OmiLibrary/Component/L10N/FluentParser'

---Structure for storing localization entries.
L10N.FluentResource = require 'OmiLibrary/Component/L10N/FluentResource'

---Stores and resolves localization messages.
L10N.FluentBundle = require 'OmiLibrary/Component/L10N/FluentBundle'

---Base fluent wrapper type.
L10N.FluentType = require 'OmiLibrary/Component/L10N/FluentTypes/Type'

---Fluent wrapper type for dates.
L10N.FluentDateTime = require 'OmiLibrary/Component/L10N/FluentTypes/DateTime'

---Fluent wrapper type for numbers.
L10N.FluentNumber = require 'OmiLibrary/Component/L10N/FluentTypes/Number'

---Fluent wrapper type for an invalid value.
L10N.FluentNone = require 'OmiLibrary/Component/L10N/FluentTypes/None'

---Associates names to named bundles.
---@type table<string, FluentBundle?>
---@private
L10N._bundles = {}

---Shared parser instance.
---@private
---@readonly
L10N._parser = L10N.FluentParser:new()


---Adds a resource to the global bundle.
---If the resource specifies a bundle, it will be added to that bundle instead.
---@param resource FluentResource The resource to add.
---@param options Args.AddResource? Additional options for adding the resource.
---@return FluentBundle bundle The bundle the resource was added to.
function L10N.addResource(resource, options)
    local bundle
    if resource.global or not resource.bundle then
        bundle = L10N._global
    else
        bundle = L10N.getOrCreateBundle(resource.bundle)
    end

    options = options or {} --[[@as Args.AddResource]]

    bundle:addResource(resource, options.flatten)
    return bundle
end

---Adds an .ftl resource file from a mod directory to the mod's bundle.
---If the loaded resource specifies a bundle, it will be added to that bundle instead.
---@param modId string The fully-qualified ID of the mod to load from.
---@param filename string The name of the file to load.
---@param options Args.AddResource? Options for adding the resource.
---@return FluentResource? resource
---@return FluentBundle? bundle
function L10N.addModResource(modId, filename, options)
    local resource = L10N.loadModResource(modId, filename)
    if not resource then
        return
    end

    return resource, L10N.addResource(resource, options)
end

---Gets the resolved value of a message attribute.
---@param id string The ID of the message.
---@param attr string The name of the attribute to get.
---@param args table<string, FluentVariable?>? Arguments to pass for message resolution.
---@param defaultBundle string? The name of the default bundle to use. Defaults to the global bundle.
---@return string value
function L10N.getAttr(id, attr, args, defaultBundle)
    local result = L10N.getAttrOrNull(id, attr, args, defaultBundle)
    if result then
        return result
    end

    local bundle
    bundle, id = L10N._getBundleAndId(id, defaultBundle)
    if bundle == L10N._global then
        bundle = nil --[[@as FluentBundle?]]
    end

    id = id .. '.' .. attr
    local logger = bundle and bundle.log or log
    local bundleName = bundle and ('bundle ' .. bundle.name) or 'global bundle'
    logger.warn.once('Missing attribute in %s: %s', bundleName, id)

    return id
end

---Gets the resolved value of a message attribute, or `nil` if no such message or attribute exists.
---@param id string The ID of the message.
---@param attr string The name of the attribute to get.
---@param args table<string, FluentVariable?>? Arguments to pass for message resolution.
---@param defaultBundle string? The name of the default bundle to use. Defaults to the global bundle.
---@return string? value
function L10N.getAttrOrNull(id, attr, args, defaultBundle)
    local bundle
    bundle, id = L10N._getBundleAndId(id, defaultBundle)
    if not bundle then
        return
    end

    local message = bundle:getMessage(id)
    local pattern = message and message.attributes[attr]
    if not pattern then
        return
    end

    local result, errors = bundle:formatPattern(pattern, args)
    if errors then
        L10N._logFormatErrors(id .. '.' .. attr, errors, bundle)
    end

    return result
end

---Gets the bundle with the given name, if it exists.
---@param name string The name of the bundle to retrieve.
---@return FluentBundle? bundle
function L10N.getBundle(name)
    return L10N._bundles[name]
end

---Gets the bundle with the given name, creating it if it doesn't exist.
---@param name string The name of the bundle to retrieve.
---@return FluentBundle bundle
function L10N.getOrCreateBundle(name)
    local bundle = L10N._bundles[name]
    if not bundle then
        bundle = L10N.FluentBundle:new({
            name = name,
            logger = name ~= '' and Logger.getOrCreate(name) or nil,
            locale = L10N._localeTag,
        })

        L10N._bundles[name] = bundle
    end

    return bundle
end

---Gets the resolved value of a message.
---@param id string The ID of the message to get.
---@param args table<string, FluentVariable?>? Arguments to pass for message resolution.
---@param defaultBundle string? The name of the default bundle to use. Defaults to the global bundle.
---@return string value
function L10N.getText(id, args, defaultBundle)
    local result = L10N.getTextOrNull(id, args, defaultBundle)
    if result then
        return result
    end

    local bundle
    bundle, id = L10N._getBundleAndId(id, defaultBundle)
    if bundle == L10N._global then
        bundle = nil --[[@as FluentBundle?]]
    end

    local logger = bundle and bundle.log or log
    local bundleName = bundle and ('bundle ' .. bundle.name) or 'global bundle'
    logger.warn.once('Missing message in %s: %s', bundleName, id)

    return id
end

---Gets the resolved value of a message, or `nil` if no such message exists.
---@param id string The ID of the message to get.
---@param args table<string, FluentVariable?>? Arguments to pass for message resolution.
---@param defaultBundle string? The name of the default bundle to use. Defaults to the global bundle.
---@return string? value
function L10N.getTextOrNull(id, args, defaultBundle)
    local bundle
    bundle, id = L10N._getBundleAndId(id, defaultBundle)
    if not bundle then
        return
    end

    local message = bundle:getMessage(id)
    local pattern = message and message.value
    if not pattern then
        return
    end

    local result, errors = bundle:formatPattern(pattern, args)
    if errors then
        L10N._logFormatErrors(id, errors, bundle)
    end

    return result
end

---Checks whether a bundle with the given name exists.
---@param name string The name of the bundle to check for.
---@return boolean
function L10N.hasBundle(name)
    return L10N._bundles[name] ~= nil
end

---Loads an .ftl resource file from the Lua cache directory as a `FluentResource`.
---@param filename string The name of the file to load.
---@return FluentResource? resource
function L10N.loadCacheResource(filename)
    local reader = getFileReader(filename, false)
    if not reader then
        return
    end

    return L10N._parseFromReader(reader, filename)
end

---Loads an .ftl resource file from a mod directory as a `FluentResource`.
---@param modId string The fully-qualified ID of the mod to load from.
---@param filename string The name of the file to load.
---@return FluentResource? resource
function L10N.loadModResource(modId, filename)
    local reader = getModFileReader(modId, filename, false)
    if not reader then
        return
    end

    local resource = L10N._parseFromReader(reader, filename)
    if not resource.global and not resource.bundle then
        resource.bundle = modId
    end

    return resource
end

---Parses a string as a `FluentResource`.
---@param text string The text to parse.
---@param filename? string An optional filename to attach to the resource.
---@return FluentResource
function L10N.parseResource(text, filename)
    local ast = L10N._parser:parse(text)
    return L10N.FluentResource.fromAST(ast, filename)
end

---Resolves the value of a translation table.
---
---This can be used to send a translation from the server to the client,
---for display in their locale.
---@generic T
---@param rec TranslateTable<T> The translation table to resolve.
---@param defaultBundle string? The name of the default bundle to use. Defaults to the global bundle.
---@return string? result
function L10N.resolveTranslateTable(rec, defaultBundle)
    return L10N._resolveTranslateTable(rec, defaultBundle, {})
end

---Gets the bundle to use and the message ID from a given ID.
---@param id string
---@param defaultBundle string?
---@return FluentBundle? bundle
---@return string id
---@protected
function L10N._getBundleAndId(id, defaultBundle)
    local period = id:find('.', 1, true)

    local bundle
    if period then
        local bundleName = id:sub(1, period - 1)
        bundle = L10N._bundles[bundleName]
        id = id:sub(period + 1)
    elseif defaultBundle then
        bundle = L10N.getOrCreateBundle(defaultBundle)
    else
        bundle = L10N._global
    end

    return bundle, id
end

---Logs a warning for errors that occurred while formatting a message.
---@param name string
---@param errors string[]
---@param bundle FluentBundle
---@private
function L10N._logFormatErrors(name, errors, bundle)
    local errorsStr = #errors == 1 and 'Error' or 'Errors'
    local msg = { errorsStr .. ' while formatting ' .. name .. '.' }

    for i = 1, #errors do
        msg[i + 1] = errors[i]
    end

    local logger = bundle.log or log
    logger.error(concat(msg, #errors > 1 and '\n\t\t' or ' '))
end

---Loads .ftl files from active mods.
---@protected
function L10N._loadModResources()
    local locale = L10N._localeTag
    local base = L10N.gameLanguageToLocaleTag(L10N._language:base() or 'en')
    local lang = L10N.extractLanguage(locale)

    -- load from base locale first,
    -- then from primary language subtag (e.g., zh-Hant → zh),
    -- then from the actual target locale
    -- (for most locales this will just be en & the locale)
    local seen = {}
    local loadOrder = {} ---@type string[]

    if base and not seen[base] then
        seen[base] = true
        loadOrder[#loadOrder + 1] = base
    end

    if not seen[lang] then
        seen[lang] = true
        loadOrder[#loadOrder + 1] = lang
    end

    if not seen[locale] then
        loadOrder[#loadOrder + 1] = locale
    end

    -- load all .ftl files, collecting bundles for flattening
    ---@type SetTable<FluentBundle>
    local loaded = {}
    for i = 1, #loadOrder do
        L10N._loadModResourcesForLocale(loadOrder[i], loaded)
    end

    -- bundles are flattened post-load so terms defined across files can be referenced
    for bundle in pairs(loaded) do
        bundle:flatten()
    end
end

---Loads .ftl files of a given locale from a given mod directory.
---@param qualifiedId string
---@param directory string
---@param loaded SetTable<FluentBundle>
---@protected
function L10N._loadModResourcesForID(qualifiedId, directory, loaded)
    local files = listFilesInModDirectory(qualifiedId, directory) ---@cast files +?
    assert(files, 'Invalid mod ID passed to listFilesInModDirectory: ' .. qualifiedId)

    local prefix = directory .. '/'
    for j = 0, files:size() - 1 do
        local path = files:get(j)
        if path:sub(-4):lower() == '.ftl' then
            -- flattening is done after loading everything, so disable it
            local _, bundle = L10N.addModResource(qualifiedId, prefix .. path, { flatten = false })
            if bundle then
                loaded[bundle] = true
            end
        end
    end
end

---Loads .ftl files of a given locale from active mods.
---@param locale string
---@param loaded SetTable<FluentBundle>
---@protected
function L10N._loadModResourcesForLocale(locale, loaded)
    local mods = core.getActivatedMods()

    for i = 1, #mods do
        local modId = mods[i]
        local path = 'media/ftl/' .. locale
        local additionalPath = 'media/ftl/' .. modId .. '/' .. locale

        L10N._loadModResourcesForID(modId, path, loaded)
        L10N._loadModResourcesForID(modId, additionalPath, loaded)
    end
end

---Parses an .ftl file from a `BufferedReader`.
---Closes the reader after reading its contents.
---@param reader BufferedReader
---@param filename string
---@return FluentResource
---@protected
function L10N._parseFromReader(reader, filename)
    local lines = {}
    while reader:ready() do
        lines[#lines + 1] = reader:readLine()
    end

    reader:close()

    return L10N.parseResource(concat(lines, '\n'), filename)
end

---Resolves the value of a translation table.
---@generic T
---@param rec TranslateTable<T> The translation table to resolve.
---@param defaultBundle string? The name of the default bundle to use. Defaults to the global bundle.
---@param seen SetTable<TranslateTable<T>> Set of already seen tables.
---@return string
---@protected
function L10N._resolveTranslateTable(rec, defaultBundle, seen)
    if seen[rec] then
        return rec.attribute and (rec.id .. '.' .. rec.attribute) or rec.id
    end

    seen[rec] = true

    local args = {} ---@type table<string, FluentVariable>
    for k, v in pairs(rec.args or {}) do
        if type(v) == 'table' then
            if core.isinstance(v, L10N.FluentType) then
                args[k] = v
            else
                ---@cast v TranslateTable<T>
                args[k] = L10N._resolveTranslateTable(v, defaultBundle, seen)
            end
        else
            args[k] = v
        end
    end

    if rec.attribute then
        return L10N.getAttr(rec.id, rec.attribute, args, defaultBundle)
    end

    return L10N.getText(rec.id, args, defaultBundle)
end

---Shared bundle instance.
---@private
---@readonly
L10N._global = L10N.getOrCreateBundle('')


L10N._loadModResources()
return L10N

--#region Type Definitions

---@class Args.AddResource
---@field flatten boolean? Flag for whether resource messages should be flattened using early evaluation.
---Defaults to `true`. If the resource does not allow early evaluation, this has no effect.
---
---Flattening reduces the message to a string where possible,
---leaving only variables and message references.

---@class TranslateTable<T : string | number | FluentVariable | TranslateTable<any>>
---@field id string The ID of the message to translate.
---@field attribute? string The name of the attribute to translate.
---@field args? TranslateTableArgs<T> Arguments for message formatting.

---@class PartialTranslateTable<T> : TranslateTable<T>
---@field id? string The ID of the message to translate.


---@alias TranslateTableArgs<T> table<string, (T | TranslateTable<T>)?>

---@alias l10n.VanillaTranslationCategory
---| 'Tooltip'
---| 'IGUI'
---| 'Recipes'
---| 'RecipeGroups'
---| 'Farming'
---| 'ContextMenu'
---| 'SurvivalGuide'
---| 'UI'
---| 'Items'
---| 'ItemName'
---| 'Moodles'
---| 'Sandbox'
---| 'Challenge'
---| 'Stash'
---| 'MultiStageBuild'
---| 'Moveables'
---| 'MakeUp'
---| 'GameSound'
---| 'DynamicRadio'
---| 'EvolvedRecipeName'
---| 'Recorded_Media'
---| 'SurvivorNames'
---| 'Attributes'
---| 'Fluids'
---| 'Print_Media'
---| 'Print_Text'
---| 'Entity'
---| 'RadioData'
---| 'BodyParts'
---| 'MapLabel'

--#endregion
