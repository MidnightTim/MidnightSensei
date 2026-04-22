# Commit Notes – MidnightSensei v1.5.0

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.5.0

## Summary

Weekly reset notification, Devourer Soul Immolation spec fix, Verify HUD bar and debug window controls, verify report flag annotations, and removal of three obsolete debug tools. Verify auto-enable on login option added.

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bump to 1.5.0 |
| `Core.lua` | Weekly reset detection (`GetWeekBucket`, `CheckWeeklyReset`); `verifyAutoEnable` setting; auto-enable verify on `PLAYER_LOGIN`; removed `debuglog`, `debug self`, `debug zone` handlers; removed `debugLog` SavedVariable; CHANGELOG entry |
| `UI.lua` | Debug window: Verify Tools section (toggle, report button, auto-enable row); verify HUD bar anchored below main frame; `UI.UpdateVerifyBar()`; `UI.ToggleVerifyExport()` |
| `Specs/DemonHunter.lua` | Devourer: Soul Immolation moved from `majorCooldowns` (suppressIfTalent=258920) to `rotationalSpells` (talentGated=true) |

## Commits

```
feat(core): weekly reset notification — Tuesday bucket detection, announces once per character per week
fix(devourer): Soul Immolation to rotationalSpells — Spontaneous Immolation redesigned to buff not replace
feat(verify): debug window Verify Tools section, auto-enable on login setting
feat(verify): HUD verify bar with View Report toggle
feat(verify): report flag annotations (talentGated, suppress, interrupt, etc.)
chore: remove vestigial debug tools (debug self, debug zone, debuglog)
chore: v1.5.0 CHANGELOG
```
