# Commit Notes – MidnightSensei v1.5.3

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.5.3

## Summary

Three Protection Warrior fixes — Shield Block pre-pull tracking, Rend auto-apply via Thunder Clap, and Shield Wall reactive CD classification — plus a cross-spec fix for healerConditional CDs incorrectly showing warning text on successful fights despite receiving full scoring credit.

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bump to 1.5.3 |
| `Core.lua` | Version 1.5.3; CHANGELOG |
| `Combat/AuraTracker.lua` | Pre-existing non-infoOnly buffs set appCount=1 at COMBAT_START |
| `Specs/Warrior.lua` | Protection: Rend suppressIfTalent=6343; Shield Wall healerConditional=true |
| `Analytics/Feedback.lua` | healerConditional CDs suppressed from neverUsed/underused on successful fights |

## Commits

```
fix(warrior): Shield Block pre-pull credits appCount=1 — pre-cast no longer reports 'never activated'
fix(warrior): Prot Rend suppressIfTalent=6343 — Thunder Clap auto-applies Rend when talented
fix(warrior): Shield Wall healerConditional=true — unused on a kill no longer penalised
fix(feedback): healerConditional CDs suppressed from neverUsed/underused text on successful fights
chore: v1.5.3 CHANGELOG
```
