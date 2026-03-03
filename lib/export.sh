#!/usr/bin/env bash
set -euo pipefail

export_aliases() {
  ALX_QUIET=1
  ensure_store
  while IFS= read -r name; do
    read_alias "$name"
    local meta="# alx:name=${name}"
    if [[ -n $_ALX_DESC ]]; then
      meta+=" desc=\"$(escape_meta_desc "$_ALX_DESC")\""
    fi
    if [[ -n $_ALX_TAGS ]]; then
      meta+=" tags=${_ALX_TAGS}"
    fi
    printf '%s\n' "$meta"
    printf "alias -- %s='%s'\n" "$name" "$(shell_escape_single "$_ALX_CMD")"
  done < <(list_alias_names)
}
