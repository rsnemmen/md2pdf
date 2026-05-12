#!/usr/bin/env bats

load 'test_helper'

@test "converts inline \\(...\\) to \$...\$" {
    run bash -c 'source "$MD2PDF"; convert_delimiters' <<'EOF'
Inline \(x^2\) here
EOF
    [ "$status" -eq 0 ]
    [ "$output" = 'Inline $x^2$ here' ]
}

@test "converts display \\[...\\] to \$\$...\$\$" {
    run bash -c 'source "$MD2PDF"; convert_delimiters' <<'EOF'
\[E = mc^2\]
EOF
    [ "$status" -eq 0 ]
    [ "$output" = '$$E = mc^2$$' ]
}

@test "converts multiple inline math on same line" {
    run bash -c 'source "$MD2PDF"; convert_delimiters' <<'EOF'
Both \(a\) and \(b\) matter
EOF
    [ "$status" -eq 0 ]
    [ "$output" = 'Both $a$ and $b$ matter' ]
}

@test "math inside triple-backtick code fence is unchanged" {
    run bash -c 'source "$MD2PDF"; convert_delimiters' <<'EOF'
```
\(x\)
```
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'```\n\\(x\\)\n```' ]
}

@test "math inside tilde fence is unchanged" {
    run bash -c 'source "$MD2PDF"; convert_delimiters' <<'EOF'
~~~
\(x\)
~~~
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'~~~\n\\(x\\)\n~~~' ]
}

@test "math inside \$\$ block is unchanged" {
    run bash -c 'source "$MD2PDF"; convert_delimiters' <<'EOF'
$$
\(not converted\)
$$
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'$$\n\\(not converted\\)\n$$' ]
}

@test "math inside inline backticks is unchanged" {
    run bash -c 'source "$MD2PDF"; convert_delimiters' <<'EOF'
`\(x\)` is code
EOF
    [ "$status" -eq 0 ]
    [ "$output" = '`\(x\)` is code' ]
}

@test "mixed inline code and math on same line" {
    run bash -c 'source "$MD2PDF"; convert_delimiters' <<'EOF'
`code` and \(math\) together
EOF
    [ "$status" -eq 0 ]
    [ "$output" = '`code` and $math$ together' ]
}

@test "code fence with 3 leading spaces is recognized" {
    run bash -c 'source "$MD2PDF"; convert_delimiters' <<'EOF'
   ```
\(x\)
   ```
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'   ```\n\\(x\\)\n   ```' ]
}

@test "passthrough: no math delimiters" {
    run bash -c 'source "$MD2PDF"; convert_delimiters' <<'EOF'
# Heading

Just prose, no math here.
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'# Heading\n\nJust prose, no math here.' ]
}

@test "empty input produces empty output" {
    run bash -c 'source "$MD2PDF"; convert_delimiters' <<'EOF'
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}
