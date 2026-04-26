# Commit Notes — v1.5.6

**Date:** April 26, 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.5.6

## Summary

Fixes a verify report crash caused by `IsTalentActive` being called outside its scope, corrects Balance Druid Wrath tracking by adding the Eclipse combat cast ID (190984) as an altId, resolves a scoring/feedback mismatch where `isInterrupt` and `isUtility` cooldowns were silently penalised despite being documented as exempt, and ships the debug tools overhaul (Fix Character Name, Clear Boss Board, updated Clear Fight History with MigrateEncounters re-populate fix).

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bump 1.5.5 → 1.5.6 |
| `Core.lua` | Version bump + CHANGELOG entry for 1.5.6; verify report suppressIfTalent check: `IsTalentActive` (nil in scope) → `IsPlayerSpell` |
| `Specs/Druid.lua` | Balance: Wrath `altIds={190984}`; Force of Nature `isUtility=true`; Solar Beam added as `isInterrupt=true, talentGated=true` |
| `Analytics/Scoring.lua` | `ScoreCooldownUsage`: `isUtility` and `isInterrupt` entries excluded from weight |
| `BossBoard.lua` | `BB.FixCharName()`, `NameExistsInData()`, `ApplyCharNameFix()` added |
| `UI.lua` | `MakeDestructiveDialog()`, `AddDestructiveBtn()` helpers; Clear Boss Board button; Clear Fight History updated (Confirm gate + MigrateEncounters fix + HUD refresh); Fix Character Name button in Recovery section |
| `README.md` | Midnight 12.0 restrictions section updated; Recent highlights updated; `/ms debug fixname` added to slash commands |

## Commits

```
fix(verify): IsTalentActive not in scope in Core.lua verify report handler — use IsPlayerSpell
fix(balance): Wrath alt ID 190984 — Eclipse:Wrath fires different cast ID in Midnight 12.0
feat(balance): Solar Beam (78675) added as isInterrupt talentGated
feat(balance): Force of Nature marked isUtility — tracked but not scored
fix(scoring): isUtility/isInterrupt CD entries excluded from ScoreCooldownUsage weight
feat(debug): Fix Character Name — dialog, validation, full charName repair across all stored data
feat(debug): Clear Boss Board added to Debug Tools Recovery with Confirm gate
fix(debug): Clear Fight History — Confirm gate + MigrateEncounters re-populate fix + HUD refresh
feat(ui): MakeDestructiveDialog and AddDestructiveBtn helpers
chore: version bump 1.5.5 → 1.5.6
```
