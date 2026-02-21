#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_helpers.sh"

setup_temp
trap teardown_temp EXIT

# Fake fzf: return first line from stdin
fake_bin="$TEMP_DIR/bin"
mkdir -p "$fake_bin"
cat > "$fake_bin/fzf" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
head -n1
SH
chmod +x "$fake_bin/fzf"
export PATH="$fake_bin:$PATH"

"$ALX_BIN" a1="echo one" --desc "One" --tags t1
"$ALX_BIN" a2="echo two" --desc "Two" --tags t2

pick_out=$("$ALX_BIN" pick)
assert_eq "a1" "$pick_out" "pick returns first alias"

exec_out=$("$ALX_BIN" pick --exec)
assert_eq "one" "$exec_out" "pick --exec runs command"
