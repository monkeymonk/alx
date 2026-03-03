#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_helpers.sh"

setup_temp
trap teardown_temp EXIT

store_dir="$XDG_CONFIG_HOME/alx/aliases"

# --- Test 1: import from stdin via - ---
echo "test 1: import from stdin"

printf "alias gs='git status'\nalias gp='git push'\n" | "$ALX_BIN" import -

assert_eq "git status" "$(alias_field "$store_dir/gs" "cmd")" "stdin gs cmd"
assert_eq "git push"   "$(alias_field "$store_dir/gp" "cmd")" "stdin gp cmd"
assert_eq "stdin"       "$(alias_field "$store_dir/gs" "origin_imported")" "stdin origin"

echo "  pass"

# --- Test 2: import --shell reads from rc files ---
echo "test 2: import --shell"

# Clean store
rm -rf "$store_dir"

# Create fake HOME with shell config files
export HOME="$TEMP_DIR/fakehome"
mkdir -p "$HOME"
cat > "$HOME/.bash_aliases" <<'SH'
alias ll='ls -la'
alias la='ls -A'
SH
cat > "$HOME/.bashrc" <<'SH'
# some config
export PATH="/usr/bin:$PATH"
alias myip='curl ifconfig.me'
SH

"$ALX_BIN" import --shell

assert_eq "ls -la"         "$(alias_field "$store_dir/ll" "cmd")"   "shell ll cmd"
assert_eq "ls -A"          "$(alias_field "$store_dir/la" "cmd")"   "shell la cmd"
assert_eq "curl ifconfig.me" "$(alias_field "$store_dir/myip" "cmd")" "shell myip cmd"

echo "  pass"

# --- Test 3: import zsh-style alias output (no 'alias' prefix) ---
echo "test 3: zsh-style import"

rm -rf "$store_dir"

printf "gs='git status'\ngp='git push'\nll='ls -la'\n" | "$ALX_BIN" import -

assert_eq "git status" "$(alias_field "$store_dir/gs" "cmd")" "zsh gs cmd"
assert_eq "git push"   "$(alias_field "$store_dir/gp" "cmd")" "zsh gp cmd"
assert_eq "ls -la"     "$(alias_field "$store_dir/ll" "cmd")" "zsh ll cmd"

echo "  pass"

echo "all import_stdin tests passed"
