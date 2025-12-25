---Data for pluralization rules.
---This is a generated file; see https://github.com/omarkmu/pz-utils.

return function()
    return {
        cardinal = {
            {
                locales = {
                    'af',
                    'an',
                    'asa',
                    'az',
                    'bal',
                    'bem',
                    'bez',
                    'bg',
                    'brx',
                    'ce',
                    'cgg',
                    'chr',
                    'ckb',
                    'dv',
                    'ee',
                    'el',
                    'eo',
                    'eu',
                    'fo',
                    'fur',
                    'gsw',
                    'ha',
                    'haw',
                    'hu',
                    'jgo',
                    'jmc',
                    'ka',
                    'kaj',
                    'kcg',
                    'kk',
                    'kkj',
                    'kl',
                    'ks',
                    'ksb',
                    'ku',
                    'ky',
                    'lb',
                    'lg',
                    'mas',
                    'mgo',
                    'ml',
                    'mn',
                    'mr',
                    'nah',
                    'nb',
                    'nd',
                    'ne',
                    'nn',
                    'nnh',
                    'no',
                    'nr',
                    'ny',
                    'nyn',
                    'om',
                    'or',
                    'os',
                    'pap',
                    'ps',
                    'rm',
                    'rof',
                    'rwk',
                    'saq',
                    'sd',
                    'sdh',
                    'seh',
                    'sn',
                    'so',
                    'sq',
                    'ss',
                    'ssy',
                    'st',
                    'syr',
                    'ta',
                    'te',
                    'teo',
                    'tig',
                    'tk',
                    'tn',
                    'tr',
                    'ts',
                    'ug',
                    'uz',
                    've',
                    'vo',
                    'vun',
                    'wae',
                    'xh',
                    'xog',
                },
                rules = {
                    one = { { { op = 'n', value = 1 } } },
                },
            },
            {
                locales = { 'ak', 'bho', 'csw', 'guw', 'ln', 'mg', 'nso', 'pa', 'ti', 'wa' },
                rules = {
                    one = { { { op = 'n', values = { { start = 0, stop = 1 } } } } },
                },
            },
            {
                locales = { 'am', 'as', 'bn', 'doi', 'fa', 'gu', 'hi', 'kn', 'kok', 'kok-Latn', 'pcm', 'zu' },
                rules = {
                    one = { { { op = 'i', value = 0 } }, { { op = 'n', value = 1 } } },
                },
            },
            {
                locales = { 'ar', 'ars' },
                rules = {
                    zero = { { { op = 'n', value = 0 } } },
                    one = { { { op = 'n', value = 1 } } },
                    two = { { { op = 'n', value = 2 } } },
                    few = { { { op = 'n', mod = 100, values = { { start = 3, stop = 10 } } } } },
                    many = { { { op = 'n', mod = 100, values = { { start = 11, stop = 99 } } } } },
                },
            },
            {
                locales = {
                    'ast',
                    'de',
                    'en',
                    'et',
                    'fi',
                    'fy',
                    'gl',
                    'ia',
                    'ie',
                    'io',
                    'lij',
                    'nl',
                    'sc',
                    'sv',
                    'sw',
                    'ur',
                    'yi',
                },
                rules = {
                    one = { { { op = 'i', value = 1 }, { op = 'v', value = 0 } } },
                },
            },
            {
                locales = { 'be' },
                rules = {
                    one = { { { op = 'n', mod = 10, value = 1 }, { op = 'n', mod = 100, neq = true, value = 11 } } },
                    few = {
                        {
                            { op = 'n', mod = 10, values = { { start = 2, stop = 4 } } },
                            { op = 'n', mod = 100, neq = true, values = { { start = 12, stop = 14 } } },
                        },
                    },
                    many = {
                        { { op = 'n', mod = 10, value = 0 } },
                        { { op = 'n', mod = 10, values = { { start = 5, stop = 9 } } } },
                        { { op = 'n', mod = 100, values = { { start = 11, stop = 14 } } } },
                    },
                },
            },
            {
                locales = { 'blo', 'cv', 'ksh' },
                rules = {
                    zero = { { { op = 'n', value = 0 } } },
                    one = { { { op = 'n', value = 1 } } },
                },
            },
            {
                locales = { 'br' },
                rules = {
                    one = {
                        {
                            { op = 'n', mod = 10, value = 1 },
                            {
                                op = 'n',
                                mod = 100,
                                neq = true,
                                values = { { start = 11 }, { start = 71 }, { start = 91 } },
                            },
                        },
                    },
                    two = {
                        {
                            { op = 'n', mod = 10, value = 2 },
                            {
                                op = 'n',
                                mod = 100,
                                neq = true,
                                values = { { start = 12 }, { start = 72 }, { start = 92 } },
                            },
                        },
                    },
                    few = {
                        {
                            { op = 'n', mod = 10, values = { { start = 3, stop = 4 }, { start = 9 } } },
                            {
                                op = 'n',
                                mod = 100,
                                neq = true,
                                values = {
                                    { start = 10, stop = 19 },
                                    { start = 70, stop = 79 },
                                    { start = 90, stop = 99 },
                                },
                            },
                        },
                    },
                    many = { { { op = 'n', neq = true, value = 0 }, { op = 'n', mod = 1000000, value = 0 } } },
                },
            },
            {
                locales = { 'bs', 'hr', 'sh', 'sr' },
                rules = {
                    one = {
                        {
                            { op = 'v', value = 0 },
                            { op = 'i', mod = 10, value = 1 },
                            { op = 'i', mod = 100, neq = true, value = 11 },
                        },
                        { { op = 'f', mod = 10, value = 1 }, { op = 'f', mod = 100, neq = true, value = 11 } },
                    },
                    few = {
                        {
                            { op = 'v', value = 0 },
                            { op = 'i', mod = 10, values = { { start = 2, stop = 4 } } },
                            { op = 'i', mod = 100, neq = true, values = { { start = 12, stop = 14 } } },
                        },
                        {
                            { op = 'f', mod = 10, values = { { start = 2, stop = 4 } } },
                            { op = 'f', mod = 100, neq = true, values = { { start = 12, stop = 14 } } },
                        },
                    },
                },
            },
            {
                locales = { 'ca', 'it', 'lld', 'pt-PT', 'scn', 'vec' },
                rules = {
                    one = { { { op = 'i', value = 1 }, { op = 'v', value = 0 } } },
                    many = {
                        {
                            { op = 'e', value = 0 },
                            { op = 'i', neq = true, value = 0 },
                            { op = 'i', mod = 1000000, value = 0 },
                            { op = 'v', value = 0 },
                        },
                        { { op = 'e', neq = true, values = { { start = 0, stop = 5 } } } },
                    },
                },
            },
            {
                locales = { 'ceb', 'fil', 'tl' },
                rules = {
                    one = {
                        {
                            { op = 'v', value = 0 },
                            { op = 'i', values = { { start = 1 }, { start = 2 }, { start = 3 } } },
                        },
                        {
                            { op = 'v', value = 0 },
                            {
                                op = 'i',
                                mod = 10,
                                neq = true,
                                values = { { start = 4 }, { start = 6 }, { start = 9 } },
                            },
                        },
                        {
                            { op = 'v', neq = true, value = 0 },
                            {
                                op = 'f',
                                mod = 10,
                                neq = true,
                                values = { { start = 4 }, { start = 6 }, { start = 9 } },
                            },
                        },
                    },
                },
            },
            {
                locales = { 'cs', 'sk' },
                rules = {
                    one = { { { op = 'i', value = 1 }, { op = 'v', value = 0 } } },
                    few = { { { op = 'i', values = { { start = 2, stop = 4 } } }, { op = 'v', value = 0 } } },
                    many = { { { op = 'v', neq = true, value = 0 } } },
                },
            },
            {
                locales = { 'cy' },
                rules = {
                    zero = { { { op = 'n', value = 0 } } },
                    one = { { { op = 'n', value = 1 } } },
                    two = { { { op = 'n', value = 2 } } },
                    few = { { { op = 'n', value = 3 } } },
                    many = { { { op = 'n', value = 6 } } },
                },
            },
            {
                locales = { 'da' },
                rules = {
                    one = {
                        { { op = 'n', value = 1 } },
                        {
                            { op = 't', neq = true, value = 0 },
                            { op = 'i', values = { { start = 0 }, { start = 1 } } },
                        },
                    },
                },
            },
            {
                locales = { 'dsb', 'hsb' },
                rules = {
                    one = {
                        { { op = 'v', value = 0 }, { op = 'i', mod = 100, value = 1 } },
                        { { op = 'f', mod = 100, value = 1 } },
                    },
                    two = {
                        { { op = 'v', value = 0 }, { op = 'i', mod = 100, value = 2 } },
                        { { op = 'f', mod = 100, value = 2 } },
                    },
                    few = {
                        { { op = 'v', value = 0 }, { op = 'i', mod = 100, values = { { start = 3, stop = 4 } } } },
                        { { op = 'f', mod = 100, values = { { start = 3, stop = 4 } } } },
                    },
                },
            },
            {
                locales = { 'es' },
                rules = {
                    one = { { { op = 'n', value = 1 } } },
                    many = {
                        {
                            { op = 'e', value = 0 },
                            { op = 'i', neq = true, value = 0 },
                            { op = 'i', mod = 1000000, value = 0 },
                            { op = 'v', value = 0 },
                        },
                        { { op = 'e', neq = true, values = { { start = 0, stop = 5 } } } },
                    },
                },
            },
            {
                locales = { 'ff', 'hy', 'kab' },
                rules = {
                    one = { { { op = 'i', values = { { start = 0 }, { start = 1 } } } } },
                },
            },
            {
                locales = { 'fr' },
                rules = {
                    one = { { { op = 'i', values = { { start = 0 }, { start = 1 } } } } },
                    many = {
                        {
                            { op = 'e', value = 0 },
                            { op = 'i', neq = true, value = 0 },
                            { op = 'i', mod = 1000000, value = 0 },
                            { op = 'v', value = 0 },
                        },
                        { { op = 'e', neq = true, values = { { start = 0, stop = 5 } } } },
                    },
                },
            },
            {
                locales = { 'ga' },
                rules = {
                    one = { { { op = 'n', value = 1 } } },
                    two = { { { op = 'n', value = 2 } } },
                    few = { { { op = 'n', values = { { start = 3, stop = 6 } } } } },
                    many = { { { op = 'n', values = { { start = 7, stop = 10 } } } } },
                },
            },
            {
                locales = { 'gd' },
                rules = {
                    one = { { { op = 'n', values = { { start = 1 }, { start = 11 } } } } },
                    two = { { { op = 'n', values = { { start = 2 }, { start = 12 } } } } },
                    few = { { { op = 'n', values = { { start = 3, stop = 10 }, { start = 13, stop = 19 } } } } },
                },
            },
            {
                locales = { 'gv' },
                rules = {
                    one = { { { op = 'v', value = 0 }, { op = 'i', mod = 10, value = 1 } } },
                    two = { { { op = 'v', value = 0 }, { op = 'i', mod = 10, value = 2 } } },
                    few = {
                        {
                            { op = 'v', value = 0 },
                            {
                                op = 'i',
                                mod = 100,
                                values = {
                                    { start = 0 },
                                    { start = 20 },
                                    { start = 40 },
                                    { start = 60 },
                                    { start = 80 },
                                },
                            },
                        },
                    },
                    many = { { { op = 'v', neq = true, value = 0 } } },
                },
            },
            {
                locales = { 'he' },
                rules = {
                    one = {
                        { { op = 'i', value = 1 }, { op = 'v', value = 0 } },
                        { { op = 'i', value = 0 }, { op = 'v', neq = true, value = 0 } },
                    },
                    two = { { { op = 'i', value = 2 }, { op = 'v', value = 0 } } },
                },
            },
            {
                locales = { 'is' },
                rules = {
                    one = {
                        {
                            { op = 't', value = 0 },
                            { op = 'i', mod = 10, value = 1 },
                            { op = 'i', mod = 100, neq = true, value = 11 },
                        },
                        { { op = 't', mod = 10, value = 1 }, { op = 't', mod = 100, neq = true, value = 11 } },
                    },
                },
            },
            {
                locales = { 'iu', 'naq', 'sat', 'se', 'sma', 'smi', 'smj', 'smn', 'sms' },
                rules = {
                    one = { { { op = 'n', value = 1 } } },
                    two = { { { op = 'n', value = 2 } } },
                },
            },
            {
                locales = { 'kw' },
                rules = {
                    zero = { { { op = 'n', value = 0 } } },
                    one = { { { op = 'n', value = 1 } } },
                    two = {
                        {
                            {
                                op = 'n',
                                mod = 100,
                                values = {
                                    { start = 2 },
                                    { start = 22 },
                                    { start = 42 },
                                    { start = 62 },
                                    { start = 82 },
                                },
                            },
                        },
                        {
                            { op = 'n', mod = 1000, value = 0 },
                            {
                                op = 'n',
                                mod = 100000,
                                values = {
                                    { start = 1000, stop = 20000 },
                                    { start = 40000 },
                                    { start = 60000 },
                                    { start = 80000 },
                                },
                            },
                        },
                        { { op = 'n', neq = true, value = 0 }, { op = 'n', mod = 1000000, value = 100000 } },
                    },
                    few = {
                        {
                            {
                                op = 'n',
                                mod = 100,
                                values = {
                                    { start = 3 },
                                    { start = 23 },
                                    { start = 43 },
                                    { start = 63 },
                                    { start = 83 },
                                },
                            },
                        },
                    },
                    many = {
                        {
                            { op = 'n', neq = true, value = 1 },
                            {
                                op = 'n',
                                mod = 100,
                                values = {
                                    { start = 1 },
                                    { start = 21 },
                                    { start = 41 },
                                    { start = 61 },
                                    { start = 81 },
                                },
                            },
                        },
                    },
                },
            },
            {
                locales = { 'lag' },
                rules = {
                    zero = { { { op = 'n', value = 0 } } },
                    one = {
                        {
                            { op = 'i', values = { { start = 0 }, { start = 1 } } },
                            { op = 'n', neq = true, value = 0 },
                        },
                    },
                },
            },
            {
                locales = { 'lt' },
                rules = {
                    one = {
                        {
                            { op = 'n', mod = 10, value = 1 },
                            { op = 'n', mod = 100, neq = true, values = { { start = 11, stop = 19 } } },
                        },
                    },
                    few = {
                        {
                            { op = 'n', mod = 10, values = { { start = 2, stop = 9 } } },
                            { op = 'n', mod = 100, neq = true, values = { { start = 11, stop = 19 } } },
                        },
                    },
                    many = { { { op = 'f', neq = true, value = 0 } } },
                },
            },
            {
                locales = { 'lv', 'prg' },
                rules = {
                    zero = {
                        { { op = 'n', mod = 10, value = 0 } },
                        { { op = 'n', mod = 100, values = { { start = 11, stop = 19 } } } },
                        {
                            { op = 'v', value = 2 },
                            { op = 'f', mod = 100, values = { { start = 11, stop = 19 } } },
                        },
                    },
                    one = {
                        { { op = 'n', mod = 10, value = 1 }, { op = 'n', mod = 100, neq = true, value = 11 } },
                        {
                            { op = 'v', value = 2 },
                            { op = 'f', mod = 10, value = 1 },
                            { op = 'f', mod = 100, neq = true, value = 11 },
                        },
                        { { op = 'v', neq = true, value = 2 }, { op = 'f', mod = 10, value = 1 } },
                    },
                },
            },
            {
                locales = { 'mk' },
                rules = {
                    one = {
                        {
                            { op = 'v', value = 0 },
                            { op = 'i', mod = 10, value = 1 },
                            { op = 'i', mod = 100, neq = true, value = 11 },
                        },
                        { { op = 'f', mod = 10, value = 1 }, { op = 'f', mod = 100, neq = true, value = 11 } },
                    },
                },
            },
            {
                locales = { 'mo', 'ro' },
                rules = {
                    one = { { { op = 'i', value = 1 }, { op = 'v', value = 0 } } },
                    few = {
                        { { op = 'v', neq = true, value = 0 } },
                        { { op = 'n', value = 0 } },
                        {
                            { op = 'n', neq = true, value = 1 },
                            { op = 'n', mod = 100, values = { { start = 1, stop = 19 } } },
                        },
                    },
                },
            },
            {
                locales = { 'mt' },
                rules = {
                    one = { { { op = 'n', value = 1 } } },
                    two = { { { op = 'n', value = 2 } } },
                    few = {
                        { { op = 'n', value = 0 } },
                        { { op = 'n', mod = 100, values = { { start = 3, stop = 10 } } } },
                    },
                    many = { { { op = 'n', mod = 100, values = { { start = 11, stop = 19 } } } } },
                },
            },
            {
                locales = { 'pl' },
                rules = {
                    one = { { { op = 'i', value = 1 }, { op = 'v', value = 0 } } },
                    few = {
                        {
                            { op = 'v', value = 0 },
                            { op = 'i', mod = 10, values = { { start = 2, stop = 4 } } },
                            { op = 'i', mod = 100, neq = true, values = { { start = 12, stop = 14 } } },
                        },
                    },
                    many = {
                        {
                            { op = 'v', value = 0 },
                            { op = 'i', neq = true, value = 1 },
                            { op = 'i', mod = 10, values = { { start = 0, stop = 1 } } },
                        },
                        { { op = 'v', value = 0 }, { op = 'i', mod = 10, values = { { start = 5, stop = 9 } } } },
                        {
                            { op = 'v', value = 0 },
                            { op = 'i', mod = 100, values = { { start = 12, stop = 14 } } },
                        },
                    },
                },
            },
            {
                locales = { 'pt' },
                rules = {
                    one = { { { op = 'i', values = { { start = 0, stop = 1 } } } } },
                    many = {
                        {
                            { op = 'e', value = 0 },
                            { op = 'i', neq = true, value = 0 },
                            { op = 'i', mod = 1000000, value = 0 },
                            { op = 'v', value = 0 },
                        },
                        { { op = 'e', neq = true, values = { { start = 0, stop = 5 } } } },
                    },
                },
            },
            {
                locales = { 'ru', 'uk' },
                rules = {
                    one = {
                        {
                            { op = 'v', value = 0 },
                            { op = 'i', mod = 10, value = 1 },
                            { op = 'i', mod = 100, neq = true, value = 11 },
                        },
                    },
                    few = {
                        {
                            { op = 'v', value = 0 },
                            { op = 'i', mod = 10, values = { { start = 2, stop = 4 } } },
                            { op = 'i', mod = 100, neq = true, values = { { start = 12, stop = 14 } } },
                        },
                    },
                    many = {
                        { { op = 'v', value = 0 }, { op = 'i', mod = 10, value = 0 } },
                        { { op = 'v', value = 0 }, { op = 'i', mod = 10, values = { { start = 5, stop = 9 } } } },
                        {
                            { op = 'v', value = 0 },
                            { op = 'i', mod = 100, values = { { start = 11, stop = 14 } } },
                        },
                    },
                },
            },
            {
                locales = { 'sgs' },
                rules = {
                    one = { { { op = 'n', mod = 10, value = 1 }, { op = 'n', mod = 100, neq = true, value = 11 } } },
                    two = { { { op = 'n', value = 2 } } },
                    few = {
                        {
                            { op = 'n', neq = true, value = 2 },
                            { op = 'n', mod = 10, values = { { start = 2, stop = 9 } } },
                            { op = 'n', mod = 100, neq = true, values = { { start = 11, stop = 19 } } },
                        },
                    },
                    many = { { { op = 'f', neq = true, value = 0 } } },
                },
            },
            {
                locales = { 'shi' },
                rules = {
                    one = { { { op = 'i', value = 0 } }, { { op = 'n', value = 1 } } },
                    few = { { { op = 'n', values = { { start = 2, stop = 10 } } } } },
                },
            },
            {
                locales = { 'si' },
                rules = {
                    one = {
                        { { op = 'n', values = { { start = 0 }, { start = 1 } } } },
                        { { op = 'i', value = 0 }, { op = 'f', value = 1 } },
                    },
                },
            },
            {
                locales = { 'sl' },
                rules = {
                    one = { { { op = 'v', value = 0 }, { op = 'i', mod = 100, value = 1 } } },
                    two = { { { op = 'v', value = 0 }, { op = 'i', mod = 100, value = 2 } } },
                    few = {
                        { { op = 'v', value = 0 }, { op = 'i', mod = 100, values = { { start = 3, stop = 4 } } } },
                        { { op = 'v', neq = true, value = 0 } },
                    },
                },
            },
            {
                locales = { 'tzm' },
                rules = {
                    one = {
                        { { op = 'n', values = { { start = 0, stop = 1 } } } },
                        { { op = 'n', values = { { start = 11, stop = 99 } } } },
                    },
                },
            },
        },
        ordinal = {
            {
                locales = { 'as', 'bn' },
                rules = {
                    one = {
                        {
                            {
                                op = 'n',
                                values = {
                                    { start = 1 },
                                    { start = 5 },
                                    { start = 7 },
                                    { start = 8 },
                                    { start = 9 },
                                    { start = 10 },
                                },
                            },
                        },
                    },
                    two = { { { op = 'n', values = { { start = 2 }, { start = 3 } } } } },
                    few = { { { op = 'n', value = 4 } } },
                    many = { { { op = 'n', value = 6 } } },
                },
            },
            {
                locales = { 'az' },
                rules = {
                    one = {
                        {
                            {
                                op = 'i',
                                mod = 10,
                                values = {
                                    { start = 1 },
                                    { start = 2 },
                                    { start = 5 },
                                    { start = 7 },
                                    { start = 8 },
                                },
                            },
                        },
                        {
                            {
                                op = 'i',
                                mod = 100,
                                values = { { start = 20 }, { start = 50 }, { start = 70 }, { start = 80 } },
                            },
                        },
                    },
                    few = {
                        { { op = 'i', mod = 10, values = { { start = 3 }, { start = 4 } } } },
                        {
                            {
                                op = 'i',
                                mod = 1000,
                                values = {
                                    { start = 100 },
                                    { start = 200 },
                                    { start = 300 },
                                    { start = 400 },
                                    { start = 500 },
                                    { start = 600 },
                                    { start = 700 },
                                    { start = 800 },
                                    { start = 900 },
                                },
                            },
                        },
                    },
                    many = {
                        { { op = 'i', value = 0 } },
                        { { op = 'i', mod = 10, value = 6 } },
                        { { op = 'i', mod = 100, values = { { start = 40 }, { start = 60 }, { start = 90 } } } },
                    },
                },
            },
            {
                locales = { 'bal', 'fil', 'fr', 'ga', 'hy', 'lo', 'mo', 'ms', 'ro', 'tl', 'vi' },
                rules = {
                    one = { { { op = 'n', value = 1 } } },
                },
            },
            {
                locales = { 'be' },
                rules = {
                    few = {
                        {
                            { op = 'n', mod = 10, values = { { start = 2 }, { start = 3 } } },
                            { op = 'n', mod = 100, neq = true, values = { { start = 12 }, { start = 13 } } },
                        },
                    },
                },
            },
            {
                locales = { 'blo' },
                rules = {
                    zero = { { { op = 'i', value = 0 } } },
                    one = { { { op = 'i', value = 1 } } },
                    few = {
                        {
                            {
                                op = 'i',
                                values = {
                                    { start = 2 },
                                    { start = 3 },
                                    { start = 4 },
                                    { start = 5 },
                                    { start = 6 },
                                },
                            },
                        },
                    },
                },
            },
            {
                locales = { 'ca' },
                rules = {
                    one = { { { op = 'n', values = { { start = 1 }, { start = 3 } } } } },
                    two = { { { op = 'n', value = 2 } } },
                    few = { { { op = 'n', value = 4 } } },
                },
            },
            {
                locales = { 'cy' },
                rules = {
                    zero = {
                        { { op = 'n', values = { { start = 0 }, { start = 7 }, { start = 8 }, { start = 9 } } } },
                    },
                    one = { { { op = 'n', value = 1 } } },
                    two = { { { op = 'n', value = 2 } } },
                    few = { { { op = 'n', values = { { start = 3 }, { start = 4 } } } } },
                    many = { { { op = 'n', values = { { start = 5 }, { start = 6 } } } } },
                },
            },
            {
                locales = { 'en' },
                rules = {
                    one = { { { op = 'n', mod = 10, value = 1 }, { op = 'n', mod = 100, neq = true, value = 11 } } },
                    two = { { { op = 'n', mod = 10, value = 2 }, { op = 'n', mod = 100, neq = true, value = 12 } } },
                    few = { { { op = 'n', mod = 10, value = 3 }, { op = 'n', mod = 100, neq = true, value = 13 } } },
                },
            },
            {
                locales = { 'gd' },
                rules = {
                    one = { { { op = 'n', values = { { start = 1 }, { start = 11 } } } } },
                    two = { { { op = 'n', values = { { start = 2 }, { start = 12 } } } } },
                    few = { { { op = 'n', values = { { start = 3 }, { start = 13 } } } } },
                },
            },
            {
                locales = { 'gu', 'hi' },
                rules = {
                    one = { { { op = 'n', value = 1 } } },
                    two = { { { op = 'n', values = { { start = 2 }, { start = 3 } } } } },
                    few = { { { op = 'n', value = 4 } } },
                    many = { { { op = 'n', value = 6 } } },
                },
            },
            {
                locales = { 'hu' },
                rules = {
                    one = { { { op = 'n', values = { { start = 1 }, { start = 5 } } } } },
                },
            },
            {
                locales = { 'it', 'lld', 'sc', 'vec' },
                rules = {
                    many = {
                        {
                            {
                                op = 'n',
                                values = { { start = 11 }, { start = 8 }, { start = 80 }, { start = 800 } },
                            },
                        },
                    },
                },
            },
            {
                locales = { 'ka' },
                rules = {
                    one = { { { op = 'i', value = 1 } } },
                    many = {
                        { { op = 'i', value = 0 } },
                        {
                            {
                                op = 'i',
                                mod = 100,
                                values = {
                                    { start = 2, stop = 20 },
                                    { start = 40 },
                                    { start = 60 },
                                    { start = 80 },
                                },
                            },
                        },
                    },
                },
            },
            {
                locales = { 'kk' },
                rules = {
                    many = {
                        { { op = 'n', mod = 10, value = 6 } },
                        { { op = 'n', mod = 10, value = 9 } },
                        { { op = 'n', mod = 10, value = 0 }, { op = 'n', neq = true, value = 0 } },
                    },
                },
            },
            {
                locales = { 'kok', 'kok-Latn', 'mr' },
                rules = {
                    one = { { { op = 'n', value = 1 } } },
                    two = { { { op = 'n', values = { { start = 2 }, { start = 3 } } } } },
                    few = { { { op = 'n', value = 4 } } },
                },
            },
            {
                locales = { 'kw' },
                rules = {
                    one = {
                        { { op = 'n', values = { { start = 1, stop = 4 } } } },
                        {
                            {
                                op = 'n',
                                mod = 100,
                                values = {
                                    { start = 1, stop = 4 },
                                    { start = 21, stop = 24 },
                                    { start = 41, stop = 44 },
                                    { start = 61, stop = 64 },
                                    { start = 81, stop = 84 },
                                },
                            },
                        },
                    },
                    many = { { { op = 'n', value = 5 } }, { { op = 'n', mod = 100, value = 5 } } },
                },
            },
            {
                locales = { 'lij', 'scn' },
                rules = {
                    many = {
                        {
                            {
                                op = 'n',
                                values = {
                                    { start = 11 },
                                    { start = 8 },
                                    { start = 80, stop = 89 },
                                    { start = 800, stop = 899 },
                                },
                            },
                        },
                    },
                },
            },
            {
                locales = { 'mk' },
                rules = {
                    one = { { { op = 'i', mod = 10, value = 1 }, { op = 'i', mod = 100, neq = true, value = 11 } } },
                    two = { { { op = 'i', mod = 10, value = 2 }, { op = 'i', mod = 100, neq = true, value = 12 } } },
                    many = {
                        {
                            { op = 'i', mod = 10, values = { { start = 7 }, { start = 8 } } },
                            { op = 'i', mod = 100, neq = true, values = { { start = 17 }, { start = 18 } } },
                        },
                    },
                },
            },
            { locales = { 'ne' }, rules = { one = { { { op = 'n', values = { { start = 1, stop = 4 } } } } } } },
            {
                locales = { 'or' },
                rules = {
                    one = {
                        { { op = 'n', values = { { start = 1 }, { start = 5 }, { start = 7, stop = 9 } } } },
                    },
                    two = { { { op = 'n', values = { { start = 2 }, { start = 3 } } } } },
                    few = { { { op = 'n', value = 4 } } },
                    many = { { { op = 'n', value = 6 } } },
                },
            },
            {
                locales = { 'sq' },
                rules = {
                    one = { { { op = 'n', value = 1 } } },
                    many = {
                        { { op = 'n', mod = 10, value = 4 }, { op = 'n', mod = 100, neq = true, value = 14 } },
                    },
                },
            },
            {
                locales = { 'sv' },
                rules = {
                    one = {
                        {
                            { op = 'n', mod = 10, values = { { start = 1 }, { start = 2 } } },
                            { op = 'n', mod = 100, neq = true, values = { { start = 11 }, { start = 12 } } },
                        },
                    },
                },
            },
            {
                locales = { 'tk' },
                rules = {
                    few = {
                        { { op = 'n', mod = 10, values = { { start = 6 }, { start = 9 } } } },
                        { { op = 'n', value = 10 } },
                    },
                },
            },
            {
                locales = { 'uk' },
                rules = {
                    few = { { { op = 'n', mod = 10, value = 3 }, { op = 'n', mod = 100, neq = true, value = 13 } } },
                },
            },
        },
    }
end
