#!/usr/bin/env bash
set -euo pipefail

export_aliases() {
  ALX_QUIET=1
  ensure_store
  while IFS= read -r name; do
    read_alias "$name"
    local comment=""
    if [[ -n $_ALX_DESC && -n $_ALX_TAGS ]]; then
      comment=" # $_ALX_DESC [${_ALX_TAGS//,/, }]"
    elif [[ -n $_ALX_DESC ]]; then
      comment=" # $_ALX_DESC"
    elif [[ -n $_ALX_TAGS ]]; then
      comment=" # [${_ALX_TAGS//,/, }]"
    fi
    printf "alias %s='%s'%s\n" "$name" "$(shell_escape_single "$_ALX_CMD")" "$comment"
  done < <(list_alias_names)
}
