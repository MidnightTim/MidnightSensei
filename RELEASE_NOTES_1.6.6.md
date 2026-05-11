# Midnight Sensei v1.6.6 Release Notes

**Release Date:** May 10, 2026
**Author:** Midnight - Thrall (US)
**Type:** Critical Hotfix

> v1.6.5 was pulled after a critical locale encoding bug was discovered post-release.
> This release contains only the fix. All v1.6.5 features ship intact in this build.

---

## Critical Bug Fix: Locale Escape Sequences — All Four Locale Files

WoW's Lua does not support `\xNN` hex escape sequences in string literals. The backslash is silently dropped, causing the literal text `xNN` to appear in-game. Every locale file was affected since the day it was written.

**Visible symptom:** Em dashes (—) in all coaching feedback messages rendered as `xe2x80x94`. Middle dots (·) in system messages rendered as `xC2xB7`. On non-English locales, every accented character was garbage text.

**Fix:** All `\xNN` sequences replaced with literal UTF-8 characters in all four locale files (`enUS`, `esES`, `deDE`, `frFR`). Total: 656 sequences fixed across the four files.

**Stored data:** Encounter feedback strings generated before this fix were persisted in SavedVariables with the broken characters baked in. A one-time migration (`Core.PatchStoredEscapes()`) runs automatically 1 second after login and repairs all saved feedback strings in encounter history and Boss Board bests. It runs exactly once per character, gated by `cdb.v165_escape_fix`.

**Rule going forward:** Never write `\xNN` in any Lua string literal. Use the literal UTF-8 character directly in source files.

---

## Files Changed

| File | Change |
|---|---|
| `Locales/enUS.lua` | All `\xNN` escape sequences replaced with literal UTF-8 characters |
| `Locales/esES.lua` | 624 `\xNN` sequences fixed (pre-existing silent breakage) |
| `Locales/deDE.lua` | All umlauts and special chars fixed |
| `Locales/frFR.lua` | All accented chars fixed |
| `Core.lua` | `PatchStoredEscapes()` migration added; CHANGELOG entry for v1.6.6; version fallback bumped to 1.6.6 |
| `MidnightSensei.toc` | Version bumped to 1.6.6 |
