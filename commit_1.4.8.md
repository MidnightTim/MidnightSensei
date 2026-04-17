# Commit — Midnight Sensei v1.4.8

**Date:** April 2026  
**Author:** Midnight - Thrall (US)  
**Branch:** main  
**Tag:** v1.4.8

---

## Summary

Single bug fix: Feral Druid Frantic Frenzy builds receiving false "never used Feral Frenzy" feedback. Missing suppressIfTalent gate identical in cause to the Celestial Alignment / Incarnation fix shipped in v1.4.7. Full suppressIfTalent audit across all 39 specs confirmed no other gaps.

---

## Changed Files

- `MidnightSensei.toc` — version 1.4.8
- `Specs/Druid.lua` — Feral Frenzy suppressIfTalent gate added

---

## Commits

### chore: bump version to 1.4.8

### fix(specs/druid): suppress Feral Frenzy tracking when Frantic Frenzy is talented
- Frantic Frenzy (1243807) is a hero talent that replaces Feral Frenzy (274837)
- Both are prerequisite nodes — IsTalentActive strict walk returns true on both when Frantic Frenzy is taken
- Added suppressIfTalent = 1243807 to the Feral Frenzy entry; Frantic Frenzy has no suppression (it is the replacement)
- Same root cause as CA/Incarnation false feedback fixed in v1.4.7
- Full suppressIfTalent audit across all 13 classes confirmed no other gaps
