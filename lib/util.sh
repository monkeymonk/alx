#!/usr/bin/env bash
set -euo pipefail

ALX_DESC=""
ALX_TAGS=""
ALX_FORCE=0
ALX_STRICT=0

now_utc() {
  date -u "+%Y-%m-%dT%H:%M:%SZ"
}

valid_name() {
  local name="$1"
  [[ $name =~ ^[^[:space:]=]+$ ]]
}

shell_escape_single() {
  local s="$1"
  s=${s//"'"/"'\\''"}
  printf "%s" "$s"
}

escape_meta_desc() {
  local s="$1"
  local _dq='"'
  s=${s//\\/\\\\}
  s="${s//$_dq/%22}"
  printf "%s" "$s"
}

unescape_meta_desc() {
  local s="$1"
  local _dq='"'
  s="${s//%22/$_dq}"
  s="${s//\\\\/\\}"
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
        # shellcheck disable=SC2034  # read by bin/alx's add dispatch
        ALX_DESC=${1-}
        ;;
      --tags)
        shift
        # shellcheck disable=SC2034  # read by bin/alx's add dispatch
        ALX_TAGS=${1-}
        ;;
      --force)
        ALX_FORCE=1
        ;;
      --strict)
        ALX_STRICT=1
        ;;
      *)
        error "unknown flag: $1"
        exit 1
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
        # shellcheck disable=SC2034  # read by lib/import.sh
        ALX_FORCE=1
        ;;
      --strict)
        # shellcheck disable=SC2034  # read by lib/import.sh (currently unused there; parity with parse_add_flags)
        ALX_STRICT=1
        ;;
      *)
        error "unknown flag: $1"
        exit 1
        ;;
    esac
    shift || true
  done
}
