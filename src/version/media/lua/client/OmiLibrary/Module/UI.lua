---Contains components and utilities related to the UI.
---@namespace omi

---@class(partial) ui
local UI = require 'OmiLibrary/Module/Core/UI'

---Components and utilities related to forms.
UI.forms = require 'OmiLibrary/Module/UI/Forms'

---Mixins with functionality that can be added to various elements.
UI.mixin = require 'OmiLibrary/Module/UI/Mixin'


---UI element for a button.
UI.Button = require 'OmiLibrary/Component/UI/Button'

---UI element for a single checkbox.
UI.Checkbox = require 'OmiLibrary/Component/UI/Checkbox'

---UI element for a checkbox group.
UI.CheckboxGroup = require 'OmiLibrary/Component/UI/CheckboxGroup'

---UI element for a dialog with a color entry.
UI.ColorDialog = require 'OmiLibrary/Component/UI/ColorDialog'

---UI element for a color input entry with validation.
UI.ColorEntry = require 'OmiLibrary/Component/UI/ColorEntry'

---UI element for a dialog box.
UI.Dialog = require 'OmiLibrary/Component/UI/Dialog'

---UI element for a dropdown box.
UI.Dropdown = require 'OmiLibrary/Component/UI/Dropdown'

---UI element for a scrolling listbox.
UI.ListBox = require 'OmiLibrary/Component/UI/ListBox'

---UI element for a list entry.
UI.ListEntry = require 'OmiLibrary/Component/UI/ListEntry'

---UI element for a map entry.
UI.MapEntry = require 'OmiLibrary/Component/UI/MapEntry'

---UI element for a panel to contain other elements.
UI.Panel = require 'OmiLibrary/Component/UI/Panel'

---UI element for a rich text panel.
UI.RichTextPanel = require 'OmiLibrary/Component/UI/RichTextPanel'

---UI element for an auto-suggest box.
UI.SuggestBox = require 'OmiLibrary/Component/UI/SuggestBox'

---UI element for a dialog with a text entry.
UI.TextDialog = require 'OmiLibrary/Component/UI/TextDialog'

---UI element for a text input with optional validation.
UI.TextEntry = require 'OmiLibrary/Component/UI/TextEntry'


return UI
