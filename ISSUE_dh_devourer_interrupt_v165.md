# Bug Fix: DH Devourer — Disrupt Restored as Primary Interrupt

**Version:** 1.6.5
**Date:** May 10, 2026
**Type:** Bug Fix / Spec DB Correction

## Summary

The Demon Hunter Devourer spec (spec index 3 in `DemonHunter.lua`) had an incorrect
interrupt entry. `Consume Magic` (spell ID 278326) was flagged `isInterrupt = true`,
which is wrong — it is a **purge**, not an interrupt. The real interrupt, `Disrupt`
(spell ID 183752), was absent from `majorCooldowns` entirely (it existed only in
`validSpells`).

This caused the addon to coach players on Consume Magic as if it were their primary
interrupt while completely ignoring Disrupt usage tracking.

## Root Cause

Introduced in v1.6.3 during the DH Devourer spec DB addition. The 1.6.3 audit listed
Consume Magic as `isInterrupt talentGated` — this was incorrect from the start.
Consume Magic dispels one beneficial magic effect from an enemy; it is situational
purge utility. Disrupt is the melee-range kick (2s GCD lockout, 15s CD).

## Fix

In `Specs/DemonHunter.lua`, Devourer `majorCooldowns`:

**Before:**
```lua
{ id = 278326, label = "Consume Magic", expectedUses = "situational", isInterrupt = true, talentGated = true },
```
(Disrupt was absent from majorCooldowns)

**After:**
```lua
{ id = 183752, label = "Disrupt",       expectedUses = "situational", isInterrupt = true },
{ id = 278326, label = "Consume Magic", expectedUses = "situational", isUtility = true, talentGated = true },
```

## Files Changed

- `Specs/DemonHunter.lua` — Devourer majorCooldowns corrected
- `Core.CHANGELOG` — 1.6.3 entry note added; 1.6.5 entry documents the fix
