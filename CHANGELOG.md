# Changelog

## 0.1.4

- Installer now defaults to latest release tag instead of `main`

## 0.1.5

- Add `alx list --table` for a cleaner, headered listing
- Document fzf-based alias search example
- Add `-v`/`--version` flag

## 0.1.3

- Allow non-identifier alias names (matching shell alias rules)
- Only warn on binary shadowing when `--strict` is used
- Only warn on function shadowing when `--strict` is used

## 0.1.2

- Make `alx add` idempotent by default (no-op if alias exists)
- Add `--strict` warning for existing aliases and keep `--force` to overwrite

## 0.1.1

- Add installer and documentation updates
- Add CONTRIBUTING, editorconfig, gitattributes, and MIT license
- Add `alx help`
- Improve import parsing and picker formatting
- Expand test coverage, including import/pick edge cases

## 0.1.0

- Initial release with JSON-backed alias registry
- Add/remove/list/show/search/run
- Structured export and import with metadata
- Conflict detection and doctor checks
- Interactive picker
