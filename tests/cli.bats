#!/usr/bin/env bats

load 'test_helper'

setup() {
    # Stub pandoc: logs args to pandoc_args, writes minimal PDF to -o target
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/pandoc" << 'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" >> "$BATS_TEST_TMPDIR/pandoc_args"
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "-o" ]]; then
        printf '%%PDF-1.4\n%%%%EOF\n' > "$2"
        break
    fi
    shift
done
STUB
    chmod +x "$BATS_TEST_TMPDIR/bin/pandoc"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

    printf '# Hello\n\nSome content\n' > "$BATS_TEST_TMPDIR/test.md"
}

@test "--help exits 0 and prints usage" {
    run "$MD2PDF" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"--compact"* ]]
}

@test "-h exits 0 and prints usage" {
    run "$MD2PDF" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "no args exits non-zero" {
    run "$MD2PDF"
    [ "$status" -ne 0 ]
}

@test "unknown option exits non-zero" {
    run "$MD2PDF" --bogus
    [ "$status" -ne 0 ]
}

@test "unreadable input file exits non-zero" {
    run "$MD2PDF" "$BATS_TEST_TMPDIR/nonexistent.md"
    [ "$status" -ne 0 ]
}

@test "single file derives output filename" {
    run "$MD2PDF" "$BATS_TEST_TMPDIR/test.md"
    [ "$status" -eq 0 ]
    [ -f "$BATS_TEST_TMPDIR/test.pdf" ]
}

@test "explicit output filename is honored" {
    run "$MD2PDF" "$BATS_TEST_TMPDIR/test.md" "$BATS_TEST_TMPDIR/out.pdf"
    [ "$status" -eq 0 ]
    [ -f "$BATS_TEST_TMPDIR/out.pdf" ]
}

@test "stdin dash in batch mode exits non-zero" {
    run "$MD2PDF" - "$BATS_TEST_TMPDIR/test.md"
    [ "$status" -ne 0 ]
}

@test "stdin mode with explicit output" {
    local out="$BATS_TEST_TMPDIR/stdin.pdf"
    run bash -c 'printf "# Hello\n" | "$1" -s - "$2"' _ "$MD2PDF" "$out"
    [ "$status" -eq 0 ]
    [ -f "$out" ]
}

@test "--toc passes --toc to pandoc" {
    run "$MD2PDF" --toc "$BATS_TEST_TMPDIR/test.md"
    [ "$status" -eq 0 ]
    grep -qx -- "--toc" "$BATS_TEST_TMPDIR/pandoc_args"
}

@test "--no-toc does not pass --toc to pandoc" {
    run "$MD2PDF" --no-toc "$BATS_TEST_TMPDIR/test.md"
    [ "$status" -eq 0 ]
    ! grep -qx -- "--toc" "$BATS_TEST_TMPDIR/pandoc_args"
}

@test "default mode passes --template=eisvogel to pandoc" {
    run "$MD2PDF" "$BATS_TEST_TMPDIR/test.md"
    [ "$status" -eq 0 ]
    grep -q -- "--template=eisvogel" "$BATS_TEST_TMPDIR/pandoc_args"
}

@test "default mode uses original eisvogel margins" {
    run "$MD2PDF" "$BATS_TEST_TMPDIR/test.md"
    [ "$status" -eq 0 ]
    ! grep -qx -- "geometry:top=0.9cm" "$BATS_TEST_TMPDIR/pandoc_args"
    ! grep -qx -- "geometry:bottom=1.5cm" "$BATS_TEST_TMPDIR/pandoc_args"
    ! grep -qx -- "geometry:includefoot" "$BATS_TEST_TMPDIR/pandoc_args"
    ! grep -qx -- "geometry:includehead" "$BATS_TEST_TMPDIR/pandoc_args"
    ! grep -Fqx -- "header-includes=\\AtBeginDocument{\\ihead*{}\\chead*{}\\ohead*{}\\KOMAoptions{headsepline=0pt}}" "$BATS_TEST_TMPDIR/pandoc_args"
}

@test "--compact trims top header space" {
    run "$MD2PDF" --compact "$BATS_TEST_TMPDIR/test.md"
    [ "$status" -eq 0 ]
    grep -qx -- "geometry:top=0.9cm" "$BATS_TEST_TMPDIR/pandoc_args"
    grep -qx -- "geometry:bottom=0.9cm" "$BATS_TEST_TMPDIR/pandoc_args"
    grep -qx -- "geometry:left=2.5cm" "$BATS_TEST_TMPDIR/pandoc_args"
    grep -qx -- "geometry:right=2.5cm" "$BATS_TEST_TMPDIR/pandoc_args"
    grep -qx -- "geometry:includefoot" "$BATS_TEST_TMPDIR/pandoc_args"
    ! grep -qx -- "geometry:includehead" "$BATS_TEST_TMPDIR/pandoc_args"
    grep -Fqx -- "header-includes=\\AtBeginDocument{\\ihead*{}\\chead*{}\\ohead*{}\\KOMAoptions{headsepline=0pt}}" "$BATS_TEST_TMPDIR/pandoc_args"
}

@test "-s / --simple does not use eisvogel template" {
    run "$MD2PDF" -s "$BATS_TEST_TMPDIR/test.md"
    [ "$status" -eq 0 ]
    ! grep -q -- "--template=eisvogel" "$BATS_TEST_TMPDIR/pandoc_args"
}

@test "--simple (long form) does not use eisvogel template" {
    run "$MD2PDF" --simple "$BATS_TEST_TMPDIR/test.md"
    [ "$status" -eq 0 ]
    ! grep -q -- "--template=eisvogel" "$BATS_TEST_TMPDIR/pandoc_args"
}

@test "batch mode produces PDFs for all inputs" {
    printf '# File 2\n' > "$BATS_TEST_TMPDIR/test2.md"
    run "$MD2PDF" "$BATS_TEST_TMPDIR/test.md" "$BATS_TEST_TMPDIR/test2.md"
    [ "$status" -eq 0 ]
    [ -f "$BATS_TEST_TMPDIR/test.pdf" ]
    [ -f "$BATS_TEST_TMPDIR/test2.pdf" ]
}
