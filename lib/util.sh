#!/usr/bin/env bash
set -euo pipefail

ALX_DESC=""
ALX_TAGS=""
ALX_FORCE=0
ALX_STRICT=0

is_jq_available() {
  command -v jq >/dev/null 2>&1
}

now_utc() {
  date -u "+%Y-%m-%dT%H:%M:%SZ"
}

valid_name() {
  local name="$1"
  # Match shell alias naming: any non-empty token without whitespace or '='.
  [[ $name =~ ^[^[:space:]=]+$ ]]
}

shell_escape_single() {
  local s="$1"
  s=${s//"'"/"'\\''"}
  printf "%s" "$s"
}

escape_meta_desc() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//"/\\"}
  printf "%s" "$s"
}

parse_add_flags() {
  ALX_DESC=""
  ALX_TAGS=""
  ALX_FORCE=0
  ALX_STRICT=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --desc)
        shift
        ALX_DESC=${1-}
        ;;
      --tags)
        shift
        ALX_TAGS=${1-}
        ;;
      --force)
        ALX_FORCE=1
        ;;
      --strict)
        ALX_STRICT=1
        ;;
      *)
        ;;
    esac
    shift || true
  done
}

parse_import_flags() {
  ALX_FORCE=0
  ALX_STRICT=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)
        ALX_FORCE=1
        ;;
      --strict)
        ALX_STRICT=1
        ;;
      *)
        ;;
    esac
    shift || true
  done
}

split_tags_json() {
  local tags="$1"
  if [[ -z $tags ]]; then
    printf '[]'
    return
  fi
  IFS=',' read -r -a parts <<<"$tags"
  local out="["
  local first=1
  local t
  for t in "${parts[@]}"; do
    t=${t## }
    t=${t%% }
    if [[ -z $t ]]; then
      continue
    fi
    if [[ $first -eq 0 ]]; then
      out+=" ,"
    fi
    first=0
    out+="\"$t\""
  done
  out+="]"
  printf '%s' "$out"
}

require_jq_write() {
  return 0
}
