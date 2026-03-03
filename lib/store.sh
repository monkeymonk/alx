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

ensure_store() {
  mkdir -p "$(alx_alias_dir)"
}
