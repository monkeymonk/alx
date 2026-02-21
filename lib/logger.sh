#!/usr/bin/env bash
set -euo pipefail

log() {
  if [[ ${ALX_QUIET-0} -eq 1 ]]; then
    return
  fi
  printf '%s\n' "$*" >&2
}

info() { log "$*"; }
warn() { log "warning: $*"; }
error() { log "error: $*"; }
