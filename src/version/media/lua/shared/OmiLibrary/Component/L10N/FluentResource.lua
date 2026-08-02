---Structure for storing localization entries from a single resource.
---@namespace omi.l10n
---@using omi
---@using omi.l10n.fluent

local core = require 'OmiLibrary/Module/Utils'
local Builder = require 'OmiLibrary/Component/L10N/FluentResourceBuilder'


---@class FluentResource : Class
---@field body Message[] The list of entries on the resource.
---@field bundle string? The target bundle specified in the resource.
---@field global boolean Flag for whether the resource should be added to the global bundle.
---@field filename string? The filename of the file the resource was loaded from.
local Resource = core.class('Resource')


---Creates a resource from a parsed AST.
---@param ast AST.Resource The AST to convert.
---@param filename string? The filename of the file the resource was loaded from.
---@return FluentResource resource
function Resource.fromAST(ast, filename)
    local resource = Resource:new()
    resource.filename = filename

    local builder = Builder:new(ast)
    return builder:build(resource)
end

---Creates a new Fluent resource.
---@param body Message[]? The entry list.
---@return FluentResource resource
function Resource:new(body)
    local this = core.new(self)

    this.body = body or {}
    this.global = false

    return this
end


return Resource
