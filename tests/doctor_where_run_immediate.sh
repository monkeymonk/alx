#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_helpers.sh"

setup_temp
trap teardown_temp EXIT

"$ALX_BIN" hi="printf hi"

run_out=$("$ALX_BIN" run hi)
assert_eq "hi" "$run_out" "run output"

where_out=$("$ALX_BIN" where hi)
assert_contains "$where_out" "origin.type: manual" "where origin"

immediate_out=$("$ALX_BIN" --immediate x="echo yo")
assert_contains "$immediate_out" "alias x='echo yo'" "immediate alias output"

assert_cmd_ok "$ALX_BIN" doctor
