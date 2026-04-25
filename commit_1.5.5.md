# Commit Notes – MidnightSensei v1.5.5

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.5.5

## Summary

Complete rewrite of AuraTracker to use cast-event-based uptime windows instead of aura scanning. Midnight 12.0 blocks `aura.spellId` equality comparisons when addon code is tainted — all three fix attempts in v1.5.4 hit the same wall. Cast-based tracking requires no aura access.

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bump to 1.5.5 |
| `Core.lua` | Version 1.5.5; CHANGELOG; verify recorder and AURA CHECK updated for cast-based detection |
| `Combat/AuraTracker.lua` | Complete rewrite — aura scanning removed; ABILITY_USED listener + expiry ticker |
| `Specs/Warrior.lua` | Protection: Shield Block `castSpellId=2565, buffDuration=6`; Fury: Enrage `castSpellIds={23881,184367}, buffDuration=8` |
| `Specs/Paladin.lua` | Protection: SotR `castSpellId=53600, buffDuration=4.5` |
| `Specs/Druid.lua` | Guardian: Ironfur `castSpellId=192081, buffDuration=7` |
| `Specs/DemonHunter.lua` | Vengeance: Demon Spikes `castSpellId=203720, buffDuration=6` |
| `Specs/Evoker.lua` | Augmentation: Ebon Might `castSpellId=395152, buffDuration=10` |

## Commits

```
refactor(auratracker): replace aura scanning with cast-event-based uptime windows — aura.spellId comparison blocked by Midnight 12.0 taint
feat(auratracker): support castSpellIds list for multi-trigger buffs (Fury Enrage)
fix(warrior): Enrage tracked via Bloodthirst + Rampage castSpellIds; Shield Block castSpellId=2565 buffDuration=6
fix(paladin): SotR castSpellId=53600 buffDuration=4.5
fix(druid): Ironfur castSpellId=192081 buffDuration=7
fix(demonhunter): Demon Spikes castSpellId=203720 buffDuration=6
fix(evoker): Ebon Might castSpellId=395152 buffDuration=10
fix(verify): AURA CHECK uses VerifySeenSpells[castSpellId] for uptimeBuffs; procBuff scan removed
chore: v1.5.5 CHANGELOG
```
