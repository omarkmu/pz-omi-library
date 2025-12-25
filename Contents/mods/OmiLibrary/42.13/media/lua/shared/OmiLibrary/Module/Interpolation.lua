---Contains functionality for string interpolation.
---@namespace omi

---@class interpolate
---@overload fun(text: string, tokens: table?, options: Args.Interpolator?): string
local interpolate = {}
interpolate.Parser = require 'OmiLibrary/Component/Interpolation/InterpolateParser'
interpolate.Interpolator = require 'OmiLibrary/Component/Interpolation/Interpolator'
interpolate.Libraries = require 'OmiLibrary/Component/Interpolation/Libraries'

---Associates strings representing options to shared interpolator instances.
---@type table<string, Interpolator>
---@private
interpolate._sharedInterpolators = {}


---Registers an interpolator function.
---@param name string The name of the new interpolation function.
---@param func InterpolatorFunction The function to execute when the interpolation function is used.
function interpolate.register(name, func)
    interpolate.Interpolator.register(name, func)
end

---Performs string interpolation.
---@param text string
---@param tokens table?
---@param options InterpolationOptions?
---@return string
function interpolate.run(text, tokens, options)
    local interpolator = interpolate._getInterpolator(options)
    return interpolator:interpolate(text, tokens)
end


---Gets or creates a shared interpolator to use for an options table.
---@param options InterpolationOptions?
---@return Interpolator
---@private
function interpolate._getInterpolator(options)
    local key = '1111111'
    if options then
        key = (options.allowTokens ~= false and '1' or '0') ..
            (options.allowMultiMaps ~= false and '1' or '0') ..
            (options.allowFunctions ~= false and '1' or '0') ..
            (options.allowCharacterEntities ~= false and '1' or '0') ..
            (options.caseSensitiveFunctions ~= false and '1' or '0') ..
            (options.checkNumericTokens ~= false and '1' or '0') ..
            (options.requireCustomTokenUnderscore ~= false and '1' or '0')
    end

    local interpolator = interpolate._sharedInterpolators[key]
    if not interpolator then
        interpolator = interpolate.Interpolator:new(options)
        interpolate._sharedInterpolators[key] = interpolator
    end

    return interpolator
end

setmetatable(interpolate, { __call = function(self, ...) return self.run(...) end })
return interpolate
