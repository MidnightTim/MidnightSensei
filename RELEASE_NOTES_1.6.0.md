# Midnight Sensei — v1.6.0 Release Notes

**Release Date:** May 2026
**Author:** Midnight - Thrall (US)

---

## Overview

Version 1.6.0 is the biggest spec-accuracy update since launch. Every class and spec — all 13 classes, all 39 specializations — has been fully reaudited against live **Archon.gg** Midnight 12.0 data. Rotation priorities, spell IDs, talent gating, passive/active classifications, and cooldown categories have all been cross-referenced against what top-ranked players are actually casting in Mythic+ and Raid.

This release resolves several long-standing tracking gaps where primary rotational spells were either missing entirely or miscategorised. The addon now reflects the actual Midnight 12.0 combat cast landscape with a high degree of confidence.

---

## Going Forward: Regular Audit Cadence

Starting with this release, Midnight Sensei will maintain a **regular audit cadence** tied to Archon.gg data. As Blizzard ships patches, talent changes, and tuning passes that shift rotation priorities or spell availability, the spec database will be updated to match.

**Between audits**, normal fixes will continue to be shipped as they are found — wrong spell IDs, missing tracking, scoring quirks, UI issues. You don't have to wait for an audit cycle to get a fix; if something is broken and we catch it, it goes out.

Regular audits provide the broader sweep: confirming that the full rotation picture is still accurate, that no new abilities have been added or removed, and that passive/active classifications haven't changed. Both types of updates will keep happening.

---

## What Changed

### Critical Tracking Gaps Resolved

Three primary rotational spells were missing entirely from the spec database — these were generating false activity penalties for players who were actually rotating correctly:

- **Havoc Demon Hunter — Chaos Strike**: The primary Fury spender was not tracked. Added with all four combat IDs (222031, 162794, 199547, and 201428 for the Metamorphosis/Annihilation variant).
- **Vengeance Demon Hunter — Soul Cleave**: The primary Pain spender was not tracked. Added with both combat IDs (228477, 228478).
- **Enhancement Shaman — Stormstrike**: The primary builder and damage ability was listed in priority notes but absent from the rotational spell list. Added with both combat IDs (32175, 17364).

### Warrior
- **Arms:** Die by the Sword added as a situational utility cooldown — tracked but never penalised.
- **Fury:** Whirlwind (both combat IDs) and Execute added to the rotational spell list. Both were missing despite being consistent filler casts in every Fury fight log.

### Shaman
- **Elemental:** Spiritwalker's Grace and Wind Rush Totem added as utility cooldowns. Both are talent-gated and situational — tracked, never penalised.
- **Restoration:** Earth Shield intentionally not tracked in uptime buffs — it is cast pre-pull before combat starts, which would generate false negatives for every fight. This is documented and will not be re-examined unless Blizzard changes when combat starts relative to Earth Shield casts.

### Hunter
- **Marksmanship:** Steady Shot (focus builder filler) and Multi-Shot (AoE/Trick Shots enabler) added to the rotational spell list.

### Monk
- **Mistweaver:** Mana Tea added as a major cooldown (mana recovery). Soothing Mist added to rotational — it auto-channels from Enveloping Mist and Vivify targets, and manual casts also fire `UNIT_SPELLCAST_SUCCEEDED`, so all cast paths are captured.
- **Windwalker:** Touch of Death added to major cooldowns — 3-minute CD, usable below 15% HP (Improved Touch of Death is a passive that expands the threshold; the ability itself is active and tracked).

### Evoker
- **Devastation & Preservation:** Zephyr added as a utility cooldown for both specs — talent-gated AoE damage reduction, tracked but never penalised.
- **Preservation:** Verdant Embrace added to rotational — 15-second CD instant heal with near-universal adoption.
- **Augmentation:** Bestow Weyrnstone added as a utility cooldown — transport tool, situational, never penalised.

### Paladin
- **Holy:** Blessing of Freedom added as a utility cooldown — movement freedom for an ally; situational, never penalised.
- **Protection:** Blessing of Sacrifice and Lay on Hands both added as healer-conditional cooldowns. These work like external tank CDs — full credit on a successful kill regardless of whether they were used; feedback on a wipe if they weren't pressed.
- **Retribution:** Hammer of Light added as a utility cooldown for Templar hero path — fires in the 20-second window opened by Wake of Ashes via the Light's Guidance talent. Wake of Ashes continues to be tracked as a major cooldown; both are in play for Templar players.

### Demon Hunter
- **Havoc:** Disrupt reclassified as an interrupt only — it was incorrectly listed as a major cooldown. Interrupts are tracked for display but never penalised in scoring.
- **Devourer:** Feast of Souls and all Devourer-specific passive abilities confirmed passive — not tracked.

---

## Passive Audit

A full passive/active classification audit was completed across all 39 specs. Over 60 abilities were confirmed as PASSIVE and explicitly excluded. The confirmed list is documented in `CLAUDE.md` under "Audit Notes — Confirmed Passives & Key Decisions (May 2026)" and will not be re-examined in future audits unless a patch changes the ability.

---

## Thank You

A genuine thank you to everyone who has played Midnight Sensei, reported bugs, flagged wrong scores, and sent feedback. The missing spell gaps fixed in this release — Chaos Strike, Soul Cleave, Stormstrike — were caught because players noticed their scores didn't add up and took the time to say something. That feedback is what makes the addon better.

Keep the reports coming. If a score feels wrong, or an ability you're casting isn't showing up, that is useful signal — not a minor complaint. Every report gets looked at.

See you in the next patch.

— Midnight, Thrall (US)

---

## Files Changed

- `MidnightSensei.toc` — version bumped to 1.6.0
- `Core.lua` — version fallback updated; 1.6.0 changelog entry added
- `Specs/Warrior.lua` — Arms, Fury updated
- `Specs/Shaman.lua` — Elemental, Enhancement, Restoration updated
- `Specs/Hunter.lua` — Marksmanship updated
- `Specs/Monk.lua` — Mistweaver, Windwalker updated
- `Specs/Evoker.lua` — Devastation, Preservation, Augmentation updated
- `Specs/Paladin.lua` — Holy, Protection, Retribution updated
- `Specs/DemonHunter.lua` — Havoc, Vengeance, Devourer updated
