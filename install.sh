#!/usr/bin/env bash
set -euo pipefail

ALX_REPO_BASE="https://raw.githubusercontent.com/monkeymonk/alx"
ALX_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/alx"
ALX_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/alx"

_latest_tag() {
  local api_url="https://api.github.com/repos/monkeymonk/alx/tags?per_page=1"
  local tag=""
  if command -v curl &>/dev/null; then
    tag=$(curl -fsSL "$api_url" | grep -m1 '"name"' | sed -E 's/.*"name": *"([^"]+)".*/\1/')
  elif command -v wget &>/dev/null; then
    tag=$(wget -qO - "$api_url" | grep -m1 '"name"' | sed -E 's/.*"name": *"([^"]+)".*/\1/')
  else
    echo "alx install: curl or wget required" >&2
    exit 1
  fi

  if [[ -z "$tag" ]]; then
    echo "alx install: failed to resolve latest release tag" >&2
    exit 1
  fi
  printf '%s' "$tag"
}

_detect_shell_rc() {
  if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
    echo "$HOME/.zshrc"
  else
    echo "$HOME/.bashrc"
  fi
}

_download() {
  local url="$1" dest="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget &>/dev/null; then
    wget -qO "$dest" "$url"
  else
    echo "alx install: curl or wget required" >&2
    exit 1
  fi
}

_patch_rc() {
  local rc="$1"
  local line="export PATH=\"$ALX_DATA/bin:\$PATH\""
  if grep -qF "$line" "$rc" 2>/dev/null; then
    echo "alx: already on PATH in $rc"
  else
    echo "" >> "$rc"
    echo "# alx — alias registry" >> "$rc"
    echo "$line" >> "$rc"
    echo "alx: added PATH line to $rc"
  fi
}

ALX_VERSION="${ALX_VERSION:-$(_latest_tag)}"
ALX_REPO="$ALX_REPO_BASE/$ALX_VERSION"

echo "Installing alx ($ALX_VERSION)..."

mkdir -p "$ALX_DATA/bin" "$ALX_DATA/lib" "$ALX_CONFIG"

_download "$ALX_REPO/bin/alx" "$ALX_DATA/bin/alx"
chmod +x "$ALX_DATA/bin/alx"

for lib in actions conflict doctor export import interactive logger store util; do
  _download "$ALX_REPO/lib/${lib}.sh" "$ALX_DATA/lib/${lib}.sh"
done

SHELL_RC="$(_detect_shell_rc)"

if [[ -t 0 ]]; then
  printf 'Add alx to PATH in %s? [y/N] ' "$SHELL_RC"
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    _patch_rc "$SHELL_RC"
  else
    echo "Skipped PATH update. Add $ALX_DATA/bin to your PATH manually."
  fi
else
  echo "Non-interactive install — skipping PATH update."
  echo "Add $ALX_DATA/bin to your PATH manually."
fi

echo ""
echo "alx installed."
