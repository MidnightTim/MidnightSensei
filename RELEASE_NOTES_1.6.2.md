# Midnight Sensei v1.6.2 — Release Notes
**Date:** May 4, 2026 | **Patch:** WoW 12.0.5

---

## Overview

v1.6.2 is a spec database update — six new tracked abilities added across Warrior, Priest, and Death Knight, twelve alt ID corrections across seven specs to fix detection gaps, and the spec count corrected from 39 to 40 (Devourer confirmed as the third Demon Hunter specialization in Midnight 12.0).

---

## Spec DB — New Tracked Abilities

| Spec | Ability | ID | Tracking |
|---|---|---|---|
| Warrior — Arms, Fury, Protection | Rallying Cry | 97462 | `isUtility, talentGated` — party max HP utility; never penalised |
| Warrior — Fury | Enraged Regeneration | 184364 | `healerConditional, talentGated` — personal healing CD; 90% credit on kills |
| Warrior — Protection | Shockwave | 46968 | `talentGated` major CD — consistent with Arms and Fury placement |
| Priest — Discipline | Void Shield | 1205350 | Rotational — confirmed in spell list |
| Priest — Discipline | Shadow Word: Pain | 589 | Rotational — Atonement applicator |
| Death Knight — Blood | Gauntlet's Grasp | 109199 | `talentGated` CD — Rider of the Apocalypse hero talent |

---

## Alt ID Corrections — Improved Detection

These resolve cases where the game fires a different spell ID than expected under certain talents or hero paths. If you were seeing false "not detected" reports for any of these abilities, this release should fix it.

| Spec | Ability | Primary ID | Added Alt ID |
|---|---|---|---|
| Hunter — Marksmanship | Rapid Fire | 257044 | 257045 |
| Hunter — Survival | Kill Command | 259489 | 259277 |
| Hunter — Survival | Takedown | 1250646 | 1253859 |
| Hunter — Survival | Boomstick | 1261193 | 1261215 |
| Mage — Arcane | Arcane Barrage | 319836 | 44425 |
| Shaman — Elemental | Earthquake | 462620 | 61882, 61982 |
| Warlock — Destruction | Incinerate | 686 | 29722 |
| Evoker — Augmentation | Breath of Eons | 403631 | 442204 |
| Druid — Feral | Frantic Frenzy | 1243807 | 1244079 |
| Druid — Guardian | Maul / Raze | 6807 | 400254 |
| Death Knight — Frost | Killing Machine (proc buff) | 59052 | 51128 |
| Death Knight — Frost | Rime (proc buff) | 51124 | 59057 |

---

## Spec Count Corrected: 39 → 40

Devourer is confirmed as the third Demon Hunter specialization in Midnight 12.0. The spec count displayed in the addon UI has been corrected.
