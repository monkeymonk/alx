#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_helpers.sh"

ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ALX_BIN="$ROOT_DIR/bin/alx"

temp_dir="$(mktemp -d)"
cleanup() { rm -rf "$temp_dir"; }
trap cleanup EXIT

export XDG_CONFIG_HOME="$temp_dir/config"

"$ALX_BIN" gs="git status" --desc "Git status" --tags git,core
"$ALX_BIN" ll="ls -lah"

store_dir="$XDG_CONFIG_HOME/alx/aliases"

assert_eq "git status" "$(alias_field "$store_dir/gs" "cmd")" "gs cmd"
assert_eq "Git status" "$(alias_field "$store_dir/gs" "desc")" "gs desc"
assert_eq "git,core"   "$(alias_field "$store_dir/gs" "tags")" "gs tags"
assert_eq "manual"     "$(alias_field "$store_dir/gs" "origin_type")" "gs origin_type"

export_file="$temp_dir/export.sh"
"$ALX_BIN" export --shell > "$export_file"

# Import into a fresh store
export XDG_CONFIG_HOME="$temp_dir/import-config"
"$ALX_BIN" import "$export_file"
store2="$XDG_CONFIG_HOME/alx/aliases"

assert_eq "git status" "$(alias_field "$store2/gs" "cmd")"         "import gs cmd"
assert_eq "Git status" "$(alias_field "$store2/gs" "desc")"        "import gs desc"
assert_eq "git,core"   "$(alias_field "$store2/gs" "tags")"        "import gs tags"
assert_eq "import"     "$(alias_field "$store2/gs" "origin_type")" "import gs origin_type"

# Legacy import
legacy_file="$temp_dir/legacy.sh"
printf "alias l='ls -1'\n" > "$legacy_file"
"$ALX_BIN" import "$legacy_file"

assert_eq "legacy-import" "$(alias_field "$store2/l" "origin_type")" "legacy import type"

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
    echo "unexpected export order: got ${names[$i]}, want ${expected[$i]}" >&2
    exit 1
  fi
done
