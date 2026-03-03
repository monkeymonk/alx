#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_helpers.sh"

setup_temp
trap teardown_temp EXIT

"$ALX_BIN" gs="git status" --desc "Git status" --tags git,core
"$ALX_BIN" q="echo 'hi'"
"$ALX_BIN" t="test" --tags one,two

export_out=$("$ALX_BIN" export --shell)

assert_contains "$export_out" "alias gs='git status' # Git status [git, core]" "inline desc+tags"
assert_contains "$export_out" "alias q='echo '\''hi'\'''" "single quote escaping"
assert_contains "$export_out" "alias t='test' # [one, two]" "tags only"

# no trailing comment for alias without desc/tags
line=$(echo "$export_out" | grep "^alias q=")
assert_eq "alias q='echo '\''hi'\'''" "$line" "no trailing comment when no metadata"
