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
      local cmd="" inline_comment=""

      # Single-quoted with trailing comment
      if [[ $rhs =~ ^(\'.*\')[[:space:]]+#[[:space:]]*(.*) ]]; then
        local quoted="${BASH_REMATCH[1]}"
        inline_comment="${BASH_REMATCH[2]}"
        inline_comment="${inline_comment%"${inline_comment##*[![:space:]]}"}"
        if [[ $quoted =~ ^\'(.*)\'$ ]]; then
          cmd=${BASH_REMATCH[1]}
          cmd=${cmd//"'\\''"/"'"}
        fi
      # Double-quoted with trailing comment
      elif [[ $rhs =~ ^(\".*\")[[:space:]]+#[[:space:]]*(.*) ]]; then
        local quoted="${BASH_REMATCH[1]}"
        inline_comment="${BASH_REMATCH[2]}"
        inline_comment="${inline_comment%"${inline_comment##*[![:space:]]}"}"
        if [[ $quoted =~ ^\"(.*)\"$ ]]; then
          cmd=${BASH_REMATCH[1]}
        fi
      # Single-quoted without comment
      elif [[ $rhs =~ ^\'(.*)\'$ ]]; then
        cmd=${BASH_REMATCH[1]}
        cmd=${cmd//"'\\''"/"'"}
      # Double-quoted without comment
      elif [[ $rhs =~ ^\"(.*)\"$ ]]; then
        cmd=${BASH_REMATCH[1]}
      else
        cmd=$rhs
      fi

      # Parse inline comment for desc/tags when no alx metadata present
      if [[ -n $inline_comment && -z $meta_name && -z $meta_desc && -z $meta_tags ]]; then
        if [[ $inline_comment =~ ^(.*)\[([^]]*)\][[:space:]]*$ ]]; then
          meta_tags="${BASH_REMATCH[2]}"
          meta_tags="${meta_tags// /}"
          meta_desc="${BASH_REMATCH[1]}"
          meta_desc="${meta_desc%"${meta_desc##*[![:space:]]}"}"
        else
          meta_desc="$inline_comment"
        fi
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
