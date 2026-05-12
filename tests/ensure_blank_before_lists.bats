#!/usr/bin/env bats

load 'test_helper'

@test "inserts blank before dash bullet after paragraph" {
    run bash -c 'source "$MD2PDF"; ensure_blank_before_lists' <<'EOF'
Some text
- item
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'Some text\n\n- item' ]
}

@test "inserts blank before ordered list (dot) after paragraph" {
    run bash -c 'source "$MD2PDF"; ensure_blank_before_lists' <<'EOF'
Some text
1. item
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'Some text\n\n1. item' ]
}

@test "inserts blank before ordered list (paren) after paragraph" {
    run bash -c 'source "$MD2PDF"; ensure_blank_before_lists' <<'EOF'
Some text
1) item
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'Some text\n\n1) item' ]
}

@test "no extra blank when blank already precedes list" {
    run bash -c 'source "$MD2PDF"; ensure_blank_before_lists' <<'EOF'
Some text

- item
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'Some text\n\n- item' ]
}

@test "no blanks inserted between consecutive list items" {
    run bash -c 'source "$MD2PDF"; ensure_blank_before_lists' <<'EOF'
- item1
- item2
- item3
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'- item1\n- item2\n- item3' ]
}

@test "list items inside code fence are not affected" {
    run bash -c 'source "$MD2PDF"; ensure_blank_before_lists' <<'EOF'
```
- not a list item
```
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'```\n- not a list item\n```' ]
}

@test "list items inside \$\$ math block are not affected" {
    run bash -c 'source "$MD2PDF"; ensure_blank_before_lists' <<'EOF'
$$
- not a list item
$$
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'$$\n- not a list item\n$$' ]
}

@test "indented bullet is recognized as a list item" {
    run bash -c 'source "$MD2PDF"; ensure_blank_before_lists' <<'EOF'
paragraph
  - nested item
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'paragraph\n\n  - nested item' ]
}

@test "inserts blank before plus-sign bullet" {
    run bash -c 'source "$MD2PDF"; ensure_blank_before_lists' <<'EOF'
paragraph
+ item
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'paragraph\n\n+ item' ]
}

@test "inserts blank before asterisk bullet" {
    run bash -c 'source "$MD2PDF"; ensure_blank_before_lists' <<'EOF'
paragraph
* item
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'paragraph\n\n* item' ]
}

@test "empty input produces empty output" {
    run bash -c 'source "$MD2PDF"; ensure_blank_before_lists' <<'EOF'
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}
