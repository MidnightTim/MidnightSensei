# Midnight Sensei v1.4.7 — Combat Module Refactor

## Overview

1.4.7 is an internal structural release. The monolithic combat tracking code has been split out of `Analytics/Engine.lua` into a dedicated `Combat/` module group. No scoring logic, no feedback logic, no spec data, and no public API surfaces were changed. The grade you receive and all user-facing features are identical to 1.4.6.

---

## What Changed

### Combat/ Module Group (new)

The combat tracking code that previously lived in `Analytics/Engine.lua` has been extracted into six dedicated files:

| File | Responsibility |
|---|---|
| `Combat/CombatLog.lua` | Namespace init and UNIT_AURA dispatcher |
| `Combat/CastTracker.lua` | Spell cast tracking, CD usage, rotational counts, GCD activity |
| `Combat/AuraTracker.lua` | Buff/debuff uptime tracking |
| `Combat/ProcTracker.lua` | Proc gain/consume cycle tracking |
| `Combat/ResourceTracker.lua` | Resource overcap detection |
| `Combat/HealingTracker.lua` | Healing stub (CLEU unavailable this build) |

`Analytics/Engine.lua` now reads all combat data through getter functions (`GetCdTracking`, `GetRotationalTracking`, `GetTotalGCDs`, `GetActiveGCDs`, `GetOvercapEvents`, `GetAllUptimes`, `GetAllProcs`, `GetHealingData`) instead of owning private state.

### UNIT_AURA Tracking Now Implemented

Prior to this release, `MS.CombatLog.ProcessUnitAura` was called by Core but never defined — aura uptime and proc tracking were silently returning fallback values. AuraTracker and ProcTracker now correctly implement these, meaning `GetAllUptimes` and `GetAllProcs` return real combat data for the first time.

### Healer Efficiency — No Change

`COMBAT_LOG_EVENT_UNFILTERED` remains a restricted event in Midnight 12.0. `GetHealingData()` returns `{ done = 0, overheal = 0 }` as before. `ScoreHealerEfficiency` treats `done == 0` as "data unavailable" and excludes the metric from the weighted score rather than penalising.

---

*Midnight Sensei — Combat performance coaching for all 13 classes*
*Created by Midnight - Thrall (US)*
