# Midnight Sensei v1.4.3 — Version Watermark, Feedback Snapshot & Devourer Fixes

## Overview

1.4.3 is a small quality-of-life and bug-fix release. It adds a persistent version watermark to the Fight Complete window, fixes two Devourer tracking issues that were producing false "never used" feedback, and repositions the version label to avoid overlap with the scrollbar.

---

## Version Watermark on Fight Complete Window

The Fight Complete window now shows the addon version in the bottom-right corner, above the button row. It sits between the Leaderboard and Close buttons, clear of the scrollbar arrow.

The label is **8pt, dimmed at 50% opacity** — visible when you look for it, invisible when you don't.

**The version shown is the version that generated that specific feedback** — not the currently running version. This means:
- If a player on 1.4.2 sends a screenshot, it shows `v1.4.2`
- If the same fight is reviewed after upgrading to 1.4.3, it still shows `v1.4.2`
- This eliminates the support question "which version are you on?" entirely

`addonVersion` is now stored as a permanent field on every encounter result going forward. Encounters recorded before 1.4.3 fall back to displaying the current running version.

---

## Devourer Bug Fixes

### Void Metamorphosis — Removed from Rotational Tracking

`191427` Void Metamorphosis has been removed from `rotationalSpells`.

**Root cause:** Metamorphosis is a shapeshifting spell. It fires `UPDATE_SHAPESHIFT_FORM` when activated, not `UNIT_SPELLCAST_SUCCEEDED`. The addon's cast tracking is built entirely on `UNIT_SPELLCAST_SUCCEEDED` and `UNIT_SPELLCAST_CHANNEL_START`. Since neither event fires for Metamorphosis, `useCount` stays at 0 permanently — even on fights where it was used multiple times. This was causing false "Rotational spell(s) never used: Void Metamorphosis" feedback on every Devourer fight.

Void Metamorphosis cannot be tracked via cast events with the current architecture. Removed.

### Reap — Flagged VERIFY

`344862` Reap remains in `rotationalSpells` but is now flagged VERIFY.

**Observed behaviour:** The fight debug snapshot (`/ms debug rotational`) confirms `id=344862 label=Reap` is present in `rotationalTracking` at fight start. Damage meter data confirms Reap was cast and dealt 163K damage. But `useCount` stays at 0.

**Suspected cause:** The game fires a different spell ID for the Devourer-specific Reap at runtime than the ID captured in the spell snapshot. This is the same spec-variant issue seen with Festering Strike (Unholy DK), Kill Command (Survival Hunter), and others throughout the 1.4.x audit.

Needs `/ms verify` in-game on a Devourer character during combat to capture the actual cast ID.

---

## Files Changed

- `Core.lua` — version 1.4.3, changelog, Devourer rotationalSpells fix
- `Analytics.lua` — `addonVersion` field added to result struct
- `UI.lua` — version watermark added to Fight Complete frame, positioned clear of scrollbar

---

*Midnight Sensei — Combat performance coaching for all 13 classes*
*Created by Midnight - Thrall (US)*
