# Commit — Midnight Sensei v1.4.3

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Branch:** main
**Tag:** v1.4.3

---

## Summary

Version watermark on Fight Complete window showing the version that generated each specific feedback. Two Devourer false-positive fixes: Void Metamorphosis removed (shapeshifting, not trackable via cast events), Reap flagged VERIFY (wrong ID at runtime). Scrollbar overlap fix on version label.

---

## Changed Files

- `Core.lua` — version 1.4.3, changelog, Devourer spec DB
- `Analytics.lua` — addonVersion stored in result struct
- `UI.lua` — version watermark on Fight Complete frame

---

## Commits

### chore: bump version to 1.4.3, update changelog

### feat(ui): version watermark on Fight Complete window
Version label added to Fight Complete frame, BOTTOMRIGHT anchored above button row. 8pt font, TEXT_DIM colour, 50% alpha. Stored as `resultFrame._verLabel` so it can be updated per-result. Positioned at x=-88 to clear the UIPanelScrollFrameTemplate scrollbar arrow.

### feat(analytics): store addonVersion with each encounter result
`addonVersion = Core.VERSION` added to the result table in `OnCombatEnd → CalculateGrade`. Stored permanently with every encounter going forward. Pre-1.4.3 encounters fall back to `Core.VERSION` at display time.

### fix(ui): version label reads from result.addonVersion not Core.VERSION
`ShowResultPanel` now sets `_verLabel` text from `result.addonVersion` (the version that generated the feedback) rather than the live `Core.VERSION`. Old fights show their original version; new fights show the current version.

### fix(spec-db/dh/devourer): Void Metamorphosis removed from rotationalSpells
`191427` removed. Shapeshifting spells fire `UPDATE_SHAPESHIFT_FORM`, not `UNIT_SPELLCAST_SUCCEEDED` or `UNIT_SPELLCAST_CHANNEL_START`. The addon has no listener for shapeshift events — `useCount` was permanently 0, generating false "Rotational spell(s) never used: Void Metamorphosis" feedback on every fight.

### fix(spec-db/dh/devourer): Reap flagged VERIFY
`344862` Reap confirmed in `rotationalTracking` at fight start via `/ms debug rotational`. Casts confirmed in damage meter (163K). `useCount` stays 0. Suspected spec-variant ID mismatch — game fires different ID at runtime. Flagged VERIFY, requires `/ms verify` in-game to capture actual cast ID.
