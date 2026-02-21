#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

failures=0

for test in "$SCRIPT_DIR"/*.sh; do
  if [[ $test == "$SCRIPT_DIR/run.sh" ]]; then
    continue
  fi
  if ! bash "$test"; then
    echo "FAIL: $test" >&2
    failures=$((failures + 1))
  else
    echo "PASS: $test" >&2
  fi
  echo >&2
 done

if [[ $failures -ne 0 ]]; then
  echo "$failures test(s) failed" >&2
  exit 1
fi

echo "All tests passed" >&2
