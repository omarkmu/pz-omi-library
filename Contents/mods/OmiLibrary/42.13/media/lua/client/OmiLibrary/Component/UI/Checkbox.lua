---UI element for a single checkbox.
---@namespace omi

local core = require 'OmiLibrary'
local UI = require 'OmiLibrary/Module/UI/Core'
local CheckboxGroup = require 'OmiLibrary/Component/UI/CheckboxGroup'


---@class Checkbox : CheckboxGroup
---@field protected __base CheckboxGroup The base class.
local Checkbox = CheckboxGroup:derive('OmiCheckbox')


---Returns whether the checkbox is selected.
---@return boolean
function Checkbox:isSelected()
    return CheckboxGroup.isSelected(self, 1)
end

---Sets whether the checkbox is selected.
---@param selected boolean?
function Checkbox:setChecked(selected)
    CheckboxGroup.setSelected(self, 1, selected)
end

---Sets a callback to be invoked when the checkbox value changes.
---@param target any?
---@param callback Callback.Checkbox.Change?
---@param ...any
function Checkbox:setOnChange(target, callback, ...)
    self.callbacks.change = core.callback(target, callback, ...)
end

---@deprecated Use `setChecked`.
function Checkbox:setSelected(...)
    CheckboxGroup.setSelected(self, ...)
end

---Triggered when the value of the checkbox changes.
---@param index integer
---@param value boolean
---@protected
---@diagnostic disable-next-line: unused
function Checkbox:_onChange(index, value)
    core.callback.invoke(self.callbacks.change, value, self)
end


---Creates a new checkbox.
---@param args Args.Checkbox
---@return Checkbox
function Checkbox:new(args)
    ---@type CheckboxGroup.Item
    local item = {
        text = args.text,
        data = args.data,
        texture = args.texture,
        checked = args.checked,
    }

    local newArgs = core.copy(args) --[[@as Args.CheckboxGroup]]
    newArgs.items = { item }

    return UI.new(self, CheckboxGroup.new, newArgs)
end


return Checkbox

--#region Type Definitions

---@class Args.Checkbox : CheckboxGroup.Item, Args.CheckboxGroup.Base
---@field onChange? Callback.Checkbox.Change Invoked when the checkbox value changes.

---@class InitArgs.Checkbox : Args.Checkbox, InitArgs.Shared


---@alias Callback.Checkbox.Change fun(target: any?, value: boolean, checkbox: Checkbox, ...: any)

--#endregion
