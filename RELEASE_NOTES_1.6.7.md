# MidnightSensei v1.6.7 — Release Notes

**Date:** May 12, 2026
**Type:** Bug Fix

---

## Overview

v1.6.7 fixes a silent tracking failure for Marksmanship Hunter players using the **Dark Ranger** hero talent. Players on this path cast Black Arrow instead of Kill Shot, but the addon continued to flag Kill Shot as "never used" in their fight feedback. This was caused by an incorrect value in the `suppressIfTalent` field — a talent node ID was used where a spell ID was required.

---

## Fix: Kill Shot No Longer Falsely Penalised on Dark Ranger MM Hunters

### What broke

The Kill Shot entry in the MM Hunter spec had `suppressIfTalent = 94987`. The intent was: if the player has the Dark Ranger talent, suppress Kill Shot from tracking (Black Arrow replaces it).

However, `94987` is the **talent node ID** for the Dark Ranger hero path — not a spell ID. Both suppress-check code paths (`IsTalentActive` in CastTracker.lua and `IsPlayerSpell` in the verify report) operate on spell IDs. A node ID passed to either function always returns false, so Kill Shot was never suppressed.

### What changed

`suppressIfTalent = 94987` was corrected to `suppressIfTalent = 466932` (Black Arrow's spell ID). MM Hunters with the Dark Ranger talent have Black Arrow in their spellbook — `IsPlayerSpell(466932)` returns true for them, and `IsTalentActive(466932)` also finds the node via the C_Traits walk. Kill Shot is now correctly excluded from tracking for these players.

### Black Arrow alt ID

Black Arrow (466932) also received `altIds = {466930}`. ID 466930 is an alternate cast event that fires in certain combat contexts; both IDs now credit the same rotational tracking slot, ensuring consistent detection regardless of which ID the game fires.

---

## Files Changed

- `Specs/Hunter.lua`
- `MidnightSensei.toc` (version bump)
- `Core.lua` (version + CHANGELOG)
