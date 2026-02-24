#!/usr/bin/env bash
set -euo pipefail

pick_alias() {
  local exec_mode=0
  if [[ ${1-} == "--exec" ]]; then
    exec_mode=1
    shift
  fi

  ensure_store

  local items=()
  local tab=$'\t'
  while IFS= read -r name; do
    read_alias "$name"
    items+=("${name}${tab}${_ALX_DESC}${tab}${_ALX_TAGS}")
  done < <(list_alias_names)

  if [[ ${#items[@]} -eq 0 ]]; then
    error "no aliases found"
    exit 1
  fi

  local selected=""
  if command -v fzf >/dev/null 2>&1; then
    selected=$(printf '%s\n' "${items[@]}" | fzf --with-nth=1,2,3 --delimiter=$'\t')
  else
    local names=()
    local item name
    for item in "${items[@]}"; do
      name=${item%%$'\t'*}
      names+=("$name")
    done
    select name in "${names[@]}"; do
      selected="$name"
      break
    done
  fi

  if [[ -z $selected ]]; then
    exit 1
  fi

  local name
  if [[ $selected == *$'\t'* ]]; then
    name=${selected%%$'\t'*}
  else
    name=$selected
  fi

  if [[ $exec_mode -eq 1 ]]; then
    run_alias "$name"
  else
    printf '%s\n' "$name"
  fi
}
