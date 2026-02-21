#!/usr/bin/env bash
set -euo pipefail

export_aliases() {
  ALX_QUIET=1
  ensure_store

  while IFS= read -r entry; do
    local name
    local cmd
    local desc
    local tags
    if is_jq_available; then
      name=$(printf '%s' "$entry" | jq -r '.key')
    else
      name=$(printf '%s' "$entry" | python3 - <<'PY'
import json,sys
try:
    e=json.loads(sys.stdin.read())
    print(e.get('key',''))
except Exception:
    pass
PY
)
    fi
    if [[ -z $name ]]; then
      continue
    fi
    if is_jq_available; then
      cmd=$(printf '%s' "$entry" | jq -r '.value.cmd')
      desc=$(printf '%s' "$entry" | jq -r '.value.desc // ""')
      tags=$(printf '%s' "$entry" | jq -r '.value.tags // [] | join(",")')
    else
      read -r cmd desc tags < <(printf '%s' "$entry" | python3 - <<'PY'
import json,sys
try:
    e=json.loads(sys.stdin.read())
    v=e.get('value',{})
    cmd=v.get('cmd','')
    desc=v.get('desc') or ''
    tags=','.join(v.get('tags') or [])
    print(cmd)
    print(desc)
    print(tags)
except Exception:
    print('')
    print('')
    print('')
PY
)
    fi

    local meta
    meta="# alx:name=${name}"
    if [[ -n $desc ]]; then
      meta+=" desc=\"$(escape_meta_desc "$desc")\""
    fi
    if [[ -n $tags ]]; then
      meta+=" tags=${tags}"
    fi
    printf '%s\n' "$meta"
    printf "alias %s='%s'\n" "$name" "$(shell_escape_single "$cmd")"
  done < <(json_all_entries)
}
