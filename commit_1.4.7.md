# Commit — Midnight Sensei v1.4.7

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Branch:** main
**Tag:** v1.4.7

---

## Summary

Internal structural release. Combat tracking code extracted from Analytics/Engine.lua into a dedicated Combat/ module group (six files). No scoring logic, spec data, or user-facing behavior changed. UNIT_AURA-based aura uptime and proc tracking now correctly implemented for the first time — previously the ProcessUnitAura dispatcher was called by Core but never defined.

---

## Changed Files

- `MidnightSensei.toc` — version 1.4.7, Combat/ group replaces root CombatLog.lua
- `Analytics/Engine.lua` — removed private combat state; reads all data via MS.CombatLog getters
- `Combat/CombatLog.lua` — new; namespace init, ProcessUnitAura dispatcher
- `Combat/CastTracker.lua` — new; spell cast/CD/rotational/GCD tracking
- `Combat/AuraTracker.lua` — new; buff uptime tracking via UNIT_AURA
- `Combat/ProcTracker.lua` — new; proc gain/consume cycle tracking via UNIT_AURA
- `Combat/ResourceTracker.lua` — new; edge-triggered overcap detection, MS_OVERCAP_DETECTED emit
- `Combat/HealingTracker.lua` — new; stub returning done=0 (CLEU restricted this build)

---

## Commits

### chore: bump version to 1.4.7

### refactor(combat): extract combat tracking into Combat/ module group
- CombatLog.lua, CastTracker.lua, AuraTracker.lua, ProcTracker.lua, ResourceTracker.lua, HealingTracker.lua
- MS.CombatLog namespace now populated by Combat/ trackers; Engine.lua reads via getters at fight end
- ProcessUnitAura dispatcher defined in Combat/CombatLog.lua; was previously called but never implemented
- COMBAT_END handlers in Combat/ run before Engine.lua (TOC order), guaranteeing finalized data when CalculateGrade reads it

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
