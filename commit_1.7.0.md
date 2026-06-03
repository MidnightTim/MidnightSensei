# Commit Notes — v1.7.0
**Date:** 06/02/2026  
**Author:** Midnight - Thrall (US)  
**Tag:** v1.7.0

## Summary

Adds Hard Mode scoring toggle with context menu slider and red header theme, fixes HUD boss label overflow, adds Sigil of Flame tracking for Vengeance DH, and removes the non-functional encounter adjustment toggle.

## Changed Files

- `MidnightSensei.toc` — version bump to 1.7.0
- `Core.lua` — version fallback to 1.7.0; Core.CHANGELOG entry; removed `encounterAdjust` default; added `hardMode` default
- `Analytics/Scoring.lua` — all five scoring components read `state.hardMode` and apply tighter thresholds when enabled
- `Analytics/Engine.lua` — `BuildState()` injects `hardMode = Core.GetSetting("hardMode") == true`
- `Specs/DemonHunter.lua` — Vengeance: Sigil of Flame (204596) added to validSpells + rotationalSpells
- `UI.lua` — Hard Mode context menu slider (texture-based, stays open on click); red header theme via `RefreshHardModeTheme()`; SETTINGS_CHANGED hook; boss label split to two lines + width constraint; `encounterAdjust` toggle removed; options panel offsets adjusted
- `Locales/enUS.lua` — OPT_SCORING, OPT_HARD_MODE, OPT_HARD_MODE_SUB keys added

## Commits

```
feat(scoring): add Hard Mode toggle with tighter per-component thresholds

feat(ui): Hard Mode context menu slider with texture-based left/right indicator

feat(ui): red title bar theme when Hard Mode is active; SETTINGS_CHANGED hook

fix(ui): boss name + grade label overflow HUD frame on long encounter names

feat(specs): Vengeance DH — Sigil of Flame (204596) added to rotation tracking

chore(options): remove non-functional encounterAdjust toggle
```
