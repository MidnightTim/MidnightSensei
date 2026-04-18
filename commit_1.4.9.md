# Commit — Midnight Sensei v1.4.9

**Date:** April 2026  
**Author:** Midnight - Thrall (US)  
**Branch:** main  
**Tag:** v1.4.9

---

## Summary

v1.4.9 fixes two spec correctness bugs and ships Mage utility coaching. The Spell List passive prereq node issue (wrong-hero-tree spells appearing for Spellslinger Mages) is resolved by mirroring the CastTracker AND-gate fix into UI.lua. Four Shadow Priest rotational spells missing from tracking are added. Mage gets informational post-fight notes for Counterspell, Spellsteal, and Arcane Intellect, supported by two new spec flags (`isUtility`, `infoOnly`) and an AuraTracker initial scan for pre-combat buffs.

---

## Changed Files

- `MidnightSensei.toc` — version 1.4.9
- `UI.lua` — `isActive()` talentGated AND-gate fix; isUtility excluded from Cooldown Spells; isUtility included in Interrupt & Utility section
- `Specs/Mage.lua` — Counterspell (isInterrupt), Spellsteal (isUtility), Arcane Intellect (infoOnly uptimeBuff) on all 3 Mage specs
- `Specs/Priest.lua` — Shadow: Mind Flay, Shadow Word: Death, Void Blast, Void Volley added to rotationalSpells
- `Analytics/Feedback.lua` — isUtility feedback path; infoOnly uptime detection; utility note at fight end
- `Combat/AuraTracker.lua` — COMBAT_START initial scan for pre-existing buffs

---

## Commits

### chore: bump version to 1.4.9

### fix(ui): AND-gate IsPlayerSpell into isActive() talentGated check for Spell List
- `UiTalentCheck` alone returns true for passive prereq nodes in hero talent paths even when the player chose the other hero tree
- Added `AND IsPlayerSpell(entry.id)` to the talentGated branch in `isActive()`
- Mirrors the identical fix applied to CastTracker in v1.4.8
- Fixes: Frostfire Bolt appearing in Spell List for Spellslinger Frost Mage

### fix(specs/priest): add missing Shadow rotational spells — Mind Flay, SW:Death, Void Blast, Void Volley
- Mind Flay (15407) is baseline filler — no talentGated
- Shadow Word: Death (32379) is a class talent — talentGated = true
- Void Blast (450983) and Void Volley (1242173) are Voidweaver hero talent abilities — talentGated = true
- All four confirmed via live verify report (appeared in "Other Spells" with no PASS/FAIL)
- Priority notes updated with filler and Voidweaver rotation context

### feat(specs/mage): add utility feedback for Counterspell, Spellsteal, Arcane Intellect on all 3 specs
- Counterspell (2139): isInterrupt = true, minFightSeconds = 20 — interrupt coaching note if unused
- Spellsteal (30449): isUtility = true, minFightSeconds = 20 — utility note if unused
- Arcane Intellect (1459): infoOnly = true uptimeBuff — presence note if uptime < 5%
- None of these affect score — informational only

### feat(analytics/feedback): isUtility flag feedback path
- Added `utilityNeverUsed = {}` list alongside `interruptNeverUsed`
- `elseif cd.isUtility` branch in CD loop collects unused utility spells
- `not cd.isUtility` added to else-branch skip (same pattern as isInterrupt)
- infoOnly uptimeBuff check after DPS uptime block — fires utility note if uptime < 5% and duration >= 20s
- Utility note appended at fight end: "Note: X — not used or detected this fight. No penalty."

### feat(ui): isUtility entries in Interrupt & Utility section, excluded from Cooldown Spells
- hasCDs check and row loop now exclude `cd.isUtility` entries from Cooldown Spells section
- hasInterrupts check and row loop now include `cd.isUtility` entries in Interrupt & Utility section

### feat(combat/auratracker): initial scan at COMBAT_START for pre-existing buffs
- After auraData init, scans C_UnitAuras.GetPlayerAuraBySpellID for each uptimeBuff
- Buffs active at pull get isActive = true and lastApplied = combatStartTime so uptime accumulates from fight start
- appCount intentionally NOT incremented — Scoring.lua's appCount > 0 gate excludes pre-existing buffs from score
