# Midnight Sensei v1.6.3 — Release Notes

**Date:** May 2026 | **Patch:** Midnight 12.0.5

---

## Combat Utility Coaching — hasCombatValue Flag

Some utility spells do more than just move or dispel — they stun, disorient, or root enemies while also dealing damage. Shockwave, Dragon's Breath, Chaos Nova, Storm Bolt, and Force of Nature all fall into this category. Previously these were tracked as generic utilities, giving the same "not used this fight, no penalty" note as a movement cooldown.

With the new `hasCombatValue` sub-flag, these spells now get a distinct coaching message: **"stuns and deals damage in addition to utility — use it where the situation allows; no penalty for holding it."** This communicates the spell's full value without penalising players who hold it for the right moment.

### Reclassifications that fix false penalties

- **Shockwave (all three Warrior specs)**: Was tracked as a regular penalised cooldown. In M+ it's correct to hold Shockwave for priority packs. Players who did so were receiving an unfair score hit. Now `isUtility + hasCombatValue` — tracked, never penalised.
- **Dragon's Breath (Frost Mage)**: Same issue — AoE disorient is held for groups or to interrupt, not spammed on CD. Reclassified to `isUtility + hasCombatValue`.

---

## 16 New Tracked Abilities — May 2026 Audit

A comprehensive Archon.gg audit pass reviewed all 40 specs and identified abilities present in high-adoption talent builds that were absent from the spec DB. After a two-pass false-positive review (88 initial findings → 43 genuine → 16 approved additions), the following abilities are now tracked:

**Demon Hunter — Devourer:** Consume Magic interrupt  
**Evoker — Devastation:** Time Spiral group utility  
**Evoker — Augmentation:** Spatial Paradox utility  
**Paladin — Holy + Retribution:** Hammer of Wrath (with Midnight 12.0 ID correction)  
**Paladin — Protection:** Sentinel defensive CD  
**Priest — Discipline:** Leap of Faith, Fade, Desperate Prayer  
**Priest — Holy:** Leap of Faith  
**Rogue — All three specs:** Cloak of Shadows  
**Rogue — Outlaw:** Preparation  
**Warrior — Fury:** Storm Bolt (stun + damage)  
**Warrior — Protection:** Piercing Howl (AoE slow)

All additions are `isUtility`, `isInterrupt`, or `healerConditional` — tracked and reported informatively, never penalised for situational holds.
