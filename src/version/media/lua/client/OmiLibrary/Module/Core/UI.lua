---Components and utilities related to the UI.
---@namespace omi

local core = require 'OmiLibrary'
local Base = require 'OmiLibrary/Component/UI/Mixin/Base'

local ISUIElement = ISUIElement
local textManager = getTextManager()
local setJoypadFocus = setJoypadFocus


---@class(partial) ui
local UI = {}

---Custom sandbox pages to inject into the UI.
---@type Args.InjectSandboxPage[]
---@private
UI._customSandboxPages = {}

---Parser used to read rich text command attributes.
UI.AttributeParser = require 'OmiLibrary/Component/UI/AttributeParser'


---Creates and initializes a button element.
---@param args InitArgs.Button
---@return Button
function UI.button(args)
    local button = UI.Button:new(args)

    button:initialise()
    button:instantiate()
    UI.init(button, args)

    return button
end

---Creates and initializes a checkbox.
---@param args InitArgs.Checkbox
---@return Checkbox
function UI.checkbox(args)
    local checkbox = UI.Checkbox:new(args)

    checkbox:initialise()
    UI.init(checkbox, args)

    return checkbox
end

---Creates and initializes a checkbox group.
---@param args InitArgs.CheckboxGroup
---@return CheckboxGroup
function UI.checkboxGroup(args)
    local checkboxGroup = UI.CheckboxGroup:new(args)

    checkboxGroup:initialise()
    UI.init(checkboxGroup, args)

    return checkboxGroup
end

---Creates a new UI element class and extends it with the base UI mixin.
---@param type string The name of the new type.
---@param base ISUIElement? The base class. Defaults to `ISUIElement`.
---@param ...table Additional mixins to add to the class.
---@return BaseUI
function UI.class(type, base, ...)
    base = base or ISUIElement

    local cls = base:derive(type) --[[@as BaseUI]]
    core.extend(cls, Base, ...)

    cls.__base = base ---@diagnostic disable-line: access-invisible

    return cls
end

---Creates and initializes a new color entry box.
---@param args InitArgs.ColorEntry
---@return ColorEntry
function UI.colorEntry(args)
    local entry = UI.ColorEntry:new(args)

    entry:initialise()
    UI.init(entry, args)

    return entry
end

---Creates and displays a color dialog.
---@param args InitArgs.ColorDialog? Additional arguments for the dialog.
---@param type DialogType? The type of dialog to create. Defaults to `'OKCancel'`.
---@return ColorDialog
function UI.colorDialog(args, type)
    type = type or 'OKCancel'
    return UI.dialog(args, type, 'Color')
end

---Creates and displays a dialog.
---@param args InitArgs.AnyDialog? Additional arguments for the dialog.
---@param type DialogType? The type of dialog to create. Defaults to `'OK'`.
---@param entryType DialogEntryType? The type of entry to include in the dialog.
---@return Dialog
function UI.dialog(args, type, entryType)
    args = core.copy(args)
    args.type = type or 'OK'
    args.playerNum = args.playerNum or 0

    local dialog
    if entryType == 'Text' then
        ---@cast args InitArgs.TextDialog
        dialog = UI.TextDialog:new(args)
    elseif entryType == 'Color' then
        ---@cast args InitArgs.ColorDialog
        dialog = UI.ColorDialog:new(args)
    else
        dialog = UI.Dialog:new(args)
    end

    local playerNum = dialog:getPlayerNum()

    dialog:initialise()
    if not args.x and not args.y then
        dialog:centerOnScreen()
    end

    if args.setHeightToContents then
        if dialog:isRichText() and dialog.chatText then
            dialog.chatText:paginate()
        end

        dialog:setHeightToContents()

        if not args.y then
            dialog:setY(getPlayerScreenTop(playerNum) + (getPlayerScreenHeight(playerNum) - dialog:getHeight()) * 0.5)
        end
    end

    dialog:addToUIManager()
    setJoypadFocus(playerNum, dialog)

    UI.init(dialog, args)
    return dialog
end

---Creates and initializes a dropdown element.
---@param args InitArgs.Dropdown
---@return Dropdown
function UI.dropdown(args)
    local options = args.options or {} --[[@as Dropdown.OptionOrString[] ]]

    local dropdown = UI.Dropdown:new(args)
    dropdown:initialise()

    if not args.w then
        local maxW = args.minWidth or 0
        local wExtra = dropdown.image and (dropdown.image:getWidthOrig() + 18) or 0

        for i = 1, #options do
            local option = options[i]
            local text = type(option) == 'string' and option or option.text

            local optionW = textManager:MeasureStringX(dropdown.font, text) + wExtra
            if optionW > maxW then
                maxW = optionW
            end
        end

        if args.maxWidth and maxW > args.maxWidth then
            maxW = args.maxWidth
        end

        dropdown:setWidth(maxW)
    end

    for i = 1, #options do
        local option = options[i]
        if type(option) == 'string' then
            dropdown:addOptionWithData(option)
        else
            dropdown:addOptionWithData(option.text, option.data)
        end

        local added = dropdown.options[#dropdown.options] ---@cast added -?
        added.tooltip = option.tooltip
    end

    local selectedIdx = args.selected
    if selectedIdx then
        dropdown.selected = core.clamp(selectedIdx, 0, #dropdown.options)
    end

    UI.init(dropdown, args)
    return dropdown
end

---Gets the position for the center of the screen given a UI element's width and height.
---@param width number
---@param height number
---@param playerNum integer?
---@return number
---@return number
function UI.getScreenCenter(width, height, playerNum)
    playerNum = playerNum or 0
    local x = getPlayerScreenLeft(playerNum) + (getPlayerScreenWidth(playerNum) - width) * 0.5
    local y = getPlayerScreenTop(playerNum) + (getPlayerScreenHeight(playerNum) - height) * 0.5

    return x, y
end

---Performs initialization shared among various UI elements.
---@param element ISUIElement
---@param args InitArgs.Shared
function UI.init(element, args)
    if args.parent then
        args.parent:addChild(element)
    end

    if args.visible == false then
        element:setVisible(false)
    end

    if not args.renderClippedChildren then
        element.javaObject:setRenderClippedChildren(false)
    end

    if args.scrollChildren ~= false then
        element:setScrollChildren(true)
    end

    if args.addHorizontalScrollbar and not args.addVerticalScrollbar then
        element:addScrollBars(true)

        if element.vscroll then
            element.vscroll:setVisible(false)
        end
    elseif args.addVerticalScrollbar then
        element:addScrollBars(args.addHorizontalScrollbar)
    end

    if args.invisibleScrollbars then
        if element.vscroll then
            element.vscroll:setVisible(false)
        end

        if element.hscroll then
            element.hscroll:setVisible(false)
        end
    end

    if args.alwaysOnTop then
        element:setAlwaysOnTop(true)
    end

    if args.backMost then
        element.javaObject:backMost()
    end

    if args.uiName then
        element:setUIName(args.uiName)
    end

    ---@cast args any
    ---@cast element any
    local parent = args.parent --[[@as any]]
    if not args.playerNum and parent and parent.playerNum then
        element.playerNum = parent.playerNum
    end
end

---Performs initialization logic for listboxes.
---@param element ListBox
---@param args InitArgs.ListBox
function UI.initListBox(element, args)
    local items = args.items or {} --[[@as (string | InitArgs.ListBoxItem)[] ]]
    for i = 1, #items do
        local itemArgs = items[i]
        if type(itemArgs) ~= 'table' then
            itemArgs = {
                item = itemArgs,
                text = tostring(itemArgs),
            }
        end

        local item = element:addItem(itemArgs.text, itemArgs.item)
        item.tooltip = itemArgs.tooltip
        item.textColor = itemArgs.textColor
        item.textColorDisabled = itemArgs.textColorDisabled
        item.texture = itemArgs.texture
        item.textureColor = itemArgs.textureColor
        item.textureColorDisabled = itemArgs.textureColorDisabled
    end

    UI.init(element, args)
end

---Injects a page into the sandbox settings menu.
---@param args Args.InjectSandboxPage
function UI.injectSandboxPage(args)
    UI._customSandboxPages[#UI._customSandboxPages + 1] = args
end

---Creates and initializes a label element.
---@param args InitArgs.Label
---@return Label
function UI.label(args)
    local x = args.x or 0
    local y = args.y or 0
    local h = args.h or 0
    local left = args.left ~= false

    if args.font and not args.h then
        args.h = textManager:getFontHeight(args.font)
    end

    local r, g, b, a = core.color.unpack(args.color or { r = 1, g = 1, b = 1, a = 1 })

    local label = ISLabel:new(x, y, h, args.text, r, g, b, a, args.font, left)
    label.keepOnScreen = false ---@diagnostic disable-line: inject-field
    label.playerNum = args.playerNum or 0 ---@diagnostic disable-line: inject-field
    label.minimumWidth = args.minWidth or 0
    label.minimumHeight = args.minHeight or 0
    label.tooltip = args.tooltip
    label.anchorLeft = args.anchorLeft ~= false
    label.anchorRight = args.anchorRight or false
    label.anchorTop = args.anchorTop ~= false
    label.anchorBottom = args.anchorBottom or false
    label.center = args.center or false
    ---@diagnostic disable-next-line: inject-field
    label.joypadNavigate = core.copy(args.joypadNavigate)

    if args.w then
        label:setWidth(args.w)
    end

    label:initialise()
    UI.init(label, args)

    return label
end

---Creates and initializes a listbox element.
---@param args InitArgs.ListBox
---@return ListBox
function UI.listBox(args)
    local listbox = UI.ListBox:new(args)
    listbox:initialise()
    listbox:instantiate()

    UI.initListBox(listbox, args)
    return listbox
end

---Creates and initializes a list entry element.
---@param args InitArgs.ListEntry
---@return ListEntry
function UI.listEntry(args)
    args = UI._initListEntryArgs(args)

    local entry = UI.ListEntry:new(args)

    entry:initialise()
    entry:instantiate()

    UI.init(entry, args)
    return entry
end

---Creates and initializes a map entry element.
---@param args InitArgs.MapEntry
---@return MapEntry
function UI.mapEntry(args)
    args = UI._initListEntryArgs(args)

    local entry = UI.MapEntry:new(args)

    entry:initialise()
    entry:instantiate()

    UI.init(entry, args)
    return entry
end

---Creates a new instance of a UI class.
---@generic A, T : BaseUI
---@param cls T The class to create an instance of.
---@param cons fun(cls: T, ...: A...): T The base class constructor.
---@param ... A... Arguments for the base class constructor.
---@return T
function UI.new(cls, cons, ...)
    return cons(cls, ...)
end

---Creates and displays a dialog with an 'Ok' option.
---@param args InitArgs.AnyDialog? Additional arguments for the dialog.
---@param entryType DialogEntryType? The type of entry to include in the dialog.
---@return Dialog
function UI.okDialog(args, entryType)
    return UI.dialog(args, 'OK', entryType)
end

---Creates and displays a dialog with 'Ok' and 'Cancel' options.
---@param args InitArgs.AnyDialog? Additional arguments for the dialog.
---@param entryType DialogEntryType? The type of entry to include in the dialog.
---@return Dialog
function UI.okCancelDialog(args, entryType)
    return UI.dialog(args, 'OKCancel', entryType)
end

---Creates and initializes a content panel.
---@param args InitArgs.Panel
---@return Panel
function UI.panel(args)
    local panel = UI.Panel:new(args)
    panel:initialise()
    panel:instantiate()

    UI.init(panel, args)
    return panel
end

---Creates and initializes a rich text panel.
---@param args InitArgs.RichTextPanel
---@return RichTextPanel
function UI.richTextPanel(args)
    local panel = UI.RichTextPanel:new(args)
    panel:initialise()
    panel:instantiate()

    UI.init(panel, args)
    return panel
end

---Creates and initializes an auto-suggest box, and adds it to the UI manager.
---@param args InitArgs.SuggestBox
---@return SuggestBox
function UI.suggestBox(args)
    args = core.copy(args)
    args.alwaysOnTop = args.alwaysOnTop ~= false

    -- suggest boxes should be added directly to the UI
    if args.parent then
        args.parent = nil
    end

    local suggestBox = UI.SuggestBox:new(args)
    suggestBox:initialise()
    suggestBox:addToUIManager()
    suggestBox:setVisible(false)

    if args.items then
        suggestBox:setSuggestions(args.items)
    end

    UI.init(suggestBox, args)
    return suggestBox
end

---Creates and displays a text dialog with 'Ok' and 'Cancel' options.
---@param args InitArgs.TextDialog? Additional arguments for the dialog.
---@param type DialogType? The type of dialog to create. Defaults to `'OKCancel'`.
---@return TextDialog
function UI.textDialog(args, type)
    type = type or 'OKCancel'
    return UI.dialog(args, type, 'Text')
end

---Creates and initializes a new text entry.
---@param args InitArgs.TextEntry
---@return TextEntry
function UI.textEntry(args)
    local entry = UI.TextEntry:new(args)

    entry:initialise()
    UI.init(entry, args)

    return entry
end

---Creates and initializes a tooltip element, and adds it to the UI manager.
---@param args InitArgs.Tooltip?
---@return Tooltip
function UI.tooltip(args)
    args = core.copy(args)

    local tooltip = ISToolTip:new()
    UI._initTooltip(tooltip, args)

    ---@diagnostic disable-next-line: assign-type-mismatch
    tooltip.descriptionPanel = UI.richTextPanel {
        marginLeft = 0,
        marginRight = 0,
        background = false,
        backgroundColor = { r = 0, g = 0, b = 0, a = 0.3 },
        borderColor = { r = 1, g = 1, b = 1, a = 0.1 },
    }

    tooltip.contextMenu = args.contextMenu
    tooltip.description = args.text or tooltip.description
    tooltip.name = args.name
    tooltip.footNote = args.footNote
    tooltip.texture = args.texture
    tooltip.nameMarginX = args.nameMarginX or tooltip.nameMarginX

    tooltip:initialise()
    tooltip:addToUIManager()

    UI.init(tooltip, args)
    return tooltip
end

---Creates and initializes an inventory tooltip element, and adds it to the UI manager.
---@param args InitArgs.TooltipInv?
---@return TooltipInv
function UI.tooltipInv(args)
    args = core.copy(args)

    local tooltip = ISToolTipInv:new(args.item)
    UI._initTooltip(tooltip, args)

    tooltip:initialise()
    tooltip:addToUIManager()

    UI.init(tooltip, args)
    return tooltip
end

---Creates and displays a dialog with 'Yes' and 'No' options.
---@param args InitArgs.AnyDialog? Additional arguments for the dialog.
---@param entryType DialogEntryType? The type of entry to include in the dialog.
---@return Dialog
function UI.yesNoDialog(args, entryType)
    return UI.dialog(args, 'YesNo', entryType)
end

---Creates and displays a dialog with 'Yes', 'No', and 'Cancel' options.
---@param args InitArgs.AnyDialog? Additional arguments for the dialog.
---@param entryType DialogEntryType? The type of entry to include in the dialog.
---@return Dialog
function UI.yesNoCancelDialog(args, entryType)
    return UI.dialog(args, 'YesNoCancel', entryType)
end


---Sets default values for list entry arguments.
---@generic T : InitArgs.ListEntry
---@param args T
---@return T
---@private
function UI._initListEntryArgs(args)
    if args.h or not args.visibleItems then
        return args
    end

    local textEntry = args.textEntry or {}

    args = core.copy(args)
    args.h = UI.ListEntry.calculateHeight(
        args.visibleItems or 5,
        textEntry.font or args.font,
        args.itemPadY,
        textEntry.h
    )

    return args
end

---Performs initialization shared among tooltips.
---@param tooltip ISToolTip | ISToolTipInv
---@param args InitArgs.Tooltip.Shared
---@private
function UI._initTooltip(tooltip, args)
    -- tooltips don't need parents; treat as shortcut for `owner`
    if args.parent then
        args.owner = args.owner or args.parent
        args.parent = nil
    end

    tooltip.x = args.x or 0
    tooltip.y = args.y or 0
    tooltip.width = args.w or 0
    tooltip.height = args.h or 0
    tooltip.owner = args.owner
    tooltip.borderColor = args.borderColor or tooltip.borderColor
    tooltip.backgroundColor = args.backgroundColor or tooltip.backgroundColor
    tooltip.followMouse = args.followMouse ~= false

    tooltip.playerNum = args.playerNum or 0 ---@diagnostic disable-line: inject-field
    tooltip.minimumWidth = args.minWidth or 0
    tooltip.minimumHeight = args.minHeight or 0
    tooltip.anchorLeft = args.anchorLeft ~= false
    tooltip.anchorRight = args.anchorRight or false
    tooltip.anchorTop = args.anchorTop ~= false
    tooltip.anchorBottom = args.anchorBottom or false
    tooltip.joypadNavigate = core.copy(args.joypadNavigate)

    local owner = tooltip.owner or tooltip.contextMenu
    if owner and not args.x and not args.y then
        tooltip.x = owner:getMouseX() + 23
        tooltip.y = owner:getMouseY() + 23
    end
end


return UI


--#region Type Definition

---@class InitArgs.Shared
---@field visible? boolean If `false`, the element will be initially invisible.
---@field renderClippedChildren? boolean If `true`, child elements entirely outside of the parent element's visible area will still call `render`. Defaults to `false`.
---@field scrollChildren? boolean If `true`, the element's children will scroll with the element's scroll position. Defaults to `true`.
---@field addVerticalScrollbar? boolean If `true`, a vertical scrollbar will be added to the element.
---@field addHorizontalScrollbar? boolean If `true`, a horizontal scrollbar will be added to the element.
---@field invisibleScrollbars? boolean If `true`, scrollbars will be set to not be visible after being added.
---@field alwaysOnTop? boolean If `true`, the element will display on top of all other elements.
---@field backMost? boolean If `true`, the element will display behind all other elements.
---@field uiName? string The UI name to assign to the element.
---@field parent? ISUIElement A parent to add the element to as a child.

---@class Args.Label : Args.BaseUI
---@field text string The label text.
---@field x? number The x position of the label.
---@field y? number The y position of the label.
---@field w? number The width of the label.
---@field h? number The height of the label.
---@field left? boolean If `true`, the label will be treated as left-aligned. Defaults to `true`.
---@field center? boolean If `true`, the text will be drawn centered.
---@field font? UIFont The font to use for the text. Defaults to `UIFont.Small`.
---@field color? ColorTableRGBA<number> The color to use for the label text.
---@field tooltip? string The tooltip to show when hovering over the label.

---@class Args.Tooltip.Shared : Args.BaseUI
---@field owner? ISUIElement The owner element of the tooltip.
---@field borderColor? ColorTableRGBA<number> The color to use for the tooltip border.
---@field backgroundColor? ColorTableRGBA<number> The color to use for the tooltip background.
---@field followMouse? boolean If `false`, the tooltip won't follow mouse movements.

---@class Args.Tooltip : Args.Tooltip.Shared
---@field contextMenu? ISContextMenu The context menu element associated with the tooltip.
---@field text? string The text to display in the tooltip.
---@field name? string The name text to display in the tooltip.
---@field footNote? string The text to display in the footnote.
---@field texture? Texture The texture to display in the tooltip.
---@field nameMarginX? number An additional margin to add to the name width. The default is `50`.

---@class Args.TooltipInv : Args.Tooltip.Shared
---@field item InventoryItem The item to use for the tooltip.

---@class Args.InjectSandboxPage
---@field name string The page name.
---@field ui ISUIElement The class of the UI element to inject.
---Must have a `new` function which takes `x`, `y`, `width`, and `height` arguments.

---@class InitArgs.Label : Args.Label, InitArgs.Shared

---@class InitArgs.Tooltip.Shared : Args.Tooltip.Shared, InitArgs.Shared

---@class InitArgs.Tooltip : Args.Tooltip, InitArgs.Tooltip.Shared

---@class InitArgs.TooltipInv : Args.TooltipInv, InitArgs.Tooltip.Shared



---@alias Tooltip ISToolTip

---@alias TooltipInv ISToolTipInv

---@alias Label ISLabel

---@alias UICallback fun(target: any?, ...: any)

--#endregion
