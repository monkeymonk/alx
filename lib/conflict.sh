#!/usr/bin/env bash
set -euo pipefail

conflict_check() {
  local name="$1"
  local force="$2"
  local strict="$3"
  local check_registry="${4:-1}"

  if [[ $check_registry -eq 1 ]]; then
    if json_has_alias "$name"; then
      if [[ $force -ne 1 ]]; then
        error "alias '$name' already exists in registry (use --force)"
        exit 2
      fi
    fi
  fi

  if alias "$name" >/dev/null 2>&1; then
    if [[ $force -ne 1 ]]; then
      warn "alias '$name' already exists in current shell (use --force)"
      exit 2
    fi
  fi

  if type "$name" 2>/dev/null | grep -q "function"; then
    if [[ $force -ne 1 ]]; then
      warn "function '$name' exists (use --force)"
      exit 2
    fi
  fi

  if command -v "$name" >/dev/null 2>&1; then
    if [[ $strict -eq 1 ]]; then
      warn "binary '$name' exists (use --force or drop --strict)"
      exit 2
    else
      warn "binary '$name' exists"
    fi
  fi
}
