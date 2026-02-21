#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
ALX_BIN="$ROOT_DIR/bin/alx"

setup_temp() {
  TEMP_DIR="$(mktemp -d)"
  export XDG_CONFIG_HOME="$TEMP_DIR/config"
}

teardown_temp() {
  if [[ -n ${TEMP_DIR-} ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "assert_eq failed: $msg" >&2
    echo "expected: $expected" >&2
    echo "actual:   $actual" >&2
    exit 1
  fi
}

assert_contains() {
  local hay="$1"
  local needle="$2"
  local msg="$3"
  if [[ "$hay" != *"$needle"* ]]; then
    echo "assert_contains failed: $msg" >&2
    echo "missing: $needle" >&2
    exit 1
  fi
}

assert_cmd_fail() {
  local expected_code="$1"
  shift
  set +e
  "$@" >/dev/null 2>&1
  local code=$?
  set -e
  if [[ $code -ne $expected_code ]]; then
    echo "expected exit $expected_code, got $code" >&2
    exit 1
  fi
}

assert_cmd_ok() {
  set +e
  "$@" >/dev/null 2>&1
  local code=$?
  set -e
  if [[ $code -ne 0 ]]; then
    echo "expected exit 0, got $code" >&2
    exit 1
  fi
}

json_get() {
  local file="$1"
  local query="$2"
  python3 - "$file" "$query" <<'PY'
import json,sys
file_path,query = sys.argv[1:3]
with open(file_path, 'r', encoding='utf-8') as f:
    data=json.load(f)
val=data
for part in query.split('.'):
    if part == "":
        continue
    if isinstance(val, dict):
        val=val.get(part)
    else:
        val=None
        break
if isinstance(val, list):
    print(json.dumps(val))
elif val is None:
    print("null")
else:
    print(val)
PY
}
