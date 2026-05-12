#!/usr/bin/env bash
set -euo pipefail

EISVOGEL_TEMPLATE="$HOME/.local/share/pandoc/templates/eisvogel.latex"
LOCAL_BIN="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASICTEX_TEXBIN="/Library/TeX/texbin"

PLATFORM=""
LINUX_PKG_MGR=""
check_only=0
auto_yes=0
had_missing=0

show_usage() {
    cat << 'EOF'
Usage: ./install.sh [options]

Install dependencies for md2pdf: pandoc, XeLaTeX, eisvogel template.

Options:
  --check     Report status of each dependency without installing anything
  -y, --yes   Skip confirmation prompts (non-interactive / CI use)
  -h, --help  Show this help message
EOF
}

die()     { printf 'Error: %s\n' "$1" >&2; exit 1; }
ok()      { printf '  [OK]      %s\n' "$1"; }
missing() { printf '  [MISSING] %s\n' "$1"; had_missing=1; }
info()    { printf '            %s\n' "$1"; }
warn()    { printf '  [WARN]    %s\n' "$1"; }

confirm() {
    local msg="$1"
    if [[ "$auto_yes" -eq 1 ]]; then
        printf '%s → yes (--yes)\n' "$msg"
        return 0
    fi
    printf '%s [Y/n] ' "$msg"
    local reply
    IFS= read -r reply
    case "$reply" in
        ''|[Yy]*) return 0 ;;
        *)         return 1 ;;
    esac
}

detect_platform() {
    local uname
    uname="$(uname -s)"
    case "$uname" in
        Darwin) PLATFORM="mac" ;;
        Linux)  PLATFORM="linux" ;;
        *)      die "Unsupported platform: $uname" ;;
    esac
    if [[ "$PLATFORM" == "linux" ]] && grep -qi microsoft /proc/version 2>/dev/null; then
        printf 'WSL detected — treating as Linux.\n\n'
    fi
}

detect_linux_pkg_mgr() {
    if command -v apt-get &>/dev/null; then
        LINUX_PKG_MGR="apt"
    elif command -v dnf &>/dev/null; then
        LINUX_PKG_MGR="dnf"
    elif command -v pacman &>/dev/null; then
        LINUX_PKG_MGR="pacman"
    else
        die "No supported package manager found (need apt, dnf, or pacman)"
    fi
}

step_brew() {
    printf '\n[Homebrew]\n'
    if command -v brew &>/dev/null; then
        ok "Homebrew: $(brew --version | head -1)"
        return
    fi
    if [[ "$check_only" -eq 1 ]]; then
        missing "Homebrew: not installed (required for pandoc + BasicTeX on macOS)"
        return
    fi
    cat >&2 << 'EOF'
Homebrew is not installed. Install it first:
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
Then re-run ./install.sh.
EOF
    exit 1
}

step_pandoc() {
    printf '\n[pandoc]\n'
    if command -v pandoc &>/dev/null; then
        ok "pandoc: $(pandoc --version | head -1)"
        return
    fi
    if [[ "$check_only" -eq 1 ]]; then
        missing "pandoc: not installed"
        return
    fi

    case "$PLATFORM" in
        mac)
            if confirm "  Install pandoc via brew?"; then
                brew install pandoc
                ok "pandoc installed"
            else
                warn "pandoc: skipped"
            fi
            ;;
        linux)
            case "$LINUX_PKG_MGR" in
                apt)
                    if confirm "  Install pandoc via apt?"; then
                        sudo apt-get install -y pandoc
                        ok "pandoc installed"
                    else
                        warn "pandoc: skipped"
                    fi
                    ;;
                dnf)
                    if confirm "  Install pandoc via dnf?"; then
                        sudo dnf install -y pandoc
                        ok "pandoc installed"
                    else
                        warn "pandoc: skipped"
                    fi
                    ;;
                pacman)
                    if confirm "  Install pandoc via pacman?"; then
                        sudo pacman -S --needed pandoc
                        ok "pandoc installed"
                    else
                        warn "pandoc: skipped"
                    fi
                    ;;
            esac
            ;;
    esac
}

step_latex() {
    printf '\n[LaTeX / XeLaTeX]\n'

    # BasicTeX may be installed but not yet on PATH — check the known location too
    if [[ "$PLATFORM" == "mac" && ! -x "$(command -v xelatex || true)" && -x "$BASICTEX_TEXBIN/xelatex" ]]; then
        export PATH="$BASICTEX_TEXBIN:$PATH"
    fi

    if command -v xelatex &>/dev/null; then
        ok "xelatex: $(xelatex --version | head -1)"
        return
    fi

    if [[ "$check_only" -eq 1 ]]; then
        missing "xelatex: not installed"
        return
    fi

    case "$PLATFORM" in
        mac)
            if confirm "  Install BasicTeX (~100MB) via brew?"; then
                brew install --cask basictex
                export PATH="$BASICTEX_TEXBIN:$PATH"
                ok "BasicTeX installed"
                info "Restart your shell or run: export PATH=\"$BASICTEX_TEXBIN:\$PATH\""
            else
                warn "LaTeX: skipped"
            fi
            ;;
        linux)
            local pkgs
            case "$LINUX_PKG_MGR" in
                apt)
                    pkgs="texlive-xetex texlive-fonts-recommended texlive-fonts-extra texlive-latex-extra"
                    if confirm "  Install $pkgs via apt?"; then
                        sudo apt-get install -y $pkgs
                        ok "TeX Live installed"
                    else
                        warn "LaTeX: skipped"
                    fi
                    ;;
                dnf)
                    pkgs="texlive-scheme-medium"
                    if confirm "  Install $pkgs via dnf?"; then
                        sudo dnf install -y $pkgs
                        ok "TeX Live installed"
                    else
                        warn "LaTeX: skipped"
                    fi
                    ;;
                pacman)
                    pkgs="texlive-xetex texlive-fontsextra texlive-latexextra"
                    if confirm "  Install $pkgs via pacman?"; then
                        sudo pacman -S --needed $pkgs
                        ok "TeX Live installed"
                    else
                        warn "LaTeX: skipped"
                    fi
                    ;;
            esac
            ;;
    esac
}

step_tlmgr_packages() {
    # Only needed on macOS; BasicTeX is minimal and needs supplementary packages for eisvogel.
    # On Linux the texlive-*-extra packages from step_latex already cover these.
    [[ "$PLATFORM" == "mac" ]] || return 0

    printf '\n[eisvogel tlmgr packages]\n'

    local tlmgr_cmd=""
    if command -v tlmgr &>/dev/null; then
        tlmgr_cmd="tlmgr"
    elif [[ -x "$BASICTEX_TEXBIN/tlmgr" ]]; then
        tlmgr_cmd="$BASICTEX_TEXBIN/tlmgr"
    else
        if [[ "$check_only" -eq 1 ]]; then
            missing "tlmgr: not found (install BasicTeX first)"
        else
            info "tlmgr not found — skipping (install BasicTeX first)"
        fi
        return
    fi

    # Use kpsewhich to probe for a representative package rather than parsing tlmgr output
    local kpsewhich_cmd=""
    command -v kpsewhich &>/dev/null && kpsewhich_cmd="kpsewhich"
    [[ -z "$kpsewhich_cmd" && -x "$BASICTEX_TEXBIN/kpsewhich" ]] && kpsewhich_cmd="$BASICTEX_TEXBIN/kpsewhich"

    if [[ -n "$kpsewhich_cmd" ]] && "$kpsewhich_cmd" adjustbox.sty &>/dev/null 2>&1; then
        ok "eisvogel tlmgr packages: already installed"
        return
    fi

    if [[ "$check_only" -eq 1 ]]; then
        missing "eisvogel tlmgr packages: not fully installed"
        return
    fi

    local pkgs=(
        adjustbox babel-german background bidi collectbox
        csquotes draftwatermark everypage filehook footmisc footnotebackref
        framed fvextra letltxmacro ly1 mdframed mweights needspace pagecolor
        sourcecodepro sourcesanspro titling ucharcat unicode-math upquote
        xecjk xurl zref
    )

    if confirm "  Install ${#pkgs[@]} eisvogel-required packages via tlmgr?"; then
        info "Updating tlmgr..."
        sudo "$tlmgr_cmd" update --self
        info "Installing packages..."
        sudo "$tlmgr_cmd" install "${pkgs[@]}"
        ok "tlmgr packages installed"
    else
        warn "tlmgr packages: skipped"
    fi
}

step_eisvogel() {
    printf '\n[eisvogel template]\n'
    if [[ -f "$EISVOGEL_TEMPLATE" ]]; then
        ok "eisvogel template: $EISVOGEL_TEMPLATE"
        return
    fi
    if [[ "$check_only" -eq 1 ]]; then
        missing "eisvogel template: not found at $EISVOGEL_TEMPLATE"
        return
    fi

    if ! confirm "  Download eisvogel template from GitHub?"; then
        warn "eisvogel: skipped"
        return
    fi

    command -v curl &>/dev/null || die "curl is required to download the eisvogel template"

    info "Fetching latest release info from GitHub..."
    local api_response download_url
    api_response=$(curl -fsSL \
        https://api.github.com/repos/Wandmalfarbe/pandoc-latex-template/releases/latest) \
        || die "Could not reach GitHub API — check your internet connection"

    download_url=$(printf '%s' "$api_response" \
        | grep -oE 'https://[^"]+eisvogel\.latex' \
        | head -1)

    [[ -n "$download_url" ]] \
        || die "Could not parse eisvogel.latex download URL from GitHub API response"

    mkdir -p "$(dirname "$EISVOGEL_TEMPLATE")"
    info "Downloading $download_url ..."
    curl -fsSL -o "$EISVOGEL_TEMPLATE" "$download_url" \
        || die "Download failed"
    ok "eisvogel template installed: $EISVOGEL_TEMPLATE"
}

step_symlink() {
    printf '\n[md2pdf on PATH]\n'
    local target="$LOCAL_BIN/md2pdf"
    local source="$SCRIPT_DIR/md2pdf.sh"

    if [[ ! -f "$source" ]]; then
        warn "md2pdf.sh not found at $source — skipping symlink"
        return
    fi

    if [[ "$check_only" -eq 1 ]]; then
        if command -v md2pdf &>/dev/null; then
            ok "md2pdf: $(command -v md2pdf)"
        else
            missing "md2pdf: not on PATH"
        fi
        return
    fi

    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        ok "symlink already exists: $target"
    else
        if confirm "  Create symlink $target → $source?"; then
            mkdir -p "$LOCAL_BIN"
            ln -sf "$source" "$target"
            ok "symlink created: $target"
        else
            warn "symlink: skipped"
            return
        fi
    fi

    if ! printf '%s' "$PATH" | tr ':' '\n' | grep -qxF "$LOCAL_BIN"; then
        printf '\n'
        info "Note: $LOCAL_BIN is not on your PATH."
        info "Add this to your shell rc (~/.zshrc, ~/.bashrc, etc.):"
        info "  export PATH=\"$LOCAL_BIN:\$PATH\""
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check)    check_only=1; shift ;;
            -y|--yes)   auto_yes=1;   shift ;;
            -h|--help)  show_usage;   exit 0 ;;
            *) die "Unknown option: $1" ;;
        esac
    done
}

main() {
    parse_args "$@"
    detect_platform

    if [[ "$check_only" -eq 1 ]]; then
        printf '=== md2pdf dependency check ===\n'
    else
        printf '=== md2pdf installer ===\n'
    fi

    if [[ "$PLATFORM" == "mac" ]]; then
        step_brew
        step_pandoc
        step_latex
        step_tlmgr_packages
    else
        detect_linux_pkg_mgr
        step_pandoc
        step_latex
    fi

    step_eisvogel
    step_symlink

    printf '\n'
    if [[ "$check_only" -eq 1 ]]; then
        if [[ "$had_missing" -eq 1 ]]; then
            printf 'Some dependencies are missing. Run ./install.sh to install them.\n'
            exit 1
        else
            printf 'All dependencies are present.\n'
        fi
    else
        printf 'Done.\n'
    fi
}

main "$@"
