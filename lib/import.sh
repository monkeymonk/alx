#!/usr/bin/env bash
set -euo pipefail

import_aliases() {
  local file="$1"
  local input_source="$file"
  if [[ $file == "-" ]]; then
    input_source="/dev/stdin"
    file="stdin"
  elif [[ ! -f $file ]]; then
    error "file not found: $file"
    exit 1
  fi
  ensure_store

  local meta_name=""
  local meta_desc=""
  local meta_tags=""

  while IFS= read -r line || [[ -n $line ]]; do
    if [[ $line =~ ^#\ alx: ]]; then
      local meta=${line#\# alx:}
      if [[ $meta =~ (^|[[:space:]])name=([^[:space:]]+) ]]; then
        meta_name=${BASH_REMATCH[2]}
      else
        meta_name=""
      fi
      if [[ $meta =~ (^|[[:space:]])desc=\"([^\"]*)\" ]]; then
        meta_desc=$(unescape_meta_desc "${BASH_REMATCH[2]}")
      elif [[ $meta =~ (^|[[:space:]])desc=([^[:space:]]+) ]]; then
        meta_desc=$(unescape_meta_desc "${BASH_REMATCH[2]}")
      else
        meta_desc=""
      fi
      if [[ $meta =~ (^|[[:space:]])tags=([^[:space:]]+) ]]; then
        meta_tags=${BASH_REMATCH[2]}
      else
        meta_tags=""
      fi
      continue
    fi

    if [[ $line =~ ^(alias[[:space:]]+(--[[:space:]]+)?)?([^[:space:]=]+)=(.*)$ ]]; then
      local name=${BASH_REMATCH[3]}
      local rhs=${BASH_REMATCH[4]}
      rhs=${rhs#"${rhs%%[![:space:]]*}"}
      rhs=${rhs%"${rhs##*[![:space:]]}"}
      local cmd=""
      if [[ $rhs =~ ^\'(.*)\'$ ]]; then
        cmd=${BASH_REMATCH[1]}
        cmd=${cmd//"'\\''"/"'"}
      elif [[ $rhs =~ ^\"(.*)\"$ ]]; then
        cmd=${BASH_REMATCH[1]}
      else
        cmd=$rhs
      fi

      if [[ -n $meta_name ]]; then
        name=$meta_name
      fi

      if ! valid_name "$name"; then
        warn "invalid alias name: $name"
        meta_name=""; meta_desc=""; meta_tags=""
        continue
      fi

      if alias_exists "$name" && [[ $ALX_FORCE -ne 1 ]]; then
        warn "skipping '$name': already exists (use --force to overwrite)"
        meta_name=""; meta_desc=""; meta_tags=""
        continue
      fi

      local origin_type
      if [[ -n $meta_name || -n $meta_desc || -n $meta_tags ]]; then
        origin_type="import"
      else
        origin_type="legacy-import"
      fi

      write_alias "$name" "$cmd" "$meta_desc" "$meta_tags" "$origin_type" "$file" "$(now_utc)"

      meta_name=""; meta_desc=""; meta_tags=""
    fi
  done < "$input_source"
}
