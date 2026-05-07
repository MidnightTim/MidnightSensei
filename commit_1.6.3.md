# Commit Notes — v1.6.3

**Date:** 05/06/2026  
**Author:** Midnight - Thrall (US)  
**Tag:** v1.6.3

## Summary

Introduces the `hasCombatValue` flag for CC utility spells, fixing false penalties on Shockwave and Dragon's Breath. Adds 16 new tracked abilities across 6 specs from the May 2026 Archon audit review.

## Changed Files

| File | Description |
|---|---|
| `MidnightSensei.toc` | Version bump 1.6.2 → 1.6.3 |
| `Core.lua` | Version fallback string updated; CHANGELOG entry added |
| `Analytics/Feedback.lua` | `combatUtilityNeverUsed` list added; hasCombatValue routing |
| `Specs/Warrior.lua` | Shockwave reclassified (all specs); Storm Bolt hasCombatValue; Fury Storm Bolt added; Prot Piercing Howl added |
| `Specs/Mage.lua` | Dragon's Breath reclassified to isUtility + hasCombatValue |
| `Specs/DemonHunter.lua` | Chaos Nova hasCombatValue; Devourer Consume Magic added |
| `Specs/Druid.lua` | Force of Nature hasCombatValue |
| `Specs/Evoker.lua` | Devastation Time Spiral added; Augmentation Spatial Paradox added |
| `Specs/Paladin.lua` | Holy + Ret Hammer of Wrath added; Prot Sentinel added |
| `Specs/Priest.lua` | Disc: Leap of Faith, Fade, Desperate Prayer added; Holy: Leap of Faith added |
| `Specs/Rogue.lua` | Cloak of Shadows added all 3 specs; Outlaw Preparation added |

## Commits

```
feat(feedback): add hasCombatValue flag for CC utility spells with distinct coaching message

feat(specs): reclassify Shockwave (Warrior all specs) and Dragon's Breath (Frost Mage) from penalised CDs to isUtility + hasCombatValue

feat(specs): add hasCombatValue to Chaos Nova (DH Havoc/Vengeance) and Force of Nature (Balance Druid)

feat(specs): 16 new tracked abilities from May 2026 Archon audit — Consume Magic, Time Spiral, Spatial Paradox, Hammer of Wrath (Holy/Ret), Sentinel, Leap of Faith (Disc/Holy), Fade, Desperate Prayer, Cloak of Shadows (all Rogues), Preparation, Storm Bolt (Fury), Piercing Howl

chore: version bump 1.6.2 → 1.6.3
```
