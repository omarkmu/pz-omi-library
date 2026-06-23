---Functions provided in library proxy tables.
---@meta _
---@namespace omi

---@class proxy
local proxy = {}

---Gets a string from a message ID.
---@param id string The ID of the message to get.
---If a bundle is not included in the ID (using `<bundle>.<messageId>`), it will default to the mod ID.
---@param attr string The name of the attribute to get.
---@param args table<string, omi.l10n.FluentVariable?>? Arguments to pass for message resolution.
---@return string value
function proxy.getAttr(id, attr, args) end

---Gets a string from a message ID, or `nil` if no such message exists.
---@param id string The ID of the message to get.
---If a bundle is not included in the ID (using `<bundle>.<messageId>`), it will default to the mod ID.
---@param attr string The name of the attribute to get.
---@param args table<string, omi.l10n.FluentVariable?>? Arguments to pass for message resolution.
---@return string? value
function proxy.getAttrOrNull(id, attr, args) end

---Gets a string from a message ID.
---@param id string The ID of the message to get.
---If a bundle is not included in the ID (using `<bundle>.<messageId>`), it will default to the mod ID.
---@param args table<string, omi.l10n.FluentVariable?>? Arguments to pass for message resolution.
---@return string value
function proxy.getText(id, args) end

---Gets a string from a message ID, or `nil` if no such message exists.
---@param id string The ID of the message to get.
---If a bundle is not included in the ID (using `<bundle>.<messageId>`), it will default to the mod ID.
---@param args table<string, omi.l10n.FluentVariable?>? Arguments to pass for message resolution.
---@return string? value
function proxy.getTextOrNull(id, args) end
