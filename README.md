# alx

A structured, metadata-aware superset of shell `alias` that exports real aliases with deterministic, reversible metadata.

![alx demo](demo.gif)

## Install

Use the install script (it downloads the core files and updates your shell rc):

```bash
curl -fsSL https://raw.githubusercontent.com/monkeymonk/alx/main/install.sh | bash
```

What the installer does:

- Installs `alx` to `~/.local/share/alx/bin/alx`.
- Installs `lib/*.sh` to `~/.local/share/alx/lib/`.
- Adds `~/.local/share/alx/bin` to your PATH in your shell rc file.

To uninstall, remove the PATH line from your rc file and delete `~/.local/share/alx/`.

If you prefer manual install, add `bin/alx` to your PATH.

## Usage

Add aliases:

```bash
alx gs="git status"
alx ll="ls -lah" --desc "Long listing" --tags core,filesystem
```

Explicit form:

```bash
alx add gs "git status" --desc "Git status" --tags git
```

By default, `alx add` is idempotent: if the alias already exists in the registry, it is a no-op. Use `--strict` to warn on existing aliases, or `--force` to overwrite.

Export to your shell:

```bash
eval "$(alx export --shell)"
```

Immediate mode:

```bash
eval "$(alx --immediate gs='git status')"
```

List, show, search:

```bash
alx list
alx list --table
alx show gs
alx search git
```

Help:

```bash
alx help
```

Import and export:

```bash
alx export --shell > aliases.sh
alx import aliases.sh
alias | alx import -        # import current shell aliases via stdin
alx import --shell           # import from ~/.bashrc, ~/.zshrc, etc.
```

Interactive picker:

```bash
alx pick
alx pick --exec
```

FZF search (custom):

```bash
alx falx 'eval "$(alx list | fzf --delimiter=$'\''\t'\'' --with-nth=1,2,3 | cut -f1)"' --desc "Fuzy search and execute alias" --tags "alias,fuzzy"
```

## Philosophy

`alx` stores aliases as structured data, detects conflicts, and exports deterministic native aliases. It augments `alias` rather than replacing it.

## Shell Integration

### Basic: load alx aliases on shell startup

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
eval "$(alx export --shell)"
```

### Full: use alx as a drop-in replacement for `alias`

This wrapper intercepts `alias name='cmd'` calls, stores them in alx, and defines the real shell alias. Plain `alias` (no args) and `alias name` (lookup) work unchanged.

```bash
# Load alx aliases
eval "$(alx export --shell)"

# Intercept alias definitions so they persist in alx
alias() {
  if [[ $# -eq 0 ]]; then
    builtin alias
  elif [[ "$1" == -* ]]; then
    builtin alias "$@"
  elif [[ "$1" == *=* ]]; then
    local name="${1%%=*}" cmd="${1#*=}"
    alx add "$name" "$cmd" --force 2>/dev/null
    builtin alias "$@"
  else
    builtin alias "$@"
  fi
}
```

With this, every `alias gs='git status'` you run also saves to alx. Remove the wrapper anytime — your shell aliases still work normally.

### Bootstrap: import existing aliases

```bash
# Import aliases from your current shell session
alias | alx import -

# Or scan your rc files directly
alx import --shell
```

## Storage

Aliases are stored as one file per alias in:

- `$XDG_CONFIG_HOME/alx/aliases/`
- fallback: `~/.config/alx/aliases/`

To clear all stored aliases:

```bash
rm -rf ~/.config/alx/aliases
```

## Requirements

- Bash 4+ or Zsh 5+

## License

MIT
