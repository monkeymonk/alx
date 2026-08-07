# Changelog

## 0.4.1

- Fix `shellcheck` findings: correct `SC1090` to `SC1091` disable directives on
  the `lib/*.sh` sourcing lines in `bin/alx`, remove the unused `local i` in
  `list --table`'s formatter, and mark cross-file-consumed flag globals
  (`ALX_QUIET`, `ALX_DESC`, `ALX_TAGS`, `ALX_FORCE`, `ALX_STRICT`) with
  targeted `SC2034` disables. No behavior change; `shellcheck bin/alx lib/*.sh`
  is now clean.

## 0.4.0

- New inline comment format for export: `alias name='cmd' # desc [tag1, tag2]`
- Import now parses inline `# desc [tags]` from bare alias lines (single and double-quoted)
- Backward-compatible: import still supports legacy `# alx:` metadata format
- Drop `--` prefix from exported alias lines for cleaner output

## 0.3.0

- Add `alx import -` to import aliases from stdin (`alias | alx import -`)
- Add `alx import --shell` to import aliases from shell rc files (~/.bashrc, ~/.zshrc, etc.)
- Replace Python table formatter with pure bash — zero external dependencies
- Remove legacy JSON store migration code and Python 3 requirement
- Remove unused `lib/parser.sh` placeholder
- Install script now prompts before modifying PATH (skips in non-interactive mode)
- Add shell integration guide to README with drop-in `alias` wrapper snippet

## 0.2.1

- Add VHS demo tape and GIF showcasing all commands
- Embed demo GIF in README

## 0.2.0

- Replace JSON store with per-file format: one file per alias in `~/.config/alx/aliases/`
- Remove `jq` dependency entirely — reads are now pure bash, no external tools required
- Atomic writes via temp+mv per alias file; no file locking needed
- Automatic migration from legacy `aliases.json` on first run (backup kept as `aliases.json.migrated`)
- Fix `split_tags_json`: tags with special characters no longer produce malformed output
- Fix `escape_meta_desc`: descriptions with `"` now round-trip correctly via `%22` encoding
- Remove dead `require_jq_write` no-op
- Cache `is_jq_available` per process (removed entirely with jq removal)
- Error on unknown flags instead of silently ignoring them
- Fix stale conflict tests to match idempotent-add behavior introduced in 0.1.2

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
