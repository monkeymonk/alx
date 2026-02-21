#!/usr/bin/env bash
set -euo pipefail

doctor() {
  ensure_store

  if is_jq_available; then
    if ! read_store | jq empty >/dev/null 2>&1; then
      error "invalid JSON in store"
      exit 3
    fi
  else
    if ! read_store | python3 - <<'PY'
import json,sys
try:
    json.load(sys.stdin)
except Exception:
    sys.exit(1)
PY
    then
      error "invalid JSON in store"
      exit 3
    fi
    warn "jq not found: limited diagnostics"
  fi

  if is_jq_available; then
    local broken
    broken=$(read_store | jq -r 'to_entries[] | select((.value.cmd|type!="string" or length==0) or (.value.origin.type|type!="string" or length==0) or (.value.created_at|type!="string" or length==0) or (.value.tags|type!="array")) | .key')
    if [[ -n $broken ]]; then
      warn "broken metadata for:"
      printf '%s\n' "$broken" >&2
    fi

    local dup
    dup=$(read_store | jq -r 'to_entries | group_by(.value.cmd) | map(select(length>1)) | .[] | map(.key) | @tsv')
    if [[ -n $dup ]]; then
      warn "duplicate commands detected:"
      printf '%s\n' "$dup" >&2
    fi
  fi

  while IFS= read -r entry; do
    local name cmd
    if is_jq_available; then
      name=$(printf '%s' "$entry" | jq -r '.key')
      cmd=$(printf '%s' "$entry" | jq -r '.value.cmd')
    else
      read -r name cmd < <(printf '%s' "$entry" | python3 - <<'PY'
import json,sys
try:
    e=json.loads(sys.stdin.read())
    v=e.get('value',{})
    print(e.get('key',''))
    print(v.get('cmd',''))
except Exception:
    print('')
    print('')
PY
)
    fi
    if [[ -z $name || -z $cmd ]]; then
      continue
    fi
    local first=${cmd%% *}
    if [[ -n $first ]] && ! command -v "$first" >/dev/null 2>&1; then
      warn "missing binary for '$name': $first"
    fi
  done < <(json_all_entries)
}
