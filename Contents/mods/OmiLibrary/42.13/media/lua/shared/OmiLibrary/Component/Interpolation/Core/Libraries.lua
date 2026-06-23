---Container for interpolation library functions.
---@namespace omi

---@class(partial) interpolate.libraries
---@field protected _list string[] List of interpolator libraries in the order they should be loaded.
local Libraries = {}

Libraries._list = {
    'math',
    'boolean',
    'string',
    'map',
    'mutate',
    'pz',
}


---Returns a table of interpolator functions.
---@param include SetTable<string>? A set of function or modules to include.
---@param exclude SetTable<string>? A set of function or modules to exclude.
---@param toLowercase boolean? If `true`, function names will be converted to lowercase.
---@return table
function Libraries:load(include, exclude, toLowercase)
    exclude = exclude or {}

    local result = {}

    for i = 1, #self._list do
        local lib = self._list[i]
        if not exclude[lib] then
            local funcs = Libraries[lib] --[[@as any]]
            for k, func in pairs(funcs) do
                local name = table.concat({ lib, '.', k })
                if not exclude[name] and (not include or include[lib] or include[name]) then
                    if toLowercase then
                        k = k:lower()
                    end

                    result[k] = func
                end
            end
        end
    end

    return result
end



return Libraries
