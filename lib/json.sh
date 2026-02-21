#!/usr/bin/env bash
set -euo pipefail

json_has_alias() {
  local name="$1"
  if is_jq_available; then
    read_store | jq -e --arg name "$name" 'has($name)' >/dev/null 2>&1
  else
    read_store | python3 - <<'PY' "$name"
import json,sys
name=sys.argv[1]
try:
    data=json.load(sys.stdin)
    sys.exit(0 if name in data else 1)
except Exception:
    sys.exit(1)
PY
  fi
}

json_get_alias() {
  local name="$1"
  if is_jq_available; then
    read_store | jq -c --arg name "$name" '.[$name]'
  else
    read_store | python3 - <<'PY' "$name"
import json,sys
name=sys.argv[1]
try:
    data=json.load(sys.stdin)
    v=data.get(name)
    print(json.dumps(v))
except Exception:
    print('null')
PY
  fi
}

json_set_alias() {
  require_jq_write
  local name="$1"
  local cmd="$2"
  local desc="$3"
  local tags_json="$4"
  local origin_type="$5"
  local origin_imported="$6"
  local created_at="$7"

  with_lock _json_set_alias_impl "$name" "$cmd" "$desc" "$tags_json" "$origin_type" "$origin_imported" "$created_at"
}

_json_set_alias_impl() {
  local name="$1"
  local cmd="$2"
  local desc="$3"
  local tags_json="$4"
  local origin_type="$5"
  local origin_imported="$6"
  local created_at="$7"
  local content
  if is_jq_available; then
    content=$(read_store | jq \
      --arg name "$name" \
      --arg cmd "$cmd" \
      --arg desc "$desc" \
      --arg origin_type "$origin_type" \
      --arg origin_imported "$origin_imported" \
      --arg created_at "$created_at" \
      --argjson tags "$tags_json" \
      '.[$name] = {cmd:$cmd, desc:(if ($desc|length)>0 then $desc else null end), tags:$tags, origin:{type:$origin_type, imported_from:(if ($origin_imported|length)>0 then $origin_imported else null end)}, created_at:$created_at}' )
  else
    content=$(read_store | python3 - "$name" "$cmd" "$desc" "$tags_json" "$origin_type" "$origin_imported" "$created_at" <<'PY'
import json,sys
name,cmd,desc,tags_json,origin_type,origin_imported,created_at = sys.argv[1:8]
try:
    data=json.load(sys.stdin)
except Exception:
    data={}
try:
    tags=json.loads(tags_json)
except Exception:
    tags=[]
data[name]={
    "cmd": cmd,
    "desc": desc if len(desc)>0 else None,
    "tags": tags,
    "origin": {
        "type": origin_type,
        "imported_from": origin_imported if len(origin_imported)>0 else None,
    },
    "created_at": created_at,
}
print(json.dumps(data, separators=(',',':')))
PY
)
  fi
  save_store "$content"
}

json_remove_alias() {
  require_jq_write
  local name="$1"

  with_lock _json_remove_alias_impl "$name"
}

_json_remove_alias_impl() {
  local name="$1"
  local content
  if is_jq_available; then
    content=$(read_store | jq --arg name "$name" 'del(.[$name])')
  else
    content=$(read_store | python3 - "$name" <<'PY'
import json,sys
name=sys.argv[1]
try:
    data=json.load(sys.stdin)
except Exception:
    data={}
if name in data:
    del data[name]
print(json.dumps(data, separators=(',',':')))
PY
)
  fi
  save_store "$content"
}

json_list_aliases() {
  if is_jq_available; then
    read_store | jq -r 'keys[]'
  else
    read_store | python3 - <<'PY'
import json,sys
try:
    data=json.load(sys.stdin)
    for k in sorted(data.keys()):
        print(k)
except Exception:
    pass
PY
  fi
}

json_search_aliases() {
  local pattern="$1"
  if is_jq_available; then
    read_store | jq -r --arg pat "$pattern" 'to_entries[] | select((.key|test($pat)) or (.value.cmd|test($pat)) or (.value.desc // ""|test($pat)) or ((.value.tags // [])|join(",")|test($pat))) | .key'
  else
    read_store | python3 - <<'PY' "$pattern"
import json,re,sys
pat=sys.argv[1]
try:
    rx=re.compile(pat)
except Exception:
    rx=re.compile(re.escape(pat))
try:
    data=json.load(sys.stdin)
    for k,v in sorted(data.items()):
        blob=' '.join([k, v.get('cmd',''), v.get('desc') or '', ','.join(v.get('tags') or [])])
        if rx.search(blob):
            print(k)
except Exception:
    pass
PY
  fi
}

json_all_entries() {
  if is_jq_available; then
    read_store | jq -c 'to_entries | sort_by(.key)[]'
  else
    read_store | python3 - <<'PY'
import json,sys
try:
    data=json.load(sys.stdin)
    for k in sorted(data.keys()):
        print(json.dumps({"key":k,"value":data[k]}))
except Exception:
    pass
PY
  fi
}
