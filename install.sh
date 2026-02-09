#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/cw"
GH_REPO="joyco-studio/cw"
SOURCE_LINE='source ~/.local/bin/cw'

# ── Resolve latest release ───────────────────────────────────────────────
echo "Checking latest release..."
API_URL="https://api.github.com/repos/${GH_REPO}/releases/latest"
TAG="$(curl -fsSL "$API_URL" 2>/dev/null | grep -m1 '"tag_name"' | cut -d'"' -f4)"

if [ -z "$TAG" ]; then
  echo "Could not determine latest release, falling back to main branch"
  TAG="main"
fi

DOWNLOAD_URL="https://raw.githubusercontent.com/${GH_REPO}/${TAG}/cw.sh"

# ── Download ──────────────────────────────────────────────────────────────
mkdir -p "$BIN_DIR"
echo "Downloading cw ${TAG}..."
curl -fsSL "$DOWNLOAD_URL" -o "$BIN_PATH"
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
