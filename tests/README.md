# md2pdf test suite

Tests are written with [bats-core](https://github.com/bats-core/bats-core).

## Install bats-core

macOS:
```sh
brew install bats-core
```

Linux (Debian/Ubuntu):
```sh
sudo apt-get install bats
```

## Run the suite

```sh
bats tests/                              # all tests
bats tests/strip_thinking.bats           # single file
bats tests/convert_delimiters.bats
bats tests/ensure_blank_before_lists.bats
bats tests/preprocess.bats
bats tests/cli.bats
bats tests/pdf_smoke.bats
bats --tap tests/                        # TAP output for CI
```

PDF smoke tests (`pdf_smoke.bats`) skip automatically when `pandoc`, `xelatex`, the eisvogel template, or `pdftotext` are not installed.
