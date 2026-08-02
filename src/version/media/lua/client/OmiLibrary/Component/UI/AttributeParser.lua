---Parser for rich text attributes.
---@namespace omi

local core = require 'OmiLibrary/Module/Utils'
local BaseParser = require 'OmiLibrary/Component/Core/Parser'
local concat = table.concat


---@class AttributeParser : Parser<BasicParseNode>
local AttributeParser = BaseParser:derive('AttributeParser')

---@enum AttributeParser.NodeType
AttributeParser.NodeType = {
    attribute = 'attribute',
    attribute_key = 'attribute_key',
    attribute_value = 'attribute_value',
}

local NodeType = AttributeParser.NodeType


---Performs parsing of attributes.
---@return ParsedAttribute[]
function AttributeParser:parse(text)
    return BaseParser.parse(self, text)
end

---Performs postprocessing on a result tree.
---@return ParsedAttribute[]
---@protected
function AttributeParser:postprocess()
    local tree = self._tree
    local result = {} ---@type ParsedAttribute[]

    if not tree.children then
        return result
    end

    for i = 1, #tree.children do
        local node = tree.children[i]
        if node.children then
            local keyNode = node.children[1]

            local key = keyNode and keyNode.value or ''
            if key ~= '' then
                local valueNode = node.children[2]

                result[#result + 1] = {
                    key = key,
                    value = valueNode and valueNode.value or '',
                }
            end
        end
    end

    return result
end

---Reads a single attribute.
---@return BasicParseNode
---@protected
function AttributeParser:readAttribute()
    local node = self:createNode(NodeType.attribute)
    local parent = self:setCurrentNode(node)

    self:readAttributeChild(NodeType.attribute_key)

    local nextChar = self:peek()
    if nextChar == '=' then
        while nextChar == '=' do
            self._ptr = self._ptr + 1
            nextChar = self:peek()
        end

        self:readAttributeChild(NodeType.attribute_value)
    end

    self:setCurrentNode(parent)

    self:setNodeEnd(node)
    self._ptr = self._ptr + 1
    return self:addNode(node)
end

---Reads an attribute key or value.
---@param nodeType AttributeParser.NodeType
---@return BasicParseNode
---@protected
function AttributeParser:readAttributeChild(nodeType)
    local node = self:createNode(nodeType)
    node.value = self:readString() or self:readText()

    self:setNodeEnd(node)

    return self:addNode(node)
end

---Reads an expression.
---@return BasicParseNode?
---@protected
function AttributeParser:readExpression()
    return self:readAttribute()
end

---Reads a string delimited by a single or double quote.
---@return string?
---@protected
function AttributeParser:readString()
    local c = self:peek()
    if c ~= '"' and c ~= '\'' then
        return
    end

    local chars = {}
    local delim = c

    local len = self:len()
    local i = self:forward()
    while i <= len do
        c = self:index(i)

        if c == '\\' and self:index(i + 1) == delim then
            -- skip escaped quote and add
            i = i + 1
            chars[#chars + 1] = delim
        elseif c == delim then
            i = i + 1
            break
        else
            chars[#chars + 1] = c
        end

        i = i + 1
    end

    self._ptr = i
    return concat(chars):trim()
end

---Reads text until the next special character or the end of the string.
---@return string
---@protected
function AttributeParser:readText()
    local text, stop = self:match('(.-)()[= "\']')
    if text then
        self._ptr = stop
        return text:trim()
    end

    return self:read(self:len()):trim()
end


---Creates a new parser.
---@param options Args.Parser? Options for creation of the parser.
---@return AttributeParser
function AttributeParser:new(options)
    return core.new(self, BaseParser.new, options)
end


return AttributeParser

--#region Type Definitions

---@class ParsedAttribute
---@field key string The key that was used for the attribute.
---@field value string The value used for the attribute. For attributes without values, this is the empty string.

--#endregion
