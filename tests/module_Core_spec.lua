---Contains tests for the core utility module.
---@diagnostic disable: access-invisible

local core = require 'OmiLibrary/Module/Core'
local Scheduler = require 'OmiLibrary/Component/Core/Scheduler'

local isPositive = function(x) return x > 0 end
local isNegative = function(x) return x < 0 end
local isZero = function(x) return x == 0 end
local increment = function(x) return x + 1 end
local id = function(x) return x end

local _000 = { 0, 0, 0 }
local n01 = { 0, -1 }
local p01 = { 0, 1 }
local n12 = { -1, -2 }
local p12 = { 1, 2 }

local function clearActivatedModsCache()
    core._activatedMods = nil
    core._activatedModsSet = nil
end

describe('#module core #function', function()
    describe('all', function()
        it('returns true when all values satisfy the predicate', function()
            assert.is_true(core.all(isZero, _000))
            assert.is_true(core.all(isNegative, n12))
            assert.is_true(core.all(isPositive, p12))
        end)

        it('returns false when at least one value does not satisfy the predicate', function()
            assert.is_false(core.all(isNegative, _000))
            assert.is_false(core.all(isPositive, _000))

            assert.is_false(core.all(isZero, n01))
            assert.is_false(core.all(isNegative, n01))
            assert.is_false(core.all(isPositive, n01))

            assert.is_false(core.all(isZero, p01))
            assert.is_false(core.all(isPositive, p01))
            assert.is_false(core.all(isNegative, p01))

            assert.is_false(core.all(isZero, n12))
            assert.is_false(core.all(isPositive, n12))

            assert.is_false(core.all(isZero, p12))
            assert.is_false(core.all(isNegative, p12))
        end)
    end)

    describe('any', function()
        it('returns true when any value satisfies the predicate', function()
            assert.is_true(core.any(isZero, _000))

            assert.is_true(core.any(isZero, n01))
            assert.is_true(core.any(isNegative, n01))

            assert.is_true(core.any(isZero, p01))
            assert.is_true(core.any(isPositive, p01))

            assert.is_true(core.any(isNegative, n12))
            assert.is_true(core.any(isPositive, p12))
        end)

        it('returns false when no values satisfy the predicate', function()
            assert.is_false(core.any(isPositive, n01))

            assert.is_false(core.any(isNegative, p01))

            assert.is_false(core.any(isZero, n12))
            assert.is_false(core.any(isPositive, n12))

            assert.is_false(core.any(isZero, p12))
            assert.is_false(core.any(isNegative, p12))
        end)
    end)

    describe('append', function()
        it('returns the first argument', function()
            local t = { 1 }
            assert.equal(t, core.append(t))
        end)

        it('appends elements from a list to the destination list', function()
            assert.same({ 1, 2, 3 }, core.append({ 1 }, { 2, 3 }))
        end)

        it('appends elements from multiple lists to the destination list', function()
            assert.same({ 1, 2, 3, 4, 5 }, core.append({ 1 }, { 2 }, { 3, 4 }, { 5 }))
        end)
    end)

    describe('appendCopy', function()
        it('returns a copy of the first argument', function()
            local t = { 1 }
            local result = core.appendCopy(t)

            assert.same(t, result)
            assert.is_not_equal(t, result)
        end)

        it('appends elements from a list to the destination list', function()
            assert.same({ 1, 2, 3 }, core.appendCopy({ 1 }, { 2, 3 }))
        end)

        it('appends elements from multiple lists to the destination list', function()
            assert.same({ 1, 2, 3, 4, 5 }, core.appendCopy({ 1 }, { 2 }, { 3, 4 }, { 5 }))
        end)
    end)

    describe('appendElements', function()
        it('returns the first argument', function()
            local t = { 1 }
            assert.equal(t, core.appendElements(t))
        end)

        it('appends arguments to the destination list', function()
            assert.same({ 1, 2, 3 }, core.appendElements({ 1 }, 2, 3))
        end)
    end)

    describe('appendSlice', function()
        it('returns the first argument', function()
            local t = { 1 }
            assert.equal(t, core.appendSlice(t, {}))
        end)

        it('appends elements from a list to the destination list', function()
            assert.same({ 1, 2, 3 }, core.appendSlice({ 1 }, { 2, 3 }))
        end)

        it('starts at the given start index', function()
            assert.same({ 1, 3, 4, 5 }, core.appendSlice({ 1 }, { 2, 3, 4, 5 }, 2))
        end)

        it('stops at the given end index', function()
            assert.same({ 1, 2, 3 }, core.appendSlice({ 1 }, { 2, 3, 4, 5 }, nil, 2))
        end)

        it('starts and stops at the given indices', function()
            assert.same({ 1, 3, 4 }, core.appendSlice({ 1 }, { 2, 3, 4, 5 }, 2, 3))
        end)
    end)

    describe('bind', function()
        it('creates a function that prefixes bound arguments', function()
            local f = spy.new()
            local bound = core.bind(f --[[@as function]], 1, 2)

            bound(3, 4)
            assert.spy(f).called_with(1, 2, 3, 4)
        end)

        it('passes bound nil values to the bound function', function()
            local f = spy.new()
            local bound = core.bind(f --[[@as function]], 1, nil, 3)

            bound(4)
            assert.spy(f).called_with(1, nil, 3, 4)
        end)
    end)

    describe('clamp', function()
        it('clamps values between the given minimum and maximum', function()
            assert.equal(3, core.clamp(3, 1, 5))
            assert.equal(1, core.clamp(-10, 1, 5))
            assert.equal(5, core.clamp(10, 1, 5))
        end)
    end)

    describe('concat', function()
        it('concatenates strings', function()
            assert.equal('', core.concat({}))
            assert.equal('hello', core.concat({ 'hello' }))
            assert.equal('ab', core.concat({ 'a', 'b' }))
        end)

        it('concatenates numbers', function()
            assert.equal('12', core.concat({ 1, 2 }))
            assert.equal('12a3b', core.concat({ 1, 2, 'a', 3, 'b' }))
        end)

        it('converts non-string values to strings', function()
            local t = setmetatable({}, {
                __tostring = function() return 'string' end,
            })

            assert.equal('truestring', core.concat({ true, t }))
        end)
    end)

    describe('contains', function()
        it('returns false if the comparison argument is not given', function()
            assert.is_false(core.contains('hello'))
        end)

        it('returns true if the comparison argument is empty', function()
            assert.is_true(core.contains('hello', ''))
        end)

        it('returns true if the text contains the comparison argument', function()
            assert.is_true(core.contains('hello', 'h'))
            assert.is_true(core.contains('hello', 'l'))
            assert.is_true(core.contains('hello', 'o'))
            assert.is_true(core.contains('hello', 'he'))
            assert.is_true(core.contains('hello', 'el'))
            assert.is_true(core.contains('hello', 'lo'))
        end)

        it('returns false if the text does not contain the comparison argument', function()
            assert.is_false(core.contains('hello', 'HELLO'))
            assert.is_false(core.contains('hello', 'goodbye'))
            assert.is_false(core.contains('hello', 'hello world'))
        end)
    end)

    describe('copy', function()
        it('creates equivalent copies', function()
            assert.same({}, core.copy({}))
            assert.same({ {} }, core.copy({ {} }))
            assert.same({ 1, 2, 3 }, core.copy({ 1, 2, 3 }))
            assert.same({ hello = 'world' }, core.copy({ hello = 'world' }))
            assert.same({ [true] = false }, core.copy({ [true] = false }))
        end)

        it('creates copies that are not reference equal', function()
            local original = {}
            assert.is_not_equal(original, core.copy(original))
        end)

        it('copies table references', function()
            local t = {}
            assert.same({ [t] = 1 }, core.copy({ [t] = 1 }))
            assert.equal(1, core.copy({ [t] = 1 })[t])

            local t2 = {}
            assert.same({ table = t2 }, core.copy({ table = t2 }))
        end)

        it('does not copy metatables', function()
            assert.is_nil(getmetatable(core.copy(setmetatable({}, {}))))
        end)
    end)

    describe('copyList', function()
        it('creates equivalent copies', function()
            assert.same({}, core.copyList({}))
            assert.same({ {} }, core.copyList({ {} }))
            assert.same({ 1, 2, 3 }, core.copy({ 1, 2, 3 }))
        end)

        it('creates copies that are not reference equal', function()
            local original = {}
            assert.is_not_equal(original, core.copyList(original))
        end)

        it('does not copy metatables', function()
            assert.is_nil(getmetatable(core.copyList(setmetatable({}, {}))))
        end)
    end)

    describe('default', function()
        it('returns the value if it is non-nil', function()
            assert.is_true(core.default(true, false))
            assert.is_false(core.default(false, true))
            assert.equal(1, core.default(1, 2))
        end)

        it('returns the default if the value is nil', function()
            assert.is_true(core.default(nil, true))
            assert.is_false(core.default(nil, false))
            assert.equal(2, core.default(nil, 2))
        end)
    end)

    describe('deepcopy', function()
        it('creates equivalent copies', function()
            assert.same({}, core.deepcopy({}))
            assert.same({ {} }, core.deepcopy({ {} }))
            assert.same({ 1, 2, 3 }, core.deepcopy({ 1, 2, 3 }))
            assert.same({ hello = 'world' }, core.deepcopy({ hello = 'world' }))
            assert.same({ [true] = false }, core.deepcopy({ [true] = false }))
        end)

        it('creates copies that are not reference equal', function()
            local original = {}
            assert.is_not_equal(original, core.deepcopy(original))
        end)

        it('does not copy metatables', function()
            assert.is_nil(getmetatable(core.deepcopy(setmetatable({}, {}))))
        end)

        it('creates copies with child tables that are not reference equal', function()
            local nested = {}
            local original = { nested }

            local nestedExpected = {}

            assert.same({ nestedExpected }, core.deepcopy(original))
            assert.is_not_equal(nestedExpected, core.deepcopy(original)[1])
        end)

        it('handles cycles', function()
            local original = {}
            original[1] = original
            original[original] = 1

            local copy = core.deepcopy(original)
            assert.equal(copy[1], copy)
            assert.equal(copy[copy], 1)
        end)

        it('creates deep copies of table keys', function()
            local key = { hello = 'world' }
            local original = { [key] = true }

            local copy = core.deepcopy(original)
            local copyKey
            for k in pairs(copy) do copyKey = k end

            assert.same(key, copyKey)
            assert.is_true(copy[copyKey])
            assert.is_nil(copy[key])
        end)
    end)

    describe('endsWith', function()
        it('returns false if the comparison argument is not given', function()
            assert.is_false(core.endsWith('hello'))
        end)

        it('returns true if the comparison argument is empty', function()
            assert.is_true(core.endsWith('hello', ''))
        end)

        it('returns true if the text ends with the comparison argument', function()
            assert.is_true(core.endsWith('hello', 'o'))
            assert.is_true(core.endsWith('hello', 'llo'))
            assert.is_true(core.endsWith('hello', 'hello'))
        end)

        it('returns false if the text does not end with the comparison argument', function()
            assert.is_false(core.endsWith('hello', 'he'))
            assert.is_false(core.endsWith('hello', 'hello world'))
        end)
    end)

    describe('entry', function()
        it('returns an entry with the given values', function()
            assert.same({ 'entrykey', 'entryvalue' }, core.entry('entrykey', 'entryvalue'))
        end)
    end)

    describe('escape', function()
        it('replaces special characters', function()
            assert.equal('%[%]%(%)%+%-%*%?%.%^%$%%', core.escape('[]()+-*?.^$%'))
        end)

        it('does not replace non-special characters', function()
            assert.equal('ABC123!', core.escape('ABC123!'))
        end)
    end)

    describe('escapeRichText', function()
        it('replaces special characters', function()
            assert.equal('hello &lt;SPACE&gt; world', core.escapeRichText('hello <SPACE> world'))
        end)
    end)

    describe('extend', function()
        it('returns the first argument', function()
            local t = { a = 1 }
            assert.equal(t, core.extend(t))
        end)

        it('adds elements from a table to the destination table', function()
            assert.same({ a = 1, b = 2, c = 3 }, core.extend({ a = 1 }, { b = 2, c = 3 }))
        end)

        it('adds elements from multiple tables to the destination table', function()
            assert.same({ a = 1, b = 2, c = 3, d = 4 }, core.extend({ a = 1 }, { b = 2 }, { c = 3, d = 4 }))
        end)
    end)

    describe('extendCopy', function()
        it('returns a copy of the first argument', function()
            local t = { a = 1 }
            local result = core.extendCopy(t)

            assert.same(t, result)
            assert.is_not_equal(t, result)
        end)

        it('adds elements from a table to the destination table', function()
            assert.same({ a = 1, b = 2, c = 3 }, core.extendCopy({ a = 1 }, { b = 2, c = 3 }))
        end)

        it('adds elements from multiple tables to the destination table', function()
            assert.same({ a = 1, b = 2, c = 3, d = 4 }, core.extendCopy({ a = 1 }, { b = 2 }, { c = 3, d = 4 }))
        end)
    end)

    describe('filter', function()
        it('filters elements according to the predicate', function()
            assert.same(_000, core.filter(isZero, _000))
            assert.same({ 0 }, core.filter(isZero, n01))
            assert.same({}, core.filter(isZero, p12))
        end)
    end)

    describe('getActivatedMods', function()
        setup(function()
            clearActivatedModsCache()
            zomboid.stub_activated_mods({ 'OmiLibrary', 'OmiChat' }):auto_revert()
        end)

        after_each(clearActivatedModsCache)

        it('returns a list of activated mod IDs', function()
            assert.same({ 'OmiLibrary', 'OmiChat' }, core.getActivatedMods())
        end)

        it('caches the result of getting activated mods', function()
            local s = spy.on(_G, 'getActivatedMods')

            core.getActivatedMods()
            core.getActivatedMods()
            core.getActivatedMods()

            assert.spy(s).called(1)
        end)
    end)

    describe('getActivatedModSet', function()
        setup(function()
            zomboid.stub_activated_mods({ 'OmiLibrary', 'OmiChat' }):auto_revert()
        end)

        after_each(clearActivatedModsCache)

        it('returns a set of activated mod IDs', function()
            assert.same({ OmiLibrary = true, OmiChat = true }, core.getActivatedModsSet())
        end)

        it('caches the result of getting activated mods', function()
            local s = spy.on(_G, 'getActivatedMods')

            core.getActivatedModsSet()
            core.getActivatedModsSet()
            core.getActivatedModsSet()

            assert.spy(s).called(1)
        end)
    end)

    describe('getEntityValue', function()
        it('gets named entity references', function()
            assert.is_not_nil(core.getEntityValue('&laquo;'))
            assert.equal(string.char(171), core.getEntityValue('&laquo;'))
            assert.equal(string.char(187), core.getEntityValue('&raquo;'))
            assert.equal(string.char(255), core.getEntityValue('&yuml;'))
        end)

        it('gets numeric character references', function()
            assert.is_not_nil(core.getEntityValue('&#255;'))
            assert.equal(string.char(255), core.getEntityValue('&#255;'))
            assert.equal(string.char(100), core.getEntityValue('&#100;'))
        end)

        it('gets numeric character references in hex', function()
            assert.is_not_nil(core.getEntityValue('&#255;'))
            assert.equal(string.char(255), core.getEntityValue('&#255;'))
        end)

        it('returns nil for unknown references or invalid formats', function()
            assert.is_nil(core.getEntityValue('&LAQUO;'))
            assert.is_nil(core.getEntityValue('&unknown;'))
            assert.is_nil(core.getEntityValue('&#ten;'))
            assert.is_nil(core.getEntityValue('not a character reference'))
        end)

        it('returns nil if an error occurs in string.char', function()
            stub(string, 'char', function() error() end):auto_revert()

            core = reload_module('OmiLibrary/Module/Utils')
            assert.is_nil(core.getEntityValue('&#100000000;'))
        end)
    end)

    describe('getPlayerByUsername', function()
        local mockUsername = 'MockUsername'
        local player = zomboid.player({ username = mockUsername })
        teardown(zomboid.revert_players)

        describe('when called server-side', function()
            setup(zomboid.set_is_server)
            teardown(zomboid.revert_is_server)

            it('does not call getPlayerFromUsername', function()
                local s = spy.on(_G, 'getPlayerFromUsername')
                core.getPlayerByUsername(mockUsername)

                assert.spy(s).not_called()
            end)

            it('returns the player with the matching username', function()
                assert.equal(player, core.getPlayerByUsername(mockUsername))
            end)

            it('returns nil for an unknown username', function()
                assert.is_nil(core.getPlayerByUsername('unknown'))
            end)
        end)

        describe('when called client-side', function()
            it('calls getPlayerFromUsername', function()
                local s = spy.on(_G, 'getPlayerFromUsername')
                core = reload_module('OmiLibrary/Module/Utils')

                core.getPlayerByUsername(mockUsername)

                assert.spy(s).called_with(mockUsername)
            end)

            it('returns the player with the matching username', function()
                assert.equal(player, core.getPlayerByUsername(mockUsername))
            end)

            it('returns nil for an unknown username', function()
                assert.is_nil(core.getPlayerByUsername('unknown'))
            end)
        end)
    end)

    describe('includes', function()
        it('returns true if the list includes the value', function()
            assert.is_true(core.includes({ 1, 2, 3 }, 2))
        end)

        it('returns false if the list does not include the value', function()
            assert.is_false(core.includes({ 1, 2, 3 }, 4))
        end)
    end)

    describe('isinstance', function()
        it('returns false if an object or class is not provided', function()
            assert.is_false(core.isinstance())
            assert.is_false(core.isinstance({}))
            assert.is_false(core.isinstance(nil, {}))
        end)

        it('returns false for a table without a metatable', function()
            assert.is_false(core.isinstance({}, {}))
        end)

        it('returns false for a table with a different metatable', function()
            local cls = {}
            cls.__index = cls

            assert.is_false(core.isinstance(setmetatable({}, {}), cls))
        end)

        it('returns false for a frozen table', function()
            local cls = {}
            cls.__metatable = 'frozen'

            assert.is_false(core.isinstance(setmetatable({}, cls), {}))
        end)

        it('returns true for a direct subclass', function()
            local cls = {}
            cls.__index = cls

            assert.is_true(core.isinstance(setmetatable({}, cls), cls))
        end)

        it('returns true for a non-direct subclass', function()
            local base = {}
            base.__index = base

            local cls = setmetatable({}, base)
            cls.__index = cls

            assert.is_true(core.isinstance(setmetatable({}, cls), base))
        end)
    end)

    describe('isModActive', function()
        setup(function()
            zomboid.stub_activated_mods({ 'OmiLibrary', 'OmiChat' }):auto_revert()
            core = reload_module('OmiLibrary/Module/Utils')
        end)

        teardown(function()
            core = reload_module('OmiLibrary/Module/Utils')
        end)

        after_each(clearActivatedModsCache)

        it('returns true if a mod is activated', function()
            assert.is_true(core.isModActive('OmiChat'))
            assert.is_true(core.isModActive('OmiLibrary'))
        end)

        it('returns false if a mod is not activated', function()
            assert.is_false(core.isModActive('unknown'))
        end)

        it('caches the result of getting activated mods', function()
            local s = spy.on(_G, 'getActivatedMods')

            core.isModActive('OmiChat')
            core.isModActive('OmiLibrary')
            core.isModActive('unknown')

            assert.spy(s).called(1)
        end)
    end)

    describe('isNilOrWhitespace', function()
        it('returns true for a nil input', function()
            assert.is_true(core.isNilOrWhitespace())
        end)

        it('returns true for an empty input', function()
            assert.is_true(core.isNilOrWhitespace(''))
        end)

        it('returns true for a whitespace-only input', function()
            assert.is_true(core.isNilOrWhitespace('      '))
        end)

        it('returns false for a non-nil, non-empty input', function()
            assert.is_false(core.isNilOrWhitespace('hello world'))
        end)
    end)

    describe('iterMap', function()
        it('maps numeric keys', function()
            assert.same({ 1, 1, 1 }, core.pack(core.iterMap(increment, _000)))
        end)

        it('maps non-numeric keys', function()
            assert.same({ a = 1, b = 2 }, core.pack(core.iterMap(increment, { a = 0, b = 1 })))
        end)

        it('includes keys and values', function()
            local iterator = spy.new(core.iterMap(increment, { a = 0 }))

            iterator()
            assert.spy(iterator).returned_with('a', 1)
        end)
    end)

    describe('iterMapValues', function()
        it('maps numeric keys', function()
            assert.same({ 1, 1, 1 }, core.pack(core.iterMapValues(increment, _000)))
        end)

        it('includes only values', function()
            local iterator = spy.new(core.iterMapValues(increment, n12))

            iterator()
            assert.spy(iterator).returned_with(0)
        end)
    end)

    describe('iterMapList', function()
        it('maps numeric keys', function()
            assert.same({ 1, 1, 1 }, core.pack(core.iterMapList(increment, _000)))
        end)

        it('ignores non-numeric keys', function()
            assert.same({ 2 }, core.pack(core.iterMapList(increment, { a = 0, 1 } --[[@as any]])))
        end)

        it('includes keys and values', function()
            local iterator = spy.new(core.iterMapList(increment, n12))

            iterator()
            assert.spy(iterator).returned_with(1, 0)
        end)
    end)

    describe('iterMapListValues', function()
        it('maps numeric keys', function()
            assert.same({ 1, 1, 1 }, core.pack(core.iterMapListValues(increment, _000)))
        end)

        it('ignores non-numeric keys', function()
            assert.same({ 2 }, core.pack(core.iterMapListValues(increment, { a = 0, 1 } --[[@as any]])))
        end)

        it('includes only values', function()
            local iterator = spy.new(core.iterMapListValues(increment, n12))

            iterator()
            assert.spy(iterator).returned_with(0)
        end)
    end)

    describe('keys', function()
        it('returns table keys', function()
            local tab = { a = 1, b = 2 }
            local keys = core.keys(tab)

            assert.equal(2, #keys)
            assert.match('[ab]', keys[1] --[[@as string]])
            assert.match('[ab]', keys[2] --[[@as string]])
            assert.is_true(keys[1] ~= keys[2])
        end)
    end)

    describe('map', function()
        it('maps numeric keys', function()
            assert.same({ 1, 1, 1 }, core.map(increment, _000))
        end)

        it('maps non-numeric keys', function()
            assert.same({ a = 1, b = 2 }, core.map(increment, { a = 0, b = 1 }))
        end)
    end)

    describe('mapList', function()
        it('maps numeric keys', function()
            assert.same({ 1, 1, 1 }, core.mapList(increment, _000))
        end)

        it('ignores non-numeric keys', function()
            assert.same({ 2 }, core.mapList(increment, { a = 0, 1 } --[[@as any]]))
        end)
    end)

    describe('pack', function()
        it('packs key-value iterators into tables', function()
            assert.same({ 1, 2, 3 }, core.pack(ipairs({ 1, 2, 3 })))
            assert.same({ 1, 2, 3 }, core.pack(ipairs({ 1, 2, 3, a = 1 })))
            assert.same({ 1, 2, 3, a = 1 }, core.pack(pairs({ 1, 2, 3, a = 1 })))
        end)
    end)

    describe('packList', function()
        it('packs value iterators into tables', function()
            assert.same({ 1, 2, 3 }, core.packList(ipairs({ 1, 2, 3 })))
            assert.same({ 1, 2, 3, 'a' }, core.packList(pairs({ 1, 2, 3, a = 1 })))
            assert.same({ 1, 2, 3 }, core.packList(core.iterMapListValues(id, { 1, 2, 3 })))
        end)
    end)

    describe('randInt', function()
        it('returns a random integer from 1 to m when given one value', function()
            for _ = 1, 100 do
                assert.equal(1, core.randInt(1))
                assert.between(1, 10, core.randInt(10))
            end
        end)

        it('returns a random integer from m to n when given two values', function()
            for _ = 1, 100 do
                assert.between(0, 1, core.randInt(0, 1))
                assert.between(5, 10, core.randInt(5, 10))
            end
        end)
    end)

    describe('split', function()
        it('clears a given list', function()
            local list = { 'a' }
            core.split('', ';', list)

            assert.same({}, list)
        end)

        it('uses the given delimiter', function()
            assert.same({ '1', '2', '3' }, core.split('1,2,3', ','))
        end)

        it('defaults to comma if a delimiter is not given', function()
            assert.same({ '1', '2', '3' }, core.split('1,2,3'))
        end)

        it('does not return empty strings', function()
            assert.same({}, core.split(';;;;;;', ';'))
        end)

        it('trims strings', function()
            local result = core.split('  A,  B,C  ,  D  ,E  ')
            assert.same({ 'A', 'B', 'C', 'D', 'E' }, result)
        end)
    end)

    describe('replaceEntities', function()
        it('replaces character entities', function()
            local expected = string.char(191) .. 'c' .. string.char(243) .. 'mo?'
            assert.equal(expected, core.replaceEntities('&iquest;c&oacute;mo?'))
            assert.equal('hello world!', core.replaceEntities('hello world&#33;'))
        end)
    end)

    describe('setInterval', function()
        it('calls setInterval on a Scheduler', function()
            local f = function() end
            local _setInterval = stub(Scheduler, 'setInterval'):auto_revert()

            core.setInterval(1000, f)

            assert.spy(_setInterval).called_with(match._, 1000, f)
        end)
    end)

    describe('setIntervalUI', function()
        it('calls setIntervalUI on a Scheduler', function()
            local f = function() end
            local _setIntervalUI = stub(Scheduler, 'setIntervalUI'):auto_revert()

            core.setIntervalUI(f)

            assert.spy(_setIntervalUI).called_with(match._, f)
        end)
    end)

    describe('setTimeout', function()
        it('calls setTimeout on a Scheduler', function()
            local f = function() end
            local _setTimeout = stub(Scheduler, 'setTimeout'):auto_revert()

            core.setTimeout(1000, f)

            assert.spy(_setTimeout).called_with(match._, 1000, f)
        end)
    end)

    describe('startsWith', function()
        it('returns false if the comparison argument is not given', function()
            assert.is_false(core.startsWith('hello'))
        end)

        it('returns true if the comparison argument is empty', function()
            assert.is_true(core.startsWith('hello', ''))
        end)

        it('returns true if the text starts with the comparison argument', function()
            assert.is_true(core.startsWith('hello', 'h'))
            assert.is_true(core.startsWith('hello', 'hel'))
            assert.is_true(core.startsWith('hello', 'hello'))
        end)

        it('returns false if the text does not start with the comparison argument', function()
            assert.is_false(core.startsWith('hello', 'lo'))
            assert.is_false(core.startsWith('hello', 'hello world'))
        end)
    end)

    describe('trim', function()
        it('trims whitespace on either side of a string', function()
            assert.equal('hello world', core.trim('     hello world'))
            assert.equal('hello world', core.trim('hello world     '))
            assert.equal('hello world', core.trim('     hello world     '))
            assert.equal('hello world', core.trim('\n\nhello world\n\n'))
        end)

        it('does not trim whitespace within a string', function()
            assert.equal('hello   world', core.trim('hello   world'))
        end)
    end)

    describe('trimleft', function()
        it('trims whitespace on the left of a string', function()
            assert.equal('hello world', core.trimleft('     hello world'))
            assert.equal('hello world', core.trimleft('\n\nhello world'))
        end)

        it('does not trim whitespace on the right of a string', function()
            assert.equal('hello world     ', core.trimleft('hello world     '))
            assert.equal('hello world     ', core.trimleft('     hello world     '))
        end)

        it('does not trim whitespace within a string', function()
            assert.equal('hello   world', core.trimleft('hello   world'))
        end)
    end)

    describe('trimright', function()
        it('trims whitespace on the right of a string', function()
            assert.equal('hello world', core.trimright('hello world     '))
            assert.equal('hello world', core.trimright('hello world\n\n'))
        end)

        it('does not trim whitespace on the left of a string', function()
            assert.equal('     hello world', core.trimright('     hello world'))
            assert.equal('     hello world', core.trimright('     hello world     '))
        end)

        it('does not trim whitespace within a string', function()
            assert.equal('hello   world', core.trimright('hello   world'))
        end)
    end)

    describe('unescapeRichText', function()
        it('replaces &lt; and &gt; character references', function()
            assert.equal('hello <SPACE> world', core.unescapeRichText('hello &lt;SPACE&gt; world'))
        end)
    end)
end)
