# Commit Notes — v1.6.0

**Date:** May 2, 2026
**Author:** Midnight - Thrall (US)
**Branch:** main
**Tag:** v1.6.0

## Summary

Full reaudit of all 13 classes (39 specs) against Archon.gg Midnight 12.0 live parse data. Three primary rotational spells were missing from the spec database and have been added. Approximately 15 additional spells were added or reclassified across seven classes. Over 60 abilities confirmed passive and documented to prevent regression. Version bumped to 1.6.0 to reflect the scope of the database overhaul.

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bumped 1.5.9 → 1.6.0 |
| `Core.lua` | VERSION fallback updated; 1.6.0 changelog entry added |
| `Specs/Warrior.lua` | Arms: Die by the Sword added; Fury: Whirlwind + Execute added |
| `Specs/Shaman.lua` | Elemental: Spiritwalker's Grace + Wind Rush Totem added; Enhancement: Stormstrike added |
| `Specs/Hunter.lua` | Marksmanship: Steady Shot + Multi-Shot added |
| `Specs/Monk.lua` | Mistweaver: Mana Tea + Soothing Mist added; Windwalker: Touch of Death added |
| `Specs/Evoker.lua` | Devastation + Preservation: Zephyr added; Preservation: Verdant Embrace added; Augmentation: Bestow Weyrnstone added |
| `Specs/Paladin.lua` | Holy: Blessing of Freedom added; Protection: Blessing of Sacrifice + Lay on Hands added; Retribution: Hammer of Light added |
| `Specs/DemonHunter.lua` | Havoc: Chaos Strike added, Disrupt reclassified; Vengeance: Soul Cleave added |

## Commits

```
feat(specs): full Archon.gg audit — all 13 classes reaudited for Midnight 12.0

Reaudit covers all 39 specs against Archon.gg talent/rotation data.
Passive/active classifications confirmed via in-game tooltips.
UNIT_SPELLCAST_SUCCEEDED tracking confirmed for all new active entries.

fix(havoc): add Chaos Strike (222031 + altIds 162794, 199547, 201428) to rotational
fix(havoc): reclassify Disrupt (183752) as isInterrupt, remove from majorCooldowns
fix(vengeance): add Soul Cleave (228477 + altId 228478) to rotational
fix(enhancement): add Stormstrike (32175 + altId 17364) to rotational
feat(warrior): Arms — Die by the Sword isUtility; Fury — Whirlwind + Execute added
feat(shaman): Elemental — Spiritwalker's Grace + Wind Rush Totem as isUtility
feat(hunter): Marksmanship — Steady Shot + Multi-Shot added to rotational
feat(monk): Mistweaver — Mana Tea + Soothing Mist; Windwalker — Touch of Death
feat(evoker): Zephyr for Devastation + Preservation; Verdant Embrace; Bestow Weyrnstone
feat(paladin): Holy — Blessing of Freedom; Prot — Blessing of Sacrifice + Lay on Hands; Ret — Hammer of Light
chore: bump version 1.5.9 → 1.6.0; update CHANGELOG
```
