# Midnight Sensei v1.4.7 — Combat Module Refactor + Full Midnight 12.0 Spec Audit

## Overview

1.4.7 is a structural and spec-data release. The combat tracking code has been split into a dedicated `Combat/` module group. All 13 class spec files have been extracted from `Core.lua` into individual `Specs/` files and audited against full Midnight 12.0 talent tree snapshots — removing PASSIVE abilities that were incorrectly tracked, adding missing cooldowns and rotational spells, and correcting wrong spell IDs. Demon Hunter's Devourer spec received a full live-verification pass with all cast IDs confirmed via `/ms verify`.

---

## Structural Changes

### Combat/ Module Group (new)

Combat tracking code extracted from `Analytics/Engine.lua` into six dedicated files:

| File | Responsibility |
|---|---|
| `Combat/CombatLog.lua` | Namespace init and UNIT_AURA dispatcher |
| `Combat/CastTracker.lua` | Spell cast tracking, CD usage, rotational counts, GCD activity |
| `Combat/AuraTracker.lua` | Buff/debuff uptime tracking |
| `Combat/ProcTracker.lua` | Proc gain/consume cycle tracking |
| `Combat/ResourceTracker.lua` | Resource overcap detection |
| `Combat/HealingTracker.lua` | Healing stub (CLEU unavailable this build) |

`Analytics/Engine.lua` now reads all combat data through getter functions at fight end instead of owning private state.

### Specs/ Module Group (new)

All spec definitions extracted from `Core.lua` into individual files — one per class. `Core.lua` is no longer the home for spec data.

### UNIT_AURA Tracking Now Implemented

`MS.CombatLog.ProcessUnitAura` was called by Core but never defined — aura uptime and proc tracking silently returned fallback values in all prior releases. AuraTracker and ProcTracker now correctly implement these.

---

## Spec Audit — Midnight 12.0 PASSIVE Audit (All 13 Classes)

All specs were audited against full talent tree snapshots from v1.4.3. The primary sweep: PASSIVE-only talents that could never appear in `UNIT_SPELLCAST_SUCCEEDED` were removed from `validSpells`, `majorCooldowns`, and `rotationalSpells`. Missing cooldowns, rotational spells, and interrupt entries were added. Wrong spell IDs were corrected.

### Demon Hunter — Devourer (Live-Verified)

The Devourer spec received the most extensive changes. All cast IDs were confirmed live via `/ms verify`:

| Spell | Old ID | Correct ID | Note |
|---|---|---|---|
| Consume | `344859` | `473662` | snapshot ID was damage event ID, not cast ID |
| Reap | `344862` | `1226019` | same issue |
| Void Metamorphosis | `191427` | `1217605` | Havoc Meta ID; Devourer uses separate ID |
| Devour | — | `1217610` | not previously tracked; fired 6x in live test |
| Cull | — | `1245453` | not previously tracked; fired 5x in live test |

PASSIVE abilities removed: Impending Apocalypse (`1227707`), Demonsurge (`452402`), Midnight (`1250094`), Eradicate (`1226033`). `Void Metamorphosis` marked `displayOnly` — shapeshift fires `UPDATE_SHAPESHIFT_FORM` not `SUCCEEDED`.

### Demon Hunter — Havoc / Vengeance

Havoc: removed wrong IDs (`162794`, `344862`), added Sigil of Misery as interrupt, added Chaos Nova as talentGated CD.

Vengeance: removed Metamorphosis from majorCooldowns (shapeshift), removed wrong IDs (`344862`, `344859`), added Sigil of Silence and Sigil of Misery as interrupts, added Chaos Nova as talentGated CD.

### Death Knight — Blood

Blood DK's `rotationalSpells` was empty — Marrowrend, Heart Strike, Blood Boil, and Death Strike were all missing entirely. Added. Blood Shield removed from `uptimeBuffs` (proc absorb, not a persistent aura). Reaper's Mark added to `majorCooldowns`.

### Death Knight — Frost / Unholy

Frost: added Howling Blast and Frostscythe to rotational, Breath of Sindragosa and Reaper's Mark to `majorCooldowns`, Mind Freeze as interrupt.

Unholy: corrected Dark Transformation `63560` → `1233448`, corrected Festering Strike `85092` → `316239` (Unholy spec-variant), added Outbreak and Soul Reaper to `majorCooldowns`, added Putrefy to rotational, removed Apocalypse and Unholy Assault (not in tree).

### Warrior

Arms: removed Bladestorm and Warbreaker (not in Arms tree), added Ravager, Demolish, Shockwave as talentGated CDs, added Colossus Smash, Overpower, Rend to rotational.

Fury: removed Onslaught (not in tree), added Avatar, Odyn's Fury, Demolish to `majorCooldowns`, added Raging Blow, Berserker Stance, Rend to rotational.

Protection: removed Last Stand (PASSIVE INACTIVE in tree), added Demolish, Demoralizing Shout, Champion's Spear to `majorCooldowns`.

### Other Specs — Common Patterns

Across the remaining classes (Paladin, Priest, Monk, Druid, Shaman, Mage, Warlock, Rogue, Hunter, Evoker):

- PASSIVE talents removed from tracked sets across all specs where they appeared
- Missing cooldowns added: Power Infusion (Priest), Surging Totem (Shaman), Supernova (Mage), Zenith (Evoker), Time Skip (Evoker), Wither (Warlock)
- Spell ID corrections: Templar's Verdict `85256` → Final Verdict `383328` (Paladin), Tip the Scales `374348` → `370553` (Evoker), Dark Transformation (DK), Festering Strike (DK), Summon Vilefiend (Warlock)
- Interrupt entries added where missing

---

## Healer Efficiency — No Change

`COMBAT_LOG_EVENT_UNFILTERED` remains restricted in Midnight 12.0. `GetHealingData()` returns `{ done = 0, overheal = 0 }`. `ScoreHealerEfficiency` treats `done == 0` as "data unavailable" and excludes the metric from the weighted score.

---

*Midnight Sensei — Combat performance coaching for all 13 classes*
*Created by Midnight - Thrall (US)*
