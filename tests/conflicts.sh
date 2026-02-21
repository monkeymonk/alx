#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_helpers.sh"

setup_temp
trap teardown_temp EXIT

# Registry conflict
"$ALX_BIN" gs="git status"
assert_cmd_fail 2 "$ALX_BIN" gs="git status"
assert_cmd_ok "$ALX_BIN" gs="git status" --force

# Function conflict (exported)
fn_conflict() { echo hi; }
export -f fn_conflict
assert_cmd_fail 2 "$ALX_BIN" add fn_conflict "echo ok"
assert_cmd_ok "$ALX_BIN" add fn_conflict "echo ok" --force

# Binary conflict (soft)
"$ALX_BIN" add ls "ls -lah"

# Binary conflict (strict)
assert_cmd_fail 2 "$ALX_BIN" add ls "ls -lah" --strict
