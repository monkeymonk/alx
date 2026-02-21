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
SH

"$ALX_BIN" import "$import_file"

store="$XDG_CONFIG_HOME/alx/aliases.json"

assert_eq "echo hello" "$(json_get "$store" "foo.cmd")" "foo cmd"
assert_eq "Hello World" "$(json_get "$store" "foo.desc")" "foo desc"
assert_eq "[\"one\", \"two\"]" "$(json_get "$store" "foo.tags")" "foo tags"

assert_eq "Say hi" "$(json_get "$store" "hi.desc")" "hi desc"
assert_eq "[\"core\"]" "$(json_get "$store" "hi.tags")" "hi tags"

assert_eq "legacy-import" "$(json_get "$store" "legacy.origin.type")" "legacy origin"

assert_eq "echo 'hi'" "$(json_get "$store" "q.cmd")" "quoted cmd"
