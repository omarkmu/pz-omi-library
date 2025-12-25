### Fluent translation file with various message and term types for tests.
### @diagnostic disable

-term = term
    .type = word

-term-parameterized = Something { $adjective }

-term-selector = { $param ->
    [one] number one
    *[other] incomprehensible
}

message-basic = Hello world
    .type = message

message-parameterized-attr =
    .attr = { $value }

message-no-value =
    .attr = attribute value

message-ref = { message-basic }, I am here
message-ref-attr = This is a { message-basic.type }

message-term = I am a message, not a { -term }
message-term-selector = I am { -term-selector(param: 1) }!
message-term-parameterized = { -term-parameterized(adjective: "cool") }

message-num = pi is ~{ 3.14159 }
message-str = pi is { "a number" }
message-var = Hello, { $name }! Your lucky number is { $num }.
message-escapes = A message with { "\"escapes\"" }, like { "\\" }, { "\u00A0" }, and { "\u10000" }

message-unknown-function = { UNKNOWN() }
message-datetime-function = { DATETIME($date) }
message-num-function = { NUMBER(5, minimumFractionDigits: 2) }

message-gettext = { GETTEXT("UI_Yes") }
message-gettext-default = { GETTEXT("Unknown", default: "DEFAULT") }

message-variants-ordinal = You came in { $place ->
    [one] { $place }st
    [two] { $place }nd
    [few] { $place }rd
    *[other] { $place }th
}.

message-variants-default = { $gender ->
    [male] He is
    [female] She is
    *[other] They are
} pretty cool.

message-variants-term-attribute = { -term } is a { -term.type ->
    [word] word
    *[other] mysterious entity
}
