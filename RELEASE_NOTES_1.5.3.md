# Midnight Sensei v1.5.3 Release Notes

## Overview

v1.5.3 delivers three Protection Warrior fixes and a cross-spec feedback infrastructure correction. All changes were driven by player-reported issues.

---

## Protection Warrior: Shield Block Pre-Pull No Longer Says "Never Activated"

Shield Block is a refresh-based ability — with enough haste, a single cast at pull keeps it active the entire fight through refreshes rather than re-applications. AuraTracker's pre-combat scan was detecting Shield Block as pre-existing and leaving its application count at 0 (the same code path used for group buffs like Arcane Intellect). Since refreshes do not fire a new APPLY event, the count stayed 0 all fight, and feedback incorrectly reported "Shield Block was never activated."

Fixed: non-group buffs (player's own mitigation) now receive credit for pre-pull application. The group-buff exception (infoOnly) is unchanged.

---

## Protection Warrior: Rend No Longer Penalised When Thunder Clap Is Talented

In Midnight 12.0, Thunder Clap (Spell ID 6343, Node ID 90343) automatically applies Rend to all targets on every cast. This is true in both Mountain Thane and Colossus hero specs — it is part of the Thunder Clap talent itself, not a hero spec passive.

The addon was tracking Rend as a separate rotational requirement and penalising warriors for never manually casting it. Fixed with `suppressIfTalent = 6343`: when Thunder Clap is talented, Rend tracking is suppressed entirely. Warriors who build without Thunder Clap (uncommon) will still have Rend tracked normally.

---

## Protection Warrior: Shield Wall Now Treated as a Reactive Cooldown

Shield Wall is used in response to predictable high-damage windows and tank busters. On a successful kill where no such window demanded it, not pressing Shield Wall is correct play. The addon was treating it like a throughput cooldown and penalising warriors who cleared a fight without needing it.

Shield Wall now uses the same `healerConditional` logic as reactive healer cooldowns:
- Unused on a successful fight → 90% scoring credit; no feedback warning
- Unused on a wipe → 0% scoring credit; "Never pressed" feedback fires
- Used → scored normally

---

## Feedback: healerConditional Warnings Fixed for All Specs

A pre-existing gap: the `healerConditional` flag correctly suppressed scoring penalties for unused reactive CDs on successful fights, but Feedback.lua was still generating "Never pressed" and "Used less than expected" coaching lines for those same CDs. Players would see a high score but contradictory coaching text.

Fixed: both feedback warnings are now suppressed for `healerConditional` cooldowns on successful fights, matching scoring behavior. This affects Protection Warrior (Shield Wall) and all healer specs with reactive CDs (Spirit Link Totem, Ascendance, Lay on Hands, Temporal Barrier, etc.).

---

## Files Changed

- `MidnightSensei.toc` — version bump to 1.5.3
- `Core.lua` — version bump, CHANGELOG
- `Combat/AuraTracker.lua` — pre-existing non-infoOnly buffs get appCount=1 at COMBAT_START
- `Specs/Warrior.lua` — Protection: Rend suppressIfTalent=6343; Shield Wall healerConditional=true
- `Analytics/Feedback.lua` — healerConditional CDs suppressed from neverUsed/underused on successful fights
