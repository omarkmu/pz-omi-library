---Module containing functionality related to creating "classes".
---@namespace omi

local META_OPS = {
    '__index',
    '__newindex',
    '__unm',
    '__add',
    '__sub',
    '__mul',
    '__div',
    '__mod',
    '__pow',
    '__eq',
    '__lt',
    '__le',
    '__len',
    '__tostring',
    '__concat',
    '__call',
}

local setmetatable = setmetatable

---@class Class
local Class = {}


---@class class
---@overload fun(name: string): Class
local class = {}


---Creates a new subclass.
---@param name string
---@return Class
function Class:derive(name)
    return class.derive(self, name)
end

---Creates a new subclass.
---@param base table
---@param name string
---@return Class
function class.derive(base, name)
    local cls = {}
    for i = 1, #META_OPS do
        local k = META_OPS[i]
        if cls[k] == nil then
            cls[k] = base[k]
        end
    end

    cls.Type = name
    cls.__index = cls
    base.__index = base

    return setmetatable(cls, base)
end

---Creates a new class.
---@param name string
---@return Class
function class.new(name)
    return class.derive(Class, name)
end


setmetatable(class, { __call = function(self, ...) return self.new(...) end })
return class
