# Commit Record — v1.6.5

**Date:** May 10, 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.6.5

---

## Summary

Full localization pass: all UI strings moved to L["KEY"] references; German (deDE) and French (frFR) locale files added. DH Devourer interrupt corrected: Disrupt restored, Consume Magic reclassified to utility.

---

## Conventional Commits

```
feat(locales): add deDE and frFR locale files (~350 keys each)

feat(ui): replace all hardcoded English strings with L["KEY"] references

fix(specs): DH Devourer — restore Disrupt as interrupt, reclassify Consume Magic to isUtility

chore(toc): bump version to 1.6.5, add deDE + frFR to load order

chore(core): CHANGELOG entry for v1.6.5, version fallback bumped to 1.6.5
```

---

## Changed Files

| File | Type | Description |
|---|---|---|
| `UI.lua` | feat | All hardcoded strings replaced with L["KEY"] references |
| `Locales/deDE.lua` | feat | NEW — German locale, ~350 keys |
| `Locales/frFR.lua` | feat | NEW — French locale, ~350 keys |
| `Specs/DemonHunter.lua` | fix | Devourer: Disrupt restored as isInterrupt; Consume Magic → isUtility talentGated |
| `Core.lua` | chore | CHANGELOG v1.6.5 entry filled; version fallback = "1.6.5" |
| `MidnightSensei.toc` | chore | Version 1.6.5; deDE + frFR in load order |

---

## Issues Closed

- ISSUE_localization_v165.md — Full localization pass
- ISSUE_dh_devourer_interrupt_v165.md — DH Devourer interrupt fix
