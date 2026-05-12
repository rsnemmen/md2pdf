#!/usr/bin/env bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECT_ROOT
export MD2PDF="$PROJECT_ROOT/md2pdf.sh"

require_pandoc() {
    command -v pandoc &>/dev/null || skip "pandoc not installed"
}

require_xelatex() {
    command -v xelatex &>/dev/null || skip "xelatex not installed"
}

require_eisvogel() {
    [[ -f "$HOME/.local/share/pandoc/templates/eisvogel.latex" ]] \
        || skip "eisvogel template not installed"
}

require_pdftotext() {
    command -v pdftotext &>/dev/null || skip "pdftotext not installed"
}
