#!/usr/bin/env bash
set -euo pipefail

alx_config_dir() {
  if [[ -n ${XDG_CONFIG_HOME-} ]]; then
    printf '%s' "$XDG_CONFIG_HOME"
  else
    printf '%s' "$HOME/.config"
  fi
}

alx_store_path() {
  printf '%s/alx/aliases.json' "$(alx_config_dir)"
}

ensure_store() {
  local path
  path="$(alx_store_path)"
  local dir
  dir="$(dirname "$path")"
  mkdir -p "$dir"
  if [[ ! -f $path ]]; then
    printf '{}' > "$path"
  fi
}

with_lock() {
  local lockfile
  lockfile="$(alx_store_path).lock"
  if command -v flock >/dev/null 2>&1; then
    exec 9>"$lockfile"
    flock -x 9
    "$@"
    flock -u 9
    exec 9>&-
  else
    "$@"
  fi
}

read_store() {
  ensure_store
  cat "$(alx_store_path)"
}

save_store() {
  local content="$1"
  local path
  path="$(alx_store_path)"
  local dir
  dir="$(dirname "$path")"
  local tmp
  tmp="${dir}/.aliases.json.tmp.$$"
  if [[ -f $path ]]; then
    cp "$path" "${path}.bak" >/dev/null 2>&1 || true
  fi
  printf '%s' "$content" > "$tmp"
  mv "$tmp" "$path"
}
