#!/usr/bin/env bash
set -euo pipefail

add_alias() {
  local name="$1"
  local command="$2"
  local desc="$3"
  local tags="$4"
  local immediate="$5"

  if ! valid_name "$name"; then
    error "invalid alias name: $name"
    exit 1
  fi

  require_jq_write
  ensure_store

  if json_has_alias "$name"; then
    if [[ $ALX_FORCE -ne 1 ]]; then
      if [[ $ALX_STRICT -eq 1 ]]; then
        warn "alias '$name' already exists in registry (use --force)"
      fi
      return 0
    fi
  fi

  conflict_check "$name" "$ALX_FORCE" "$ALX_STRICT" 0

  local tags_json
  tags_json=$(split_tags_json "$tags")

  json_set_alias "$name" "$command" "$desc" "$tags_json" "manual" "" "$(now_utc)"

  if [[ $immediate -eq 1 ]]; then
    printf "alias %s='%s'\n" "$name" "$(shell_escape_single "$command")"
  fi
}

remove_alias() {
  local name="$1"
  require_jq_write
  ensure_store
  if ! json_has_alias "$name"; then
    error "alias '$name' not found"
    exit 1
  fi
  json_remove_alias "$name"
}

list_aliases() {
  local format="tsv"
  if [[ ${1-} == "--table" || ${1-} == "--pretty" ]]; then
    format="table"
  fi

  ensure_store
  local rows=()
  while IFS= read -r entry; do
    local name cmd desc tags
    if is_jq_available; then
      name=$(printf '%s' "$entry" | jq -r '.key')
      cmd=$(printf '%s' "$entry" | jq -r '.value.cmd')
      desc=$(printf '%s' "$entry" | jq -r '.value.desc // ""')
      tags=$(printf '%s' "$entry" | jq -r '.value.tags // [] | join(",")')
    else
      read -r name cmd desc tags < <(printf '%s' "$entry" | python3 - <<'PY'
import json,sys
try:
    e=json.loads(sys.stdin.read())
    v=e.get('value',{})
    print(e.get('key',''))
    print(v.get('cmd',''))
    print(v.get('desc') or '')
    print(','.join(v.get('tags') or []))
except Exception:
    print('')
    print('')
    print('')
    print('')
PY
)
    fi
    if [[ -z $name ]]; then
      continue
    fi

    if [[ $format == "table" ]]; then
      cmd=${cmd//$'\t'/ }
      desc=${desc//$'\t'/ }
      tags=${tags//$'\t'/ }
      rows+=("${name}"$'\t'"${cmd}"$'\t'"${desc}"$'\t'"${tags}")
    else
      printf '%s\t%s\t%s\t%s\n' "$name" "$cmd" "$desc" "$tags"
    fi
  done < <(json_all_entries)

  if [[ $format == "table" ]]; then
    printf '%s\n' "${rows[@]}" | python3 -c 'import sys
headers = ["NAME", "COMMAND", "DESCRIPTION", "TAGS"]
rows = [line.rstrip("\n").split("\t") for line in sys.stdin if line.strip("\n") != ""]
widths = [len(h) for h in headers]
for row in rows:
    for i, value in enumerate(row):
        if i < len(widths):
            widths[i] = max(widths[i], len(value))
def format_row(values):
    padded = [values[i].ljust(widths[i]) for i in range(len(widths))]
    return " | ".join(padded)
print(format_row(headers))
print("-+-".join("-" * w for w in widths))
for row in rows:
    print(format_row(row))'
  fi
}

search_aliases() {
  ensure_store
  json_search_aliases "$1"
}

show_alias() {
  local name="$1"
  ensure_store
  local obj
  obj=$(json_get_alias "$name")
  if [[ $obj == "null" || -z $obj ]]; then
    error "alias '$name' not found"
    exit 1
  fi

  if is_jq_available; then
    printf 'name: %s\n' "$name"
    printf 'cmd: %s\n' "$(printf '%s' "$obj" | jq -r '.cmd')"
    printf 'desc: %s\n' "$(printf '%s' "$obj" | jq -r '.desc // ""')"
    printf 'tags: %s\n' "$(printf '%s' "$obj" | jq -r '.tags // [] | join(",")')"
    printf 'origin.type: %s\n' "$(printf '%s' "$obj" | jq -r '.origin.type')"
    printf 'origin.imported_from: %s\n' "$(printf '%s' "$obj" | jq -r '.origin.imported_from // ""')"
    printf 'created_at: %s\n' "$(printf '%s' "$obj" | jq -r '.created_at')"
  else
    python3 - <<'PY' "$name" "$obj"
import json,sys
name=sys.argv[1]
obj=json.loads(sys.argv[2])
print(f"name: {name}")
print(f"cmd: {obj.get('cmd','')}")
print(f"desc: {obj.get('desc') or ''}")
print(f"tags: {','.join(obj.get('tags') or [])}")
origin=obj.get('origin') or {}
print(f"origin.type: {origin.get('type','')}")
print(f"origin.imported_from: {origin.get('imported_from') or ''}")
print(f"created_at: {obj.get('created_at','')}")
PY
  fi
}

where_alias() {
  local name="$1"
  ensure_store
  if ! json_has_alias "$name"; then
    error "alias '$name' not found"
    exit 1
  fi
  local obj
  obj=$(json_get_alias "$name")
  local origin_type origin_from
  if is_jq_available; then
    origin_type=$(printf '%s' "$obj" | jq -r '.origin.type')
    origin_from=$(printf '%s' "$obj" | jq -r '.origin.imported_from // ""')
  else
    read -r origin_type origin_from < <(python3 - <<'PY' "$obj"
import json,sys
obj=json.loads(sys.argv[1])
origin=obj.get('origin') or {}
print(origin.get('type',''))
print(origin.get('imported_from') or '')
PY
)
  fi
  printf 'registry: %s\n' "$(alx_store_path)"
  printf 'origin.type: %s\n' "$origin_type"
  printf 'origin.imported_from: %s\n' "$origin_from"
}

run_alias() {
  local name="$1"
  ensure_store
  local obj
  obj=$(json_get_alias "$name")
  if [[ $obj == "null" || -z $obj ]]; then
    error "alias '$name' not found"
    exit 1
  fi
  local cmd
  if is_jq_available; then
    cmd=$(printf '%s' "$obj" | jq -r '.cmd')
  else
    cmd=$(python3 - <<'PY' "$obj"
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get('cmd',''))
PY
)
  fi
  if [[ -z $cmd ]]; then
    error "alias '$name' has empty command"
    exit 1
  fi
  sh -c "$cmd"
}
