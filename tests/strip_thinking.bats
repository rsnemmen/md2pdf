#!/usr/bin/env bats

load 'test_helper'

@test "passthrough: no thinking marker" {
    run bash -c 'source "$MD2PDF"; strip_leading_thinking' <<'EOF'
# Hello

Some text
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'# Hello\n\nSome text' ]
}

@test "strips *Thinking* marker and following blockquote" {
    run bash -c 'source "$MD2PDF"; strip_leading_thinking' <<'EOF'
*Thinking*

> I am reasoning here.
> Another thought.

Real content
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "Real content" ]
}

@test "strips **Thinking** (double asterisks) variant" {
    run bash -c 'source "$MD2PDF"; strip_leading_thinking' <<'EOF'
**Thinking**

> Reasoning.

Content after
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "Content after" ]
}

@test "strips _Thinking_ (underscore) variant" {
    run bash -c 'source "$MD2PDF"; strip_leading_thinking' <<'EOF'
_Thinking_

> Reasoning.

Content after
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "Content after" ]
}

@test "marker not at line 1 is preserved" {
    run bash -c 'source "$MD2PDF"; strip_leading_thinking' <<'EOF'
# Intro

*Thinking*

Some text
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'# Intro\n\n*Thinking*\n\nSome text' ]
}

@test "marker at line 1 without following blockquote is restored verbatim" {
    run bash -c 'source "$MD2PDF"; strip_leading_thinking' <<'EOF'
*Thinking*

Just a paragraph
EOF
    [ "$status" -eq 0 ]
    [ "$output" = $'*Thinking*\n\nJust a paragraph' ]
}

@test "blockquote ends when non-blank non-quote line appears" {
    run bash -c 'source "$MD2PDF"; strip_leading_thinking' <<'EOF'
*Thinking*

> reasoning
> more reasoning

Content after blockquote
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "Content after blockquote" ]
}

@test "only thinking block produces empty output" {
    run bash -c 'source "$MD2PDF"; strip_leading_thinking' <<'EOF'
*Thinking*

> Only reasoning, no real content
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "empty input produces empty output" {
    run bash -c 'source "$MD2PDF"; strip_leading_thinking' <<'EOF'
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}
