---Helper types.
---@meta _
---@namespace omi

---@class ColorTable<T: number> : umbrella.RGB
---@field r T The red value.
---@field g T The green value.
---@field b T The blue value.

---@class ColorTableRGBA<T: number> : ColorTable<T>, umbrella.RGBA
---@field a T The alpha value.

---@alias SetTable<T> table<T, boolean?>

---@alias Entry<K, V> [K, V]

---@alias Callback.LogError fun(err: string, ...: any)
