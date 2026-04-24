# Midnight Sensei v1.5.2 Release Notes

## Overview

v1.5.2 delivers targeted bug fixes for Unholy Death Knight, Retribution Paladin, and all six tank specs. Every change was driven by player-reported issues.

---

## Unholy DK: Festering Strike Spell ID Corrected

Festering Strike was tracked as id=316239, which appears in the talent tree but never fires `UNIT_SPELLCAST_SUCCEEDED`. The actual cast ID is 85948. Updated to track 85948 as primary with 316239 retained as an altId in case the talent-modified variant fires under certain configurations.

---

## Retribution Paladin: Divine Storm No Longer Penalised in Single Target

Divine Storm (53385) was in `rotationalSpells`, causing the addon to penalise Ret Paladins for not using an AoE ability in single-target and open world content. Divine Storm is now classified as `isUtility` — it will be noted if used but never scored against you for skipping it.

---

## Retribution Paladin: Avenging Wrath + Radiant Glory

When Radiant Glory (458359) is talented, Avenging Wrath is no longer a player-cast spell — Wake of Ashes automatically triggers it. The addon was incorrectly penalising players for "never pressing Avenging Wrath" when it procs automatically. `suppressIfTalent = 458359` added to Avenging Wrath — it is excluded from scoring entirely when Radiant Glory is active.

---

## Tank Feedback: Spec-Specific Mitigation Ability Names

The low-mitigation-uptime coaching line previously said "Demon Spikes" for all tanks. It now references the correct primary active mitigation for each spec:

| Spec | Ability Referenced |
|---|---|
| Blood Death Knight | Death Strike |
| Vengeance Demon Hunter | Demon Spikes |
| Guardian Druid | Frenzied Regeneration |
| Brewmaster Monk | Ironskin Brew |
| Protection Warrior | Shield Block |
| Protection Paladin | Shield of the Righteous |

---

## Files Changed

- `MidnightSensei.toc` — version bump to 1.5.2
- `Core.lua` — version bump, CHANGELOG
- `Specs/DeathKnight.lua` — Unholy: Festering Strike id=85948, altIds={316239}
- `Specs/Paladin.lua` — Ret: Divine Storm isUtility; Avenging Wrath suppressIfTalent=458359
- `Analytics/Feedback.lua` — spec-aware mitigation ability lookup table
