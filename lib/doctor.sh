#!/usr/bin/env bash
set -euo pipefail

doctor() {
  ensure_store

  declare -A _seen_cmds
  while IFS= read -r name; do
    read_alias "$name"

    if [[ -z $_ALX_CMD ]]; then
      warn "broken entry '$name': missing cmd"
      continue
    fi
    if [[ -z $_ALX_ORIGIN_TYPE ]]; then
      warn "broken entry '$name': missing origin_type"
    fi
    if [[ -z $_ALX_CREATED_AT ]]; then
      warn "broken entry '$name': missing created_at"
    fi

    if [[ -n ${_seen_cmds[$_ALX_CMD]+x} ]]; then
      warn "duplicate command: '$_ALX_CMD' used by '${_seen_cmds[$_ALX_CMD]}' and '$name'"
    else
      _seen_cmds["$_ALX_CMD"]="$name"
    fi

    local first=${_ALX_CMD%% *}
    if [[ -n $first ]] && ! command -v "$first" >/dev/null 2>&1; then
      warn "missing binary for '$name': $first"
    fi
  done < <(list_alias_names)
}
