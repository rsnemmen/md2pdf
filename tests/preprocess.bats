#!/usr/bin/env bats

load 'test_helper'

FIXTURE="$PROJECT_ROOT/tests/fixtures/kitchen_sink.md"

@test "thinking block is stripped" {
    run bash -c 'source "$MD2PDF"; preprocess' < "$FIXTURE"
    [ "$status" -eq 0 ]
    [[ "$output" != *"Thinking"* ]]
    [[ "$output" != *"I am thinking"* ]]
}

@test "math delimiters are converted" {
    run bash -c 'source "$MD2PDF"; preprocess' < "$FIXTURE"
    [ "$status" -eq 0 ]
    [[ "$output" == *'$E = mc^2$'* ]]
    [[ "$output" != *'\(E = mc^2\)'* ]]
    [[ "$output" == *'$$F = ma$$'* ]]
    [[ "$output" != *'\[F = ma\]'* ]]
}

@test "math inside code fence is not converted" {
    run bash -c 'source "$MD2PDF"; preprocess' < "$FIXTURE"
    [ "$status" -eq 0 ]
    [[ "$output" == *'\(this is not math\)'* ]]
}

@test "bullet inside code fence is not given a preceding blank" {
    run bash -c 'source "$MD2PDF"; preprocess' < "$FIXTURE"
    [ "$status" -eq 0 ]
    # The line inside the fence must appear without an extra blank before it
    [[ "$output" == *$'```python\n# \\(this is not math\\)\n- not a list item'* ]]
}

@test "blank is inserted before list that immediately follows paragraph" {
    run bash -c 'source "$MD2PDF"; preprocess' < "$FIXTURE"
    [ "$status" -eq 0 ]
    [[ "$output" == *$'immediately by a list:\n\n- first item'* ]]
}

@test "output starts with the first real heading, not the thinking block" {
    run bash -c 'source "$MD2PDF"; preprocess' < "$FIXTURE"
    [ "$status" -eq 0 ]
    [[ "$output" == '# Kitchen Sink Demo'* ]]
}
