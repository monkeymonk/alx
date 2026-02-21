#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
ALX_BIN="$ROOT_DIR/bin/alx"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not installed; skipping" >&2
  exit 0
fi

temp_dir="$(mktemp -d)"
cleanup() { rm -rf "$temp_dir"; }
trap cleanup EXIT

export XDG_CONFIG_HOME="$temp_dir/config"

"$ALX_BIN" gs="git status" --desc "Git status" --tags git,core
"$ALX_BIN" ll="ls -lah"

store="$XDG_CONFIG_HOME/alx/aliases.json"

jq -e '.gs.cmd == "git status"' "$store" >/dev/null
jq -e '.gs.desc == "Git status"' "$store" >/dev/null
jq -e '.gs.tags == ["git","core"]' "$store" >/dev/null
jq -e '.gs.origin.type == "manual"' "$store" >/dev/null

export_file="$temp_dir/export.sh"
"$ALX_BIN" export --shell > "$export_file"

# Import into a fresh store
export XDG_CONFIG_HOME="$temp_dir/import-config"
"$ALX_BIN" import "$export_file"
store2="$XDG_CONFIG_HOME/alx/aliases.json"

jq -e '.gs.cmd == "git status"' "$store2" >/dev/null
jq -e '.gs.desc == "Git status"' "$store2" >/dev/null
jq -e '.gs.tags == ["git","core"]' "$store2" >/dev/null
jq -e '.gs.origin.type == "import"' "$store2" >/dev/null

# Legacy import
legacy_file="$temp_dir/legacy.sh"
printf "alias l='ls -1'\n" > "$legacy_file"
"$ALX_BIN" import "$legacy_file"

jq -e '.l.origin.type == "legacy-import"' "$store2" >/dev/null

# Deterministic export order
export_out="$temp_dir/export2.sh"
"$ALX_BIN" export --shell > "$export_out"
mapfile -t names < <(grep '^# alx:name=' "$export_out" | sed -E 's/^# alx:name=([^ ]+).*/\1/')
expected=(gs l ll)
if [[ ${#names[@]} -lt 3 ]]; then
  echo "unexpected export count" >&2
  exit 1
fi
for i in 0 1 2; do
  if [[ ${names[$i]} != ${expected[$i]} ]]; then
    echo "unexpected export order" >&2
    exit 1
  fi
done
