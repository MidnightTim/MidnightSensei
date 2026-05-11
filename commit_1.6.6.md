# Commit Record — v1.6.6

**Date:** May 10, 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.6.6
**Type:** Critical Hotfix

---

## Summary

Critical fix: WoW Lua does not support \xNN hex escape sequences — backslash is silently dropped, producing garbled text in all coaching feedback. All four locale files patched. One-time SavedVariables migration added to repair already-persisted broken strings. v1.6.5 was pulled after this bug was discovered post-release.

---

## Conventional Commits

```
fix(locales)!: replace all \xNN hex escape sequences with literal UTF-8 characters
  — WoW Lua silently drops backslash on \xNN; affects enUS, esES, deDE, frFR
  — 656 total sequences replaced across all four files

fix(core): add PatchStoredEscapes() one-time login migration for SavedVariables feedback strings

chore(toc): bump version to 1.6.6
chore(core): CHANGELOG entry for v1.6.6; version fallback bumped to 1.6.6
```

---

## Changed Files

| File | Type | Description |
|---|---|---|
| `Locales/enUS.lua` | fix | All `\xNN` sequences replaced with literal UTF-8 |
| `Locales/esES.lua` | fix | 624 `\xNN` sequences fixed (pre-existing silent breakage) |
| `Locales/deDE.lua` | fix | All umlauts and special chars fixed |
| `Locales/frFR.lua` | fix | All accented chars fixed |
| `Core.lua` | fix+chore | PatchStoredEscapes() added; CHANGELOG v1.6.6; version fallback = "1.6.6" |
| `MidnightSensei.toc` | chore | Version 1.6.6 |

---

## Issues Closed

- #165 — ISSUE_hex_escape_locale_v166.md — Critical: \xNN hex escapes broken in WoW Lua
