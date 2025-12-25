---Contains system tests for interpolation.

local format = string.format

local function generateTests(args)
    if type(assert) ~= 'table' then
        error('cannot generate interpolation tests; assert was not passed to the module function')
    end

    if type(it) ~= 'function' then
        error('cannot generate interpolation tests; it function was not passed to the module function')
    end

    local cases = args.cases
    local tokens = args.tokens
    local options = args.options

    for _, case in pairs(cases) do
        local patt, expected = case[1], case[2]
        local name = #patt > 0
            and format('yields the expected value for the pattern %q', patt)
            or 'returns the empty string for an empty pattern'

        it(name, function() assert.interpolate_match(patt, expected, tokens, options) end)
    end
end

describe('#system interpolation', function()
    setup(function()
        zomboid.set_string('UI_Yes', 'Yes')
    end)

    teardown(zomboid.revert_strings)

    it('respects the allowTokens option', function()
        local tokens = { token = 1 }

        -- nothing provided → allow tokens
        assert.interpolate_match('$token', '1', tokens)

        -- true → allow tokens
        assert.interpolate_match('$token', '1', tokens, { allowTokens = true })

        -- false → treat tokens as text
        assert.interpolate_match('$token', '$token', tokens, { allowTokens = false })
    end)

    it('respects the allowFunctions option', function()
        -- default → allow functions
        assert.interpolate_match('$Upper(x)', 'X')

        -- true → allow functions
        assert.interpolate_match('$Upper(x)', 'X', nil, { allowFunctions = true })

        -- false → treat functions as tokens
        assert.interpolate_match('$Upper(x)', '(x)', nil, { allowFunctions = false })
        assert.interpolate_match('$Upper(x)', 'f(x)', { Upper = 'f' }, { allowFunctions = false })
    end)

    it('respects the allowCharacterEntities option', function()
        -- default → allow entities
        assert.interpolate_match('&#255;', string.char(255))

        -- true → allow entities
        assert.interpolate_match('&#255;', string.char(255), nil, { allowCharacterEntities = true })

        -- false → treat as text
        assert.interpolate_match('&#255;', '&#255;', nil, { allowCharacterEntities = false })
    end)

    it('respects the allowMultiMaps option', function()
        -- default → allow multi-maps
        assert.interpolate_match('@(message:hello)', 'hello')

        -- true → allow multi-maps
        assert.interpolate_match('@(message:hello)', 'hello', nil, { allowMultiMaps = true })

        -- false → treat as text
        assert.interpolate_match('@(message:hello)', '@(message:hello)', nil, { allowMultiMaps = false })
    end)

    it('respects the requireCustomTokenUnderscore option', function()
        -- default → require underscore
        assert.interpolate_match('$Set(token 1)$token', '')

        -- true → require underscore
        assert.interpolate_match('$Set(token 1)$token', '', nil, { requireCustomTokenUnderscore = true })

        -- false → don't require underscore
        assert.interpolate_match('$Set(token 1)$token', '1', nil, { requireCustomTokenUnderscore = false })
    end)

    it('respects the caseSensitiveFunctions option', function()
        -- default → case-sensitive
        assert.interpolate_match('$upper(hi)', '')
        assert.interpolate_match('$Upper(hi)', 'HI')
        assert.interpolate_match('$UPPER(hi)', '')

        -- true → case-sensitive
        assert.interpolate_match('$upper(hi)', '', nil, { caseSensitiveFunctions = true })
        assert.interpolate_match('$Upper(hi)', 'HI', nil, { caseSensitiveFunctions = true })
        assert.interpolate_match('$UPPER(hi)', '', nil, { caseSensitiveFunctions = true })

        -- false → case-insensitive
        assert.interpolate_match('$upper(hi)', 'HI', nil, { caseSensitiveFunctions = false })
        assert.interpolate_match('$Upper(hi)', 'HI', nil, { caseSensitiveFunctions = false })
        assert.interpolate_match('$UPPER(hi)', 'HI', nil, { caseSensitiveFunctions = false })
    end)

    it('respects the checkNumericTokens options', function()
        local tokens = { [2] = 200, [3] = 300, ['3'] = 'three hundred' }

        -- default → check numeric tokens
        assert.interpolate_match('$2', '200', tokens)
        assert.interpolate_match('$3', 'three hundred', tokens)

        -- true → check numeric tokens
        assert.interpolate_match('$2', '200', tokens, { checkNumericTokens = true })
        assert.interpolate_match('$3', 'three hundred', tokens, { checkNumericTokens = true })

        -- false → do not check numeric tokens
        assert.interpolate_match('$2', '', tokens, { checkNumericTokens = false })
        assert.interpolate_match('$3', 'three hundred', tokens, { checkNumericTokens = false })
    end)

    generateTests {
        tokens = {
            ['1'] = 100,
            token = 'value',
            other = 's',
        },

        options = {
            caseSensitiveFunctions = false,
            libraryExtra = {
                Custom = function() return 'custom result' end,
            },
        },

        cases = {
            -- text
            { '', '' },
            { '$$', '$' },
            { '(', '(' },
            { '()', '()' },
            { '``', '``' },
            { '$$ $@ $) $( $: $;', '$ @ ) ( : ;' },
            { 'hello world', 'hello world' },
            { '$str(``)', '' },
            { '$str(`hello world`)', 'hello world' },
            { '$str(`$$ $@ $) $( $: $;`)', '$ @ ) ( : ;' },

            -- tokens
            { '$unknown', '' },
            { '$other', 's' },
            { 'hello $unknown', 'hello ' },
            { '$1', '100' },
            { '$$1', '$1' },
            { '$$$1', '$100' },
            { '$token', 'value' },
            { '$TOKEN', '' },
            { '$$token', '$token' },
            { '$token$other', 'values' },
            { '$token(', 'value(' },

            -- character entities
            { '&#255;', string.char(255) },
            { '&laquo;', string.char(171) },
            { '&Laquo;', '&Laquo;' },
            { '$len(hello&#32;world)', '11' },
            { '&unknown;', '&unknown;' },

            -- extra library functions
            { '$custom()', 'custom result' },

            --#region At-maps
            { '@()', '' },
            { '@(:A)', '' },
            { '@(A:)', '' },
            { '$len(@(A:))', 1 },
            { '@(A)', 'A' },
            { '@(A:A)', 'A' },
            { '@(A;2)', 'A' },
            { '@(1:A)', 'A' },
            { '@(B;A)', 'B' },
            { '@(@(A))', 'A' },
            { '@(@(A;B))', 'A' },
            { '@(A:B', '@(A:B' },
            { '@(hello world)', 'hello world' },

            { '$index(@(A:B) A)', 'B' },
            { '$index(@(A;B) A)', 'A' },
            { '$index(@(A;B) B)', 'B' },
            { '$nthvalue(@(A;B) 1)', 'A' },
            { '$nthvalue(@(A;B) 2)', 'B' },

            { '@(@(A;B): C)', 'C' },
            { '$index(@(@(A;B): C) A)', 'C' },
            { '$index(@(@(A;B): C) B)', 'C' },

            { '$index(@(@(A;B)) A)', 'A' },
            { '$index(@(@(A;B)) B)', 'B' },
            --#endregion

            --#region Math functions
            { '$pi()', math.pi },
            { '$isnan()', '' },
            { '$abs()', '' },
            { '$acos()', '' },
            { '$asin()', '' },
            { '$atan()', '' },
            { '$atan2()', '' },
            { '$atan2(1)', '' },
            { '$ceil()', '' },
            { '$cos()', '' },
            { '$cosh()', '' },
            { '$deg()', '' },
            { '$exp()', '' },
            { '$floor()', '' },
            { '$fmod()', '' },
            { '$fmod(1)', '' },
            { '$frexp()', '' },
            { '$int()', '' },
            { '$ldexp()', '' },
            { '$ldexp(1)', '' },
            { '$log()', '' },
            { '$log10()', '' },
            { '$max()', '' },
            { '$min()', '' },
            { '$mod()', '' },
            { '$mod(1)', '' },
            { '$modf()', '' },
            { '$num()', '' },
            { '$pow()', '' },
            { '$pow(1)', '' },
            { '$rad()', '' },
            { '$sin()', '' },
            { '$sinh()', '' },
            { '$sqrt()', '' },
            { '$tan()', '' },
            { '$tanh()', '' },

            { '$isnan(1)', '' },
            { '$isnan($log(-1))', true },

            { '$abs(a)', '' },
            { '$abs(0)', '0' },
            { '$abs(1)', '1' },
            { '$abs(-100)', '100' },

            { '$acos(-1)', math.acos(-1) },
            { '$int($acos(0))', '1' },
            { '$int($acos(1))', '0' },

            { '$asin(1)', math.asin(1) },
            { '$asin(-1)', math.asin(-1) },
            { '$int($asin(0))', '0' },

            { '$atan(0)', math.atan(0) },
            { '$atan(1)', math.atan(1) },
            { '$atan2(0 0)', math.atan2(0, 0) },
            { '$atan2(1 1)', math.atan2(1, 1) },

            { '$ceil(0)', '0' },
            { '$ceil(0.1)', '1' },
            { '$ceil(1.9)', '2' },
            { '$eq($ceil(-0.1) 0)', true },
            { '$ceil(-1.1)', '-1' },

            { '$cos(0)', math.cos(0) },
            { '$cos($pi())', math.cos(math.pi) },
            { '$cosh(0)', math.cosh(0) },
            { '$cosh($pi())', math.cosh(math.pi) },

            { '$deg(0)', math.deg(0) },
            { '$deg($pi())', math.deg(math.pi) },

            { '$exp(0)', math.exp(0) },
            { '$exp(1)', math.exp(1) },

            { '$floor(0.3)', 0 },
            { '$floor(1.1)', 1 },
            { '$floor(-0.1)', -1 },

            { '$fmod(0 1)', math.fmod(0, 1) },
            { '$fmod(1 2)', math.fmod(1, 2) },
            { '$fmod(5 3)', math.fmod(5, 3) },

            { '$frexp(1)', math.frexp(1) },
            { '$index($frexp(1) 2)', select(2, math.frexp(1)) },
            { '$concats(, $frexp(1))', table.concat({ math.frexp(1) }, ',') },

            { '$int(0)', 0 },
            { '$int(-1)', -1 },
            { '$int(1.1)', 1 },

            { '$ldexp(1 2)', math.ldexp(1, 2) },
            ---@diagnostic disable-next-line: param-type-mismatch
            { '$ldexp(1 0.5)', math.ldexp(1, 0.5) },
            ---@diagnostic disable-next-line: param-type-mismatch
            { '$ldexp(1 000 . 5000)', math.ldexp(1, 0.5) },

            { '$log(1)', math.log(1) },
            { '$log10(10)', math.log10(10) },

            { '$max(1)', '1' },
            { '$max(-1 -100)', '-1' },
            { '$max(1 2 3)', '3' },
            { '$max(1 2 3 0 -1)', '3' },
            { '$max(a b c)', 'c' },
            { '$max(a b c 1)', 'c' },

            { '$min(1)', '1' },
            { '$min(-1 -100)', '-100' },
            { '$min(1 2 3)', '1' },
            { '$min(1 2 3 0 -1)', '-1' },
            { '$min(a b c)', 'a' },
            { '$min(a b c 1)', '1' },

            { '$mod(0 1)', '0' },
            { '$mod(1 2)', '1' },
            { '$mod(3 2)', '1' },
            { '$mod(2 3)', '2' },
            { '$mod(-2 3)', '1' },

            { '$modf(1.5)', math.modf(1.5) },
            { '$index($modf(1.5) 2)', select(2, math.modf(1.5)) },
            { '$concats(, $modf(1.5))', table.concat({ math.modf(1.5) }, ',') },

            { '$num(a)', '' },
            { '$num(1)', '1' },
            { '$num(-4)', '-4' },
            { '$num(1 2 3)', '123' },

            { '$pow(2 3)', '8' },
            { '$pow(2 -1)', '0.5' },

            { '$rad(0)', '0' },
            { '$rad(180)', math.pi },

            { '$sin(0)', math.sin(0) },
            { '$sin(1)', math.sin(1) },
            { '$sinh(0)', math.sinh(0) },
            { '$sinh(1)', math.sinh(1) },

            { '$sqrt(1)', '1' },
            { '$sqrt(4)', '2' },
            { '$sqrt(9)', '3' },

            { '$tan(0)', math.tan(0) },
            { '$tan(1)', math.tan(1) },
            { '$tanh(0)', math.tanh(0) },
            { '$tanh(1)', math.tanh(1) },
            --#endregion

            --#region String functions
            { '$str()', '' },
            { '$lower()', '' },
            { '$upper()', '' },
            { '$reverse()', '' },
            { '$trim()', '' },
            { '$trimleft()', '' },
            { '$trimright()', '' },
            { '$first()', '' },
            { '$last()', '' },
            { '$contains()', true },
            { '$startswith()', true },
            { '$endswith()', true },
            { '$concat()', '' },
            { '$concats()', '' },
            { '$len()', '0' },
            { '$capitalize()', '' },
            { '$punctuate()', '.' },
            { '$gsub()', '' },
            { '$sub()', '' },
            { '$index()', '' },
            { '$match()', '' },
            { '$char()', '' },
            { '$byte()', '' },
            { '$rep()', '' },

            { '$lower(Hello)', 'hello' },
            { '$upper(Hello)', 'HELLO' },
            { '$reverse(hello)', 'olleh' },
            { '$trimleft(`  hello  `)', 'hello  ' },
            { '$trimright(`  hello  `)', '  hello' },
            { '$trim(`  hello  `)', 'hello' },
            { '$first(hello)', 'h' },
            { '$last(hello)', 'o' },

            { '$startswith(hello h)', true },
            { '$startswith(hello o)', '' },
            { '$endswith(hello o)', true },
            { '$endswith(hello h)', '' },

            { '$concat(a b c)', 'abc' },
            { '$concats(`` a b c)', 'abc' },
            { '$concats(, a b c)', 'a,b,c' },

            { '$len(hello)', '5' },
            { '$len(hello world)', '10' },
            { '$len(`hello world`)', '11' },

            { '$capitalize(hello)', 'Hello' },
            { '$capitalize(`hello world`)', 'Hello world' },

            { '$punctuate(hello)', 'hello.' },
            { '$punctuate(hello.)', 'hello.' },
            { '$punctuate(hello ?)', 'hello?' },
            { '$punctuate(hello,)', 'hello,' },
            { '$punctuate(hello, ?)', 'hello,' },
            { '$punctuate(hello. ? ,)', 'hello.?' },

            { '$gsub(hello)', 'hello' },
            { '$gsub(hello h)', 'ello' },
            { '$gsub(hello w)', 'hello' },
            { '$gsub(hello l)', 'heo' },
            { '$gsub(hello l L)', 'heLLo' },
            { '$gsub(hello l L 1)', 'heLlo' },
            { '$index($gsub(hello) 2)', '6' },
            { '$index($gsub(hello h) 2)', '1' },
            { '$index($gsub(hello w) 2)', '0' },

            { '$sub(hello 1)', 'hello' },
            { '$sub(hello 2)', 'ello' },
            { '$sub(hello 5)', 'o' },
            { '$sub(hello 6)', '' },
            { '$sub(hello 2 4)', 'ell' },
            { '$sub(hello 2 -2)', 'ell' },
            { '$sub(hello 1 5)', 'hello' },

            { '$index(hello 1)', 'h' },
            { '$index(hello 2)', 'e' },
            { '$index(hello 3)', 'l' },
            { '$index(hello 4)', 'l' },
            { '$index(hello 5)', 'o' },
            { '$index(hello -1)', 'o' },
            { '$index(hello -6)', '' },
            { '$index(hello -6 H)', 'H' },

            { '$match(hello h)', 'h' },
            { '$match(hello h 2)', '' },
            { '$match(hello %w)', 'h' },
            { '$match(hello %w 2)', 'e' },
            { '$match(hello h%wl)', 'hel' },
            { '$match(1.3 %d%.%d)', '1.3' },
            { '$match(hello %d%.%d)', '' },

            { '$char(97)', 'a' },
            { '$char(97 98 99)', 'abc' },
            { '$char(@(97;98;99))', 'abc' },
            { '$char(invalid)', '' },
            { '$char(@(97;98;invalid))', '' },

            { '$byte(a)', '97' },
            { '$byte(hello)', '104' },
            { '$index($byte(hello 1 2) 2)', '101' },
            { '$byte(a invalid)', '' },
            { '$byte(a 1 invalid)', '' },

            { '$rep(a)', '' },
            { '$rep(a 1)', 'a' },
            { '$rep(a 5)', 'aaaaa' },
            --#endregion

            --#region Boolean functions
            { '$not()', true },
            { '$eq()', true },
            { '$neq()', '' },
            { '$gt()', '' },
            { '$lt()', '' },
            { '$gte()', true },
            { '$lte()', true },
            { '$any()', '' },
            { '$all()', '' },
            { '$if()', '' },
            { '$unless()', '' },
            { '$ifelse()', '' },

            { '$not(``)', true },
            { '$not(1)', '' },
            { '$not(false)', '' },
            { '$not(true)', '' },
            { '$not(@())', true },
            { '$not(@(A))', '' },

            { '$eq(1 1)', true },
            { '$eq(1 2)', '' },
            { '$eq(`1` 1)', true },
            { '$neq(1 1)', '' },
            { '$neq(1 2)', true },
            { '$neq(`1` 1)', '' },

            { '$gt(1 2)', '' },
            { '$gt(2 1)', true },
            { '$gt(1 -1)', true },
            { '$gt(-1 0)', '' },
            { '$gte(1 2)', '' },
            { '$gte(2 1)', true },
            { '$gte(1 -1)', true },
            { '$gte(-1 0)', '' },
            { '$gte(1 1)', true },
            { '$lt(1 2)', true },
            { '$lt(2 1)', '' },
            { '$lt(1 -1)', '' },
            { '$lt(-1 0)', true },
            { '$lte(1 2)', true },
            { '$lte(2 1)', '' },
            { '$lte(1 -1)', '' },
            { '$lte(-1 0)', true },
            { '$lte(1 1)', true },

            { '$any(1 2)', '1' },
            { '$any(`` 2)', '2' },
            { '$all(1 2)', '2' },
            { '$all(1 ``)', '' },

            { '$if(`` hello)', '' },
            { '$if(1 hello)', 'hello' },
            { '$if(1 hello world)', 'helloworld' },
            { '$if(1 `hello world`)', 'hello world' },

            { '$unless(1 hello)', '' },
            { '$unless(`` hello)', 'hello' },
            { '$unless(`` hello world)', 'helloworld' },
            { '$unless(`` `hello world`)', 'hello world' },

            { '$ifelse(1 @(true:hi;false:bye))', 'hi' },
            { '$ifelse(`` @(true:hi;false:bye))', 'bye' },
            { '$ifelse(1 @(true:hi world;false:bye))', 'hi world' },
            { '$ifelse(`` @(true:hi world;false:bye world))', 'bye world' },
            --#endregion

            --#region Map functions
            { '$list(@())', '' },
            { '$list(1 2 3)', '1' },
            { '$list(@(1;2;3))', '1' },
            { '$index($list(1 2 3) 2)', '2' },

            { '$map()', '' },
            { '$map(upper)', '' },
            { '$map(upper @())', '' },
            { '$map(upper @(a;b;c))', 'A' },
            { '$concat($map(upper @(a;b;c)))', 'ABC' },
            { '$concat($map(punctuate @(a;b;c) `! `))', 'a! b! c! ' },

            { '$len(@())', '0' },
            { '$len(@(A))', '1' },
            { '$len(@(A;B;C))', '3' },
            { '$len(@(A;B;C;A))', '4' },

            { '$concat(@())', '' },
            { '$concat(@(A;B;C))', 'ABC' },

            { '$concats(, @())', '' },
            { '$concats(, @(A;B;C))', 'A,B,C' },

            { '$nthvalue()', '' },
            { '$nthvalue(@())', '' },
            { '$nthvalue(@() 2)', '' },
            { '$nthvalue(@(A;B;C) 2)', 'B' },

            { '$first(@())', '' },
            { '$first(@(A;B;C))', 'A' },
            { '$last(@())', '' },
            { '$last(@(A;B;C))', 'C' },

            { '$get()', '' },
            { '$get(@() A)', '' },
            { '$get(@(A) A)', 'A' },
            { '$get(@(A;B;C) A)', 'A' },
            { '$get(@(A;B;C) B)', 'B' },
            { '$get(@(A:1;A:2) A)', '1' },

            { '$has()', '' },
            { '$has(@(A) A)', 'true' },
            { '$has(@(A) B)', '' },

            { '$index(@() A)', '' },
            { '$index(@(A;B;C) A)', 'A' },
            { '$index(@(A;B;C;A) A)', 'A' },
            { '$index(@(A:1;A:2) A)', '1' },
            { '$len($index(@(A;B;C;A) A))', '2' },
            { '$len($index(@(A:1;A:2) A))', '2' },
            { '$nthvalue($index(@(A:1;A:2) A) 2)', '2' },

            { '$unique(@())', '' },
            { '$unique(1)', '' },
            { '$unique(@(A))', 'A' },
            { '$len($unique(@(A;B)))', '2' },
            { '$len($unique(@(A;B;A)))', '2' },
            --#endregion

            --#region Mutator functions
            { '$random(`not a number`)', '' },
            { '$random(1 string)', '' },

            { '$choose()', '' },
            { '$choose(A)', 'A' },
            { '$set(_rand $choose(A B C))$not(_rand)', '' },
            { '$eq($randomseed(1)$choose(A B C) $randomseed(1)$choose(A B C))', true },

            { '$eq($randomseed(5)$random() $randomseed(5)$random())', true },
            { '$eq($randomseed(5)$choose(@(A;B)) $randomseed(5)$choose(@(A;B)))', true },

            { '$set(_rand $random(5))$all($gte($_rand 1) $lte($_rand 5))', true },
            { '$set(_rand $random(2 5))$all($gte($_rand 2) $lte($_rand 5))', true },

            { '$set(unknown value)$unknown', '' },
            { '$set(_token value)$_token', 'value' },

            { '$set(_token h e l l o)$_token', 'hello' },
            --#endregion

            --#region PZ functions
            { '$GetText(UI_Yes)', 'Yes' },
            { '$GetText(UI_Unknown)', 'UI_Unknown' },
            { '$GetTextOrNull(UI_Yes)', 'Yes' },
            { '$GetTextOrNull(UI_Unknown)', '' },
            --#endregion
        },
    }
end)
