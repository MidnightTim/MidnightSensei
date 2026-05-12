# Commit Record — v1.6.7

**Date:** 2026-05-12
**Author:** Midnight - Thrall (US)
**Branch:** main
**Tag:** v1.6.7
**Status:** Release

---

## Summary

Fixes a silent tracking failure where Marksmanship Hunter players using the Dark Ranger hero talent were incorrectly flagged for never using Kill Shot. The `suppressIfTalent` field on the Kill Shot entry was set to a talent node ID (94987) instead of a spell ID (466932), causing both CastTracker's `IsTalentActive` check and the verify report's `IsPlayerSpell` check to always return false. Also adds `altIds = {466930}` to Black Arrow to capture an alternate cast event ID.

---

## Changed Files

| File | Change |
|---|---|
| `Specs/Hunter.lua` | Kill Shot suppressIfTalent 94987 → 466932; Black Arrow altIds = {466930} added |
| `Core.lua` | Version 1.6.6 → 1.6.7; CHANGELOG 1.6.7 entry added |
| `MidnightSensei.toc` | Version 1.6.6 → 1.6.7 |

---

## Conventional Commits

```
fix(hunter): correct Kill Shot suppressIfTalent from node ID to spell ID

suppressIfTalent = 94987 (node ID) never matched IsTalentActive or
IsPlayerSpell because both operate on spell IDs. Changed to 466932
(Black Arrow spell ID) which IsPlayerSpell returns true for on any
Dark Ranger MM Hunter, correctly suppressing Kill Shot tracking.

Closes #<issue>

feat(hunter): add altIds = {466930} to MM Hunter Black Arrow

466930 is an alternate cast event ID that fires in some combat
contexts alongside the primary 466932. Both IDs now credit the
same rotational slot.
```
