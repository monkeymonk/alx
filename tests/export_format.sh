#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_helpers.sh"

setup_temp
trap teardown_temp EXIT

"$ALX_BIN" gs="git status" --desc "Git status" --tags git,core
"$ALX_BIN" q="echo 'hi'"

export_out=$("$ALX_BIN" export --shell)

assert_contains "$export_out" "# alx:name=gs desc=\"Git status\" tags=git,core" "metadata line"
assert_contains "$export_out" "alias gs='git status'" "alias line"
assert_contains "$export_out" "alias q='echo '\''hi'\'''" "single quote escaping"
