---Information about a form page.
---@namespace omi

local core = require 'OmiLibrary'

local getAttrOrNull = core.l10n.getAttrOrNull


---@class forms.PageInfo : Class
---@field info forms.FieldInfo Information about the field associated with the form page.
---@field panel Panel The panel containing the page content.
---@field label? Label The label used for the page heading.
---@field tooltip? string The tooltip used for the form listbox item associated with the page.
local PageInfo = core.class('FormPageInfo')


---Creates a new form page.
---@param args Args.FormPageInfo
---@return forms.PageInfo
function PageInfo:new(args)
    local this = core.new(self)

    this.info = args.info
    this.tooltip = getAttrOrNull(this.info.prefix, 'tooltip')
    this.panel = args.form:createPagePanel()

    return this
end


return PageInfo

--#region Type Definitions

---@class Args.FormPageInfo
---@field form forms.Form The form that the page belongs to.
---@field info forms.FieldInfo Information about the field associated with the form page.

--#endregion
