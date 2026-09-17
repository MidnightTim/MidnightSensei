# Commit Notes — v1.7.7

**Date:** 09/16/2026
**Author:** midnightstockton
**Branch:** main
**Tag:** v1.7.7

## Summary

Follow-up bugfix release. A user report after 1.7.6 shipped flagged that Unholy Death Knight's Death Strike was being scored as an expected core-rotation spell when it should be optional/situational. Fixed and released on its own rather than bundled into a larger batch.

## Changed Files

- `MidnightSensei.toc` — version bump 1.7.6 → 1.7.7
- `Core.lua` — `Core.VERSION` fallback bump; new v1.7.7 `Core.CHANGELOG` entry
- `Specs/DeathKnight.lua` — Unholy's Death Strike reclassified from expected-rotation to `isUtility = true`
- `ISSUE_dk_unholy_death_strike.md` — new issue file
- `RELEASE_NOTES_1.7.7.md` — new release notes

## Commits

```
fix(deathknight): stop scoring Unholy Death Strike as expected core rotation

chore: bump version to 1.7.7 and update changelog
```
