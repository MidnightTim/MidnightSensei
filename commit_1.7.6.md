# Commit Notes — v1.7.6

**Date:** 09/06/2026
**Author:** midnightstockton
**Branch:** main
**Tag:** v1.7.6

## Summary

Closes 9 cooldown-tracking gaps found across six classes (Warrior, Priest, Monk, Evoker, Druid, Rogue) — talents that were either never checked or incorrectly marked absent from their talent trees, so using them produced no cooldown-usage credit and sometimes false "never used" feedback. Three new mutually-exclusive choice-talent pairs were also wired up (Ravager/Bladestorm, Invoke Chi-Ji/Invoke Yu'lon, Convoke the Spirits/Incarnation for both Feral and Restoration).

## Changed Files

- `MidnightSensei.toc` — version bump 1.7.4 → 1.7.6
- `Core.lua` — `Core.VERSION` fallback bump; new v1.7.6 `Core.CHANGELOG` entry
- `Specs/Warrior.lua` — Bladestorm added to Arms (paired with Ravager); Ravager + Bladestorm added to Fury
- `Specs/Priest.lua` — Power Word: Barrier added to Discipline
- `Specs/Monk.lua` — Celestial Brew added to Brewmaster; Invoke Yu'lon added to Mistweaver (paired with Invoke Chi-Ji)
- `Specs/Evoker.lua` — Timelessness added to Augmentation
- `Specs/Druid.lua` — Incarnation: Avatar of Ashamane added to Feral (paired with Convoke, replaces Berserk); Incarnation: Tree of Life added to Restoration (paired with Convoke)
- `Specs/Rogue.lua` — Thistle Tea added to Outlaw and Subtlety (distinct spell ID from Assassination's)
- `ISSUE_warrior_bladestorm_ravager.md`, `ISSUE_priest_power_word_barrier.md`, `ISSUE_monk_celestial_brew.md`, `ISSUE_monk_invoke_yulon.md`, `ISSUE_evoker_timelessness.md`, `ISSUE_druid_feral_incarnation.md`, `ISSUE_druid_resto_incarnation.md`, `ISSUE_rogue_thistle_tea.md` — new issue files, one per fix
- `RELEASE_NOTES_1.7.6.md` — new release notes

## Commits

```
feat(warrior): track Bladestorm on Arms and Ravager+Bladestorm on Fury

fix(priest): track Power Word: Barrier on Discipline

fix(monk): track Celestial Brew on Brewmaster and Invoke Yu'lon on Mistweaver

feat(evoker): track Timelessness on Augmentation

fix(druid): track Incarnation: Avatar of Ashamane on Feral and Incarnation: Tree of Life on Restoration

fix(rogue): track Thistle Tea on Outlaw and Subtlety

chore: bump version to 1.7.6 and update changelog
```
