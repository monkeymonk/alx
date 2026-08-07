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

  ensure_store

  if alias_exists "$name"; then
    if [[ $ALX_FORCE -ne 1 ]]; then
      if [[ $ALX_STRICT -eq 1 ]]; then
        warn "alias '$name' already exists in registry (use --force)"
      fi
      return 0
    fi
  fi

  conflict_check "$name" "$ALX_FORCE" "$ALX_STRICT" 0

  write_alias "$name" "$command" "$desc" "$tags" "manual" "" "$(now_utc)"

  if [[ $immediate -eq 1 ]]; then
    printf "alias %s='%s'\n" "$name" "$(shell_escape_single "$command")"
  fi
}

remove_alias() {
  local name="$1"
  ensure_store
  if ! alias_exists "$name"; then
    error "alias '$name' not found"
    exit 1
  fi
  delete_alias_file "$name"
}

list_aliases() {
  local format="tsv"
  if [[ ${1-} == "--table" || ${1-} == "--pretty" ]]; then
    format="table"
  fi

  ensure_store
  local rows=()
  while IFS= read -r name; do
    read_alias "$name"
    if [[ $format == "table" ]]; then
      rows+=("${name}"$'\t'"${_ALX_CMD}"$'\t'"${_ALX_DESC}"$'\t'"${_ALX_TAGS}")
    else
      printf '%s\t%s\t%s\t%s\n' "$name" "$_ALX_CMD" "$_ALX_DESC" "$_ALX_TAGS"
    fi
  done < <(list_alias_names)

  if [[ $format == "table" ]] && [[ ${#rows[@]} -gt 0 ]]; then
    local headers=("NAME" "COMMAND" "DESCRIPTION" "TAGS")
    local widths=(${#headers[0]} ${#headers[1]} ${#headers[2]} ${#headers[3]})
    for row in "${rows[@]}"; do
      IFS=$'\t' read -r f0 f1 f2 f3 <<< "$row"
      (( ${#f0} > widths[0] )) && widths[0]=${#f0}
      (( ${#f1} > widths[1] )) && widths[1]=${#f1}
      (( ${#f2} > widths[2] )) && widths[2]=${#f2}
      (( ${#f3} > widths[3] )) && widths[3]=${#f3}
    done
    printf "%-${widths[0]}s | %-${widths[1]}s | %-${widths[2]}s | %-${widths[3]}s\n" "${headers[@]}"
    printf "%-${widths[0]}s-+-%-${widths[1]}s-+-%-${widths[2]}s-+-%-${widths[3]}s\n" \
      "$(printf '%*s' "${widths[0]}" '' | tr ' ' '-')" \
      "$(printf '%*s' "${widths[1]}" '' | tr ' ' '-')" \
      "$(printf '%*s' "${widths[2]}" '' | tr ' ' '-')" \
      "$(printf '%*s' "${widths[3]}" '' | tr ' ' '-')"
    for row in "${rows[@]}"; do
      IFS=$'\t' read -r f0 f1 f2 f3 <<< "$row"
      printf "%-${widths[0]}s | %-${widths[1]}s | %-${widths[2]}s | %-${widths[3]}s\n" "$f0" "$f1" "$f2" "$f3"
    done
  fi
}

search_aliases() {
  local pattern="$1"
  ensure_store
  while IFS= read -r name; do
    read_alias "$name"
    if printf '%s %s %s %s' "$name" "$_ALX_CMD" "$_ALX_DESC" "$_ALX_TAGS" | \
       grep -qE "$pattern" 2>/dev/null; then
      printf '%s\n' "$name"
    fi
  done < <(list_alias_names)
}

show_alias() {
  local name="$1"
  ensure_store
  if ! alias_exists "$name"; then
    error "alias '$name' not found"
    exit 1
  fi
  read_alias "$name"
  printf 'name: %s\n' "$name"
  printf 'cmd: %s\n' "$_ALX_CMD"
  printf 'desc: %s\n' "$_ALX_DESC"
  printf 'tags: %s\n' "$_ALX_TAGS"
  printf 'origin.type: %s\n' "$_ALX_ORIGIN_TYPE"
  printf 'origin.imported_from: %s\n' "$_ALX_ORIGIN_FROM"
  printf 'created_at: %s\n' "$_ALX_CREATED_AT"
}

where_alias() {
  local name="$1"
  ensure_store
  if ! alias_exists "$name"; then
    error "alias '$name' not found"
    exit 1
  fi
  read_alias "$name"
  printf 'registry: %s\n' "$(alx_alias_dir)"
  printf 'file: %s\n' "$(alx_alias_file "$name")"
  printf 'origin.type: %s\n' "$_ALX_ORIGIN_TYPE"
  printf 'origin.imported_from: %s\n' "$_ALX_ORIGIN_FROM"
}

run_alias() {
  local name="$1"
  ensure_store
  if ! alias_exists "$name"; then
    error "alias '$name' not found"
    exit 1
  fi
  read_alias "$name"
  if [[ -z $_ALX_CMD ]]; then
    error "alias '$name' has empty command"
    exit 1
  fi
  sh -c "$_ALX_CMD"
}
