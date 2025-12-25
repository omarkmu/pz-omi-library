---Contains components and utilities related to forms.
---@namespace omi

---@class forms
local Forms = {}


---Form panel for collecting information from the user.
Forms.Form = require 'OmiLibrary/Component/UI/Forms/Form'

---Component that generates a form based on a schema.
Forms.Generator = require 'OmiLibrary/Component/UI/Forms/Generator'

---Control for an array of objects in a form.
Forms.ObjectArrayPanel = require 'OmiLibrary/Component/UI/Forms/ObjectArrayPanel'


---Creates a form generator.
---@param args Args.FormGenerator
---@return forms.Generator
function Forms.generator(args)
    return Forms.Generator:new(args)
end


return Forms
