#!/usr/bin/env bash
#
# Cross-platform dotfiles bootstrap.
# Detects the OS, delegates to the platform installer, then runs the steps that
# are identical everywhere (stow the dotfiles, install mise-managed tools, gh
# extensions).
#
#   ./install-all.sh
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

### PLATFORM-SPECIFIC PACKAGES ###############################################
case "$(uname -s)" in
  Darwin) echo "==> macOS detected"; ./packages/install-mac.sh ;;
  Linux)  echo "==> Linux detected";  ./packages/install-linux.sh ;;
  *)      echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

### SHARED STEPS (all platforms) #############################################

# Deploy the dotfiles as symlinks into $HOME. --no-folding keeps target dirs
# real (so stray files can live next to symlinks); --dotfiles maps dot-* -> .*
if command -v stow >/dev/null 2>&1; then
  echo "==> Stowing dotfiles into \$HOME"
  stow --no-folding --dotfiles -R .
else
  echo "!! stow not found — skipping symlink deploy (install it, then run: stow --no-folding --dotfiles -R .)"
fi

chmod +x ./dot-claude/review-bot/install.sh
./dot-claude/review-bot/install.sh

chmod +x ./dot-claude/nudge/install.sh
./dot-claude/nudge/install.sh

# Agent skills (private submodule): custom ones linked, upstream ones via npx skills.
if command -v mise >/dev/null 2>&1; then
  mise run skills || echo "!! skills install failed (private submodule unreachable?) — rerun: mise run skills"
fi

# Global CLI tools / language runtimes declared in ~/.config/mise
# (stowed just above). Safe no-op if there is nothing to install.
if command -v mise >/dev/null 2>&1; then
  echo "==> Installing mise-managed tools"
  mise install
fi

# gh extensions (cross-platform). Listed in packages/gh-extensions.txt, one
# owner/repo per line (blank lines and #-comments ignored).
if command -v gh >/dev/null 2>&1; then
  ext_file="$DOTFILES_DIR/packages/gh-extensions.txt"
  if [[ -f $ext_file ]]; then
    echo "==> Installing gh extensions"
    while IFS= read -r ext || [[ -n $ext ]]; do
      ext="${ext%%#*}"; ext="${ext//[[:space:]]/}"
      [[ -n $ext ]] && gh extension install "$ext" 2>/dev/null || true
    done < "$ext_file"
  fi
fi

echo "==> All done."
