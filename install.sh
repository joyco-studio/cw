#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/cw"
REPO="https://raw.githubusercontent.com/joyco-studio/cw/main/cw.sh"
SOURCE_LINE='source ~/.local/bin/cw'

# ── Download ──────────────────────────────────────────────────────────────
mkdir -p "$BIN_DIR"
echo "Downloading cw..."
curl -fsSL "$REPO" -o "$BIN_PATH"
chmod +x "$BIN_PATH"

# ── Shell setup ───────────────────────────────────────────────────────────
rc=""
if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "${SHELL:-}")" = "zsh" ]; then
  rc="${ZDOTDIR:-$HOME}/.zshrc"
elif [ -n "${BASH_VERSION:-}" ] || [ "$(basename "${SHELL:-}")" = "bash" ]; then
  rc="$HOME/.bashrc"
fi

if [ -n "$rc" ]; then
  if ! grep -qxF "$SOURCE_LINE" "$rc" 2>/dev/null; then
    echo "" >> "$rc"
    echo "$SOURCE_LINE" >> "$rc"
    echo "Added '$SOURCE_LINE' to $rc"
  else
    echo "Already in $rc, skipping"
  fi
else
  echo "Could not detect shell rc file — add this manually:"
  echo "  $SOURCE_LINE"
fi

echo "Done! Restart your shell or run: source $rc"
