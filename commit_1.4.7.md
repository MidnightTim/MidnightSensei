# Commit — Midnight Sensei v1.4.7

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Branch:** main
**Tag:** v1.4.7

---

## Summary

Structural and spec-data release. Combat tracking extracted from Analytics/Engine.lua into Combat/ module group. All 13 class specs extracted from Core.lua into individual Specs/ files and audited against Midnight 12.0 talent tree snapshots — PASSIVE abilities removed, missing CDs and rotational spells added, wrong spell IDs corrected. Demon Hunter Devourer spec fully live-verified via /ms verify with corrected cast IDs. UNIT_AURA tracking (aura uptime and procs) now implemented for the first time.

---

## Changed Files

- `MidnightSensei.toc` — version 1.4.7, Combat/ and Specs/ groups added
- `Core.lua` — spec definitions removed; now calls Core.RegisterSpec() from Specs/*.lua
- `Analytics/Engine.lua` — removed private combat state; reads all data via MS.CombatLog getters
- `Combat/CombatLog.lua` — new; namespace init, ProcessUnitAura dispatcher
- `Combat/CastTracker.lua` — new; spell cast/CD/rotational/GCD tracking
- `Combat/AuraTracker.lua` — new; buff uptime tracking via UNIT_AURA
- `Combat/ProcTracker.lua` — new; proc gain/consume cycle tracking via UNIT_AURA
- `Combat/ResourceTracker.lua` — new; edge-triggered overcap detection, MS_OVERCAP_DETECTED emit
- `Combat/HealingTracker.lua` — new; stub returning done=0 (CLEU restricted this build)
- `Specs/DemonHunter.lua` — new; Devourer live-verified, Havoc/Vengeance audited
- `Specs/DeathKnight.lua` — new; Blood rotational spells added from scratch, Frost/Unholy IDs corrected
- `Specs/Warrior.lua` — new; Arms/Fury/Prot PASSIVE audit, missing CDs and rotational spells added
- `Specs/Monk.lua` — new; PASSIVE audit
- `Specs/Paladin.lua` — new; Final Verdict ID corrected, PASSIVE audit
- `Specs/Priest.lua` — new; Power Infusion added to majorCooldowns, PASSIVE audit
- `Specs/Druid.lua` — new; PASSIVE audit
- `Specs/Shaman.lua` — new; Surging Totem added, PASSIVE audit
- `Specs/Mage.lua` — new; Supernova added, PASSIVE audit
- `Specs/Warlock.lua` — new; Wither and Summon Vilefiend ID corrected, PASSIVE audit
- `Specs/Rogue.lua` — new; PASSIVE audit
- `Specs/Hunter.lua` — new; PASSIVE audit
- `Specs/Evoker.lua` — new; Zenith, Time Skip, Time Dilation added, Tip the Scales ID corrected

---

## Commits

### chore: bump version to 1.4.7

### refactor(combat): extract combat tracking into Combat/ module group
- CombatLog.lua, CastTracker.lua, AuraTracker.lua, ProcTracker.lua, ResourceTracker.lua, HealingTracker.lua
- MS.CombatLog namespace now populated by Combat/ trackers; Engine.lua reads via getters at fight end
- ProcessUnitAura dispatcher defined in Combat/CombatLog.lua; was previously called but never implemented
- COMBAT_END handlers in Combat/ run before Engine.lua (TOC order), guaranteeing finalized data when CalculateGrade reads it

### refactor(specs): extract all spec definitions from Core.lua into Specs/*.lua
- One file per class; Core.lua now calls Core.RegisterSpec() from each Specs/ file at load time
- No spec data changed as part of extraction — content changes are in separate audit commits below

### fix(combat): implement UNIT_AURA aura uptime and proc tracking
- AuraTracker.lua: GetAllUptimes(duration) now returns real uptime percentages from UNIT_AURA events
- ProcTracker.lua: GetAllProcs() now returns real gain counts and totalActiveTime from UNIT_AURA events
- Both silently returned fallback/nil values in all prior releases (ProcessUnitAura was unimplemented)

### refactor(engine): remove private combat state from Analytics/Engine.lua
- Removed cdTracking, rotationalTracking, overcapState, overcapEvents, totalGCDs, activeGCDs locals
- Removed IsTalentActive helper, CD/rotational setup loops, ABILITY_USED handler, SESSION_READY overcap tick
- BuildState() now reads all data from MS.CombatLog getters
- MS_OVERCAP_DETECTED event received from ResourceTracker; feedbackQueue remains private to Engine

### fix(healing): remove CLEU RegisterEvent from HealingTracker — restricted in Midnight 12.0
- COMBAT_LOG_EVENT_UNFILTERED is a restricted event; RegisterEvent triggers ADDON_ACTION_FORBIDDEN
- HealingTracker is now a stub: GetHealingData() returns { done=0, overheal=0 }
- ScoreHealerEfficiency already treats done==0 as "data unavailable" and returns nil (excluded from score)

### fix(specs): Midnight 12.0 PASSIVE audit — all 13 classes
- Removed PASSIVE-only talents from validSpells, majorCooldowns, and rotationalSpells across all specs
- These abilities can never appear in UNIT_SPELLCAST_SUCCEEDED and were silently inflating miss rates
- Added missing cooldowns and rotational spells identified during talent tree snapshot review

### fix(specs/dh): Devourer — live-verify all cast IDs via /ms verify
- Consume: 344859 → 473662 (snapshot used damage event ID, not cast ID)
- Reap: 344862 → 1226019 (same issue)
- Void Metamorphosis: 191427 → 1217605 (Havoc Meta ID; Devourer uses separate ID)
- Devour 1217610 and Cull 1245453 added — untracked previously, each fired in live test
- Void Metamorphosis marked displayOnly — shapeshift fires UPDATE_SHAPESHIFT_FORM not SUCCEEDED

### fix(specs/dk): Blood rotationalSpells was empty — core spells missing entirely
- Marrowrend, Heart Strike, Blood Boil, Death Strike added to Blood rotationalSpells
- Blood Shield removed from uptimeBuffs (proc absorb, not a persistent aura)
- Frost: Howling Blast, Frostscythe added to rotational; Breath of Sindragosa added to majorCooldowns
- Unholy: Dark Transformation 63560 → 1233448; Festering Strike 85092 → 316239 (spec-variant)

### fix(specs): notable spell ID corrections across classes
- Paladin: Templar's Verdict 85256 → Final Verdict 383328
- Evoker: Tip the Scales 374348 → 370553
- Warlock: Summon Vilefiend confirmed as 1251778
