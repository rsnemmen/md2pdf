#!/usr/bin/env bats

load 'test_helper'

@test "simple mode produces a valid PDF" {
    require_pandoc
    require_xelatex
    local out="$BATS_TEST_TMPDIR/sample.pdf"
    run "$MD2PDF" -s "$PROJECT_ROOT/examples/sample.md" "$out"
    [ "$status" -eq 0 ]
    [ -s "$out" ]
    [[ "$(head -c 5 "$out")" == "%PDF-" ]]
}

@test "default (eisvogel) mode produces a valid PDF" {
    require_pandoc
    require_xelatex
    require_eisvogel
    local out="$BATS_TEST_TMPDIR/sample-eisvogel.pdf"
    run "$MD2PDF" "$PROJECT_ROOT/examples/sample.md" "$out"
    [ "$status" -eq 0 ]
    [ -s "$out" ]
    [[ "$(head -c 5 "$out")" == "%PDF-" ]]
}

@test "stdin mode produces a valid PDF" {
    require_pandoc
    require_xelatex
    local out="$BATS_TEST_TMPDIR/stdin.pdf"
    run bash -c 'cat "$1" | "$2" -s - "$3"' _ "$PROJECT_ROOT/examples/sample.md" "$MD2PDF" "$out"
    [ "$status" -eq 0 ]
    [ -s "$out" ]
    [[ "$(head -c 5 "$out")" == "%PDF-" ]]
}

@test "math conversion survives end-to-end to PDF text" {
    require_pandoc
    require_xelatex
    require_pdftotext
    local out="$BATS_TEST_TMPDIR/math.pdf"
    printf '# Math Test\n\nInline: \(\\alpha + \\beta\)\n' > "$BATS_TEST_TMPDIR/math.md"
    run "$MD2PDF" -s "$BATS_TEST_TMPDIR/math.md" "$out"
    [ "$status" -eq 0 ]
    [ -s "$out" ]
    local text
    text="$(pdftotext "$out" -)"
    [[ "$text" == *"α"* ]] || [[ "$text" == *"β"* ]]
}
