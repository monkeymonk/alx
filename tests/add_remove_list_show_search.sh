#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_helpers.sh"

setup_temp
trap teardown_temp EXIT

"$ALX_BIN" gs="git status" --desc "Git status" --tags git,core
"$ALX_BIN" ll="ls -lah"

list_out=$("$ALX_BIN" list)
assert_contains "$list_out" $'gs\tgit status\tGit status\tgit,core' "list includes gs"
assert_contains "$list_out" $'ll\tls -lah' "list includes ll"

show_out=$("$ALX_BIN" show gs)
assert_contains "$show_out" "name: gs" "show name"
assert_contains "$show_out" "cmd: git status" "show cmd"
assert_contains "$show_out" "desc: Git status" "show desc"
assert_contains "$show_out" "tags: git,core" "show tags"

search_out=$("$ALX_BIN" search git)
assert_contains "$search_out" "gs" "search by tag/desc"

"$ALX_BIN" remove ll
assert_cmd_fail 1 "$ALX_BIN" show ll
