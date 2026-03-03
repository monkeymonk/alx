#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_helpers.sh"

setup_temp
trap teardown_temp EXIT

import_file="$TEMP_DIR/import.sh"
cat > "$import_file" <<'SH'
# alx:name=foo desc="Hello World" tags=one,two
alias foo='echo hello'

# metadata without name should attach to alias name
# alx:desc="Say hi" tags=core
alias hi='echo hi'

# legacy import
alias legacy='ls -1'

# quoted command with embedded single quote
# alx:name=q desc="Quote test" tags=quote
alias q='echo '\''hi'\'''

# inline comment: desc + tags (single-quoted)
alias sm='somecommand' # My description [tag, another_tag]

# inline comment: desc only (double-quoted)
alias dx="docker exec" # Run docker exec

# inline comment: tags only
alias dk='docker kill' # [docker, ops]

# inline comment with escaped single quote in cmd
alias sq='echo '\''world'\''' # Greeting [hello]
SH

"$ALX_BIN" import "$import_file"

store_dir="$XDG_CONFIG_HOME/alx/aliases"

# --- alx metadata format (backward compat) ---
assert_eq "echo hello" "$(alias_field "$store_dir/foo" "cmd")"  "foo cmd"
assert_eq "Hello World" "$(alias_field "$store_dir/foo" "desc")" "foo desc"
assert_eq "one,two"     "$(alias_field "$store_dir/foo" "tags")" "foo tags"

assert_eq "Say hi" "$(alias_field "$store_dir/hi" "desc")" "hi desc"
assert_eq "core"   "$(alias_field "$store_dir/hi" "tags")" "hi tags"

assert_eq "legacy-import" "$(alias_field "$store_dir/legacy" "origin_type")" "legacy origin"

assert_eq "echo 'hi'" "$(alias_field "$store_dir/q" "cmd")" "quoted cmd"

# --- inline comment format ---
assert_eq "somecommand"   "$(alias_field "$store_dir/sm" "cmd")"  "inline sm cmd"
assert_eq "My description" "$(alias_field "$store_dir/sm" "desc")" "inline sm desc"
assert_eq "tag,another_tag" "$(alias_field "$store_dir/sm" "tags")" "inline sm tags"
assert_eq "import"         "$(alias_field "$store_dir/sm" "origin_type")" "inline sm origin"

assert_eq "docker exec"      "$(alias_field "$store_dir/dx" "cmd")"  "inline dx cmd"
assert_eq "Run docker exec"  "$(alias_field "$store_dir/dx" "desc")" "inline dx desc"
assert_eq ""                  "$(alias_field "$store_dir/dx" "tags")" "inline dx tags"

assert_eq "docker kill" "$(alias_field "$store_dir/dk" "cmd")"  "inline dk cmd"
assert_eq ""            "$(alias_field "$store_dir/dk" "desc")" "inline dk desc"
assert_eq "docker,ops"  "$(alias_field "$store_dir/dk" "tags")" "inline dk tags"

assert_eq "echo 'world'" "$(alias_field "$store_dir/sq" "cmd")"  "inline sq cmd"
assert_eq "Greeting"      "$(alias_field "$store_dir/sq" "desc")" "inline sq desc"
assert_eq "hello"          "$(alias_field "$store_dir/sq" "tags")" "inline sq tags"
