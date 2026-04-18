# Commit Notes — MidnightSensei v1.4.10

**Date:** 2026-04-18  
**Author:** Midnight - Thrall (US)  
**Tag:** v1.4.10

## Summary

Introduces the `healerConditional` scoring flag, which awards 90% credit for fight-reactive healer CDs left unused on successful fights. Applies the flag across all 7 healer specs. Also corrects Fire Mage Fireball ID, removes punitive Scorch tracking, resolves the Frost Mage id=228597 passive mystery, adds Farseer hero path CDs to Elemental Shaman, and fills two missing Resto Shaman filler spells.

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bump 1.4.9 → 1.4.10 |
| `Core.lua` | Fallback version bump 1.4.5 → 1.4.10 |
| `Analytics/Engine.lua` | Track `bossKillSuccess` from BOSS_END; pass `state.fightSuccess` in BuildState |
| `Analytics/Scoring.lua` | healerConditional 90% credit branch in ScoreCooldownUsage |
| `Specs/Mage.lua` | Fire: Fireball 116→133, Scorch removed, Hot Streak comment updated. Frost: id=228597 passive confirmed |
| `Specs/Shaman.lua` | Elemental: Earth Elemental + Ancestral Swiftness added, priorityNotes updated. Resto: Healing Wave + Healing Stream Totem added, Surging Totem talentGated fixed, healerConditional on Spirit Link/Surging/Ascendance |
| `Specs/Priest.lua` | Disc: Pain Suppression healerConditional. Holy: Divine Hymn, Apotheosis, Guardian Spirit healerConditional |
| `Specs/Monk.lua` | Mistweaver: Revival, Life Cocoon, Invoke Chi-Ji healerConditional |
| `Specs/Paladin.lua` | Holy: Aura Mastery, Guardian of Anc. Kings, Lay on Hands, Blessing of Sacrifice healerConditional |
| `Specs/Evoker.lua` | Preservation: Rewind, Time Dilation healerConditional |
| `Specs/Druid.lua` | Resto: Tranquility, Ironbark, Nature's Swiftness, Innervate, Convoke healerConditional |

## Commits

```
feat(scoring): add healerConditional flag — 90% credit for reactive CDs on successful fights

feat(engine): track bossKillSuccess from BOSS_END; expose state.fightSuccess to Scoring

fix(specs/mage): Fire Mage Fireball ID corrected 116→133 (live-verified x10); Scorch removed

fix(specs/mage): Frost Mage id=228597 confirmed passive Glacial Spike Icicle cast; do not track

feat(specs/shaman): Elemental — Earth Elemental (198103) + Ancestral Swiftness (443454) Farseer CDs

fix(specs/shaman): Resto — Healing Wave (77472) + Healing Stream Totem (5394) added; Surging Totem talentGated

feat(specs): apply healerConditional to all 7 healer specs (Priest, Monk, Paladin, Evoker, Druid, Shaman)

chore: version bump 1.4.9 → 1.4.10
```
