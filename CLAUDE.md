# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A two-file bash tool that converts Markdown to PDF via `pandoc` + XeLaTeX + the [eisvogel](https://github.com/Wandmalfarbe/pandoc-latex-template) template.

- `md2pdf.sh` — the converter (preprocessing pipeline + pandoc invocation)
- `install.sh` — dependency installer (pandoc, XeLaTeX, eisvogel, PATH symlink)

## Running

```sh
./install.sh --check          # verify dependencies without installing
./install.sh                  # install all dependencies
./md2pdf.sh report.md         # convert a single file
./md2pdf.sh *.md              # batch convert (progress bar shown)
cat notes.md | ./md2pdf.sh - out.pdf  # stdin input
```

## Architecture

`md2pdf.sh` works as a preprocessing pipeline piped into pandoc:

```
input → preprocess() → pandoc → PDF
```

`preprocess()` chains three awk/sed passes:
1. `strip_leading_thinking` — removes chatbot "thinking" preambles (lines matching `*Thinking*` / `_Thinking_` at line 1, followed by blockquotes)
2. `convert_delimiters` — converts `\(...\)` / `\[...\]` math delimiters to `$...$` / `$$...$$` (only runs when `contains_math()` detects them)
3. `ensure_blank_before_lists` — inserts blank lines before list items that immediately follow non-blank, non-list lines (fixes common AI output formatting)

Two pandoc modes are controlled by `use_simple`:
- Default: eisvogel template with syntax highlighting and a custom `\passthrough` fix for inline code in listings
- `--simple` (`-s`): bare xelatex with 1-inch margins, no template required

Batch mode suppresses per-file verbose output and shows a `render_bar` progress indicator instead; errors are captured to a temp file and printed after the bar advances.

## Key paths

- eisvogel template: `~/.local/share/pandoc/templates/eisvogel.latex`
- installed symlink: `~/.local/bin/md2pdf → <repo>/md2pdf.sh`
