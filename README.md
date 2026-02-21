# alx

A structured, metadata-aware superset of shell `alias` that exports real aliases with deterministic, reversible metadata.

## Installation

1. Add `bin/alx` to your PATH.
2. `jq` is optional; if installed it is used for faster JSON handling.

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
