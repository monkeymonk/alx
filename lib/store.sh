#!/usr/bin/env bash
set -euo pipefail

alx_alias_dir() {
  if [[ -n ${XDG_CONFIG_HOME-} ]]; then
    printf '%s/alx/aliases' "$XDG_CONFIG_HOME"
  else
    printf '%s/.config/alx/aliases' "$HOME"
  fi
}

alx_alias_file() {
  printf '%s/%s' "$(alx_alias_dir)" "$1"
}

alias_exists() {
  [[ -f "$(alx_alias_file "$1")" ]]
}

# Reads alias file; sets _ALX_CMD _ALX_DESC _ALX_TAGS _ALX_ORIGIN_TYPE _ALX_ORIGIN_FROM _ALX_CREATED_AT
read_alias() {
  local file
  file="$(alx_alias_file "$1")"
  _ALX_CMD="" _ALX_DESC="" _ALX_TAGS="" _ALX_ORIGIN_TYPE="" _ALX_ORIGIN_FROM="" _ALX_CREATED_AT=""
  while IFS= read -r line || [[ -n $line ]]; do
    local key="${line%%=*}"
    local val="${line#*=}"
    case "$key" in
      cmd)             _ALX_CMD="$val" ;;
      desc)            _ALX_DESC="$val" ;;
      tags)            _ALX_TAGS="$val" ;;
      origin_type)     _ALX_ORIGIN_TYPE="$val" ;;
      origin_imported) _ALX_ORIGIN_FROM="$val" ;;
      created_at)      _ALX_CREATED_AT="$val" ;;
    esac
  done < "$file"
}

write_alias() {
  local name="$1" cmd="$2" desc="$3" tags="$4" \
        origin_type="$5" origin_from="$6" created_at="$7"
  local dir
  dir="$(alx_alias_dir)"
  mkdir -p "$dir"
  local tmp
  tmp="${dir}/.${name}.tmp.$$"
  printf 'cmd=%s\ndesc=%s\ntags=%s\norigin_type=%s\norigin_imported=%s\ncreated_at=%s\n' \
    "$cmd" "$desc" "$tags" "$origin_type" "$origin_from" "$created_at" > "$tmp"
  mv "$tmp" "$(alx_alias_file "$name")"
}

delete_alias_file() {
  rm -f "$(alx_alias_file "$1")"
}

# Lists alias names in lexicographic order (bash glob is already sorted)
list_alias_names() {
  local dir
  dir="$(alx_alias_dir)"
  [[ -d $dir ]] || return 0
  local f
  for f in "$dir"/*; do
    [[ -f $f ]] || continue
    printf '%s\n' "${f##*/}"
  done
}

# Migrates legacy aliases.json to per-file format (runs once, backs up old file)
_migrate_legacy_store() {
  local legacy_dir
  if [[ -n ${XDG_CONFIG_HOME-} ]]; then
    legacy_dir="$XDG_CONFIG_HOME/alx"
  else
    legacy_dir="$HOME/.config/alx"
  fi
  local legacy="${legacy_dir}/aliases.json"
  [[ -f $legacy ]] || return 0

  local dir
  dir="$(alx_alias_dir)"
  mkdir -p "$dir"

  python3 - "$legacy" "$dir" <<'PY'
import json, os, sys
legacy, alias_dir = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(legacy))
except Exception:
    sys.exit(0)
for name, v in data.items():
    dest = os.path.join(alias_dir, name)
    if os.path.exists(dest):
        continue
    origin = v.get('origin') or {}
    tmp = dest + '.mig'
    with open(tmp, 'w') as f:
        f.write(f"cmd={v.get('cmd','')}\n")
        f.write(f"desc={v.get('desc') or ''}\n")
        f.write(f"tags={','.join(v.get('tags') or [])}\n")
        f.write(f"origin_type={origin.get('type','manual')}\n")
        f.write(f"origin_imported={origin.get('imported_from') or ''}\n")
        f.write(f"created_at={v.get('created_at','')}\n")
    os.rename(tmp, dest)
PY

  mv "$legacy" "${legacy}.migrated"
  warn "migrated legacy JSON store to per-file format (backup: ${legacy}.migrated)"
}

ensure_store() {
  _migrate_legacy_store
  mkdir -p "$(alx_alias_dir)"
}
