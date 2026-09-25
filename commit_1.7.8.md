# Commit Notes — v1.7.8

**Date:** 09/25/2026
**Author:** midnightstockton
**Branch:** main
**Tag:** v1.7.8

## Summary

Two bugfixes this release. First, a deeper look at the 1.7.7 Death Strike fix revealed `isUtility` was completely non-functional for `rotationalSpells` across the whole addon (two separate bugs: the flag never survived into the runtime tracking table, and the feedback code never checked it even when it did) - this affected 8 abilities across 6 classes, some going back months, including Lava Burst, the original ability this pattern was built around. Second, a user-reported UI bug where the Fight Complete popup goes stale if left open across multiple fights.

## Changed Files

- `MidnightSensei.toc` — version bump 1.7.7 → 1.7.8
- `Core.lua` — `Core.VERSION` fallback bump; new v1.7.8 `Core.CHANGELOG` entry
- `Combat/CastTracker.lua` — `rotationalTracking[rs.id]` now copies `isUtility` from the spec definition (the actual root cause; a prior Feedback.lua-only fix in 1.7.7 had no effect because this field never existed on the runtime object)
- `Analytics/Feedback.lua` — rotational "never used"/"low used" feedback block now skips entries where `isUtility` is true
- `UI.lua` — `UI.OnCombatEnd` now refreshes the Fight Complete popup in place if it's already open when a new fight completes
- `ISSUE_isutility_rotational_broken.md`, `ISSUE_fight_complete_stale_popup.md` — new issue files
- `RELEASE_NOTES_1.7.8.md` — new release notes

## Commits

```
fix(tracking): copy isUtility flag into runtime rotationalTracking table

fix(feedback): skip isUtility rotational spells in never-used/low-used lists

fix(ui): refresh Fight Complete popup when left open across fights

chore: bump version to 1.7.8 and update changelog
```
