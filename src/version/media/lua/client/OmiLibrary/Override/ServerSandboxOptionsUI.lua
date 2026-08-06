---Handles injecting sandbox options pages.
---@namespace omi

local UI = require 'OmiLibrary/Module/Core/UI'

local ISServerSandboxOptionsUI = ISServerSandboxOptionsUI
local _createChildren = ISServerSandboxOptionsUI.createChildren

local UI_BORDER_SPACING = 10
local SCROLLBAR_WIDTH = 17

---Override to inject pages.
function ISServerSandboxOptionsUI:createChildren()
    _createChildren(self)

    ---@diagnostic disable-next-line: access-invisible
    local toInject = UI._customSandboxPages
    if #toInject == 0 then
        return
    end

    local listbox = self.listbox
    for i = 1, #toInject do
        local args = toInject[i]

        ---@type umbrella.ServerSettingsScreen.SettingsPage
        local page = {
            name = args.name,
            customui = args.ui,
            settings = {},
        }

        local item = {
            panel = self:createPanel(page),
            page = page,
        }

        self.customui[#self.customui + 1] = item.panel
        listbox:addItem(page.name, item)
    end
end
