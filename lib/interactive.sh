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
  while IFS= read -r entry; do
    local name desc tags
    if is_jq_available; then
      name=$(printf '%s' "$entry" | jq -r '.key')
      desc=$(printf '%s' "$entry" | jq -r '.value.desc // ""')
      tags=$(printf '%s' "$entry" | jq -r '.value.tags // [] | join(",")')
    else
      read -r name desc tags < <(printf '%s' "$entry" | python3 - <<'PY'
import json,sys
try:
    e=json.loads(sys.stdin.read())
    v=e.get('value',{})
    print(e.get('key',''))
    print(v.get('desc') or '')
    print(','.join(v.get('tags') or []))
except Exception:
    print('')
    print('')
    print('')
PY
)
    fi
    if [[ -n $name ]]; then
      items+=("${name}\t${desc}\t${tags}")
    fi
  done < <(json_all_entries)

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
