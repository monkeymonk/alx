# alx

A structured, metadata-aware superset of shell `alias` that exports real aliases with deterministic, reversible metadata.

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

`jq` is optional; if installed it is used for faster JSON handling.

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
```

Interactive picker:

```bash
alx pick
alx pick --exec
```

## Philosophy

`alx` stores aliases as structured data, detects conflicts, and exports deterministic native aliases. It augments `alias` rather than replacing it.

## Integration Guide

Add this to your shell profile.

Bash (`~/.bashrc`):

```bash
eval "$(alx export --shell)"
```

Zsh (`~/.zshrc`):

```bash
eval "$(alx export --shell)"
```

## Storage

Aliases are stored in:

- `$XDG_CONFIG_HOME/alx/aliases.json`
- fallback: `~/.config/alx/aliases.json`

## Requirements

- Bash 4+ or Zsh 5+
- Python 3
- `jq` optional

## License

MIT
