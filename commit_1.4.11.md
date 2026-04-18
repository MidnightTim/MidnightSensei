# Commit Notes — MidnightSensei v1.4.11

**Date:** 2026-04-18  
**Author:** Midnight - Thrall (US)  
**Tag:** v1.4.11

## Summary

Introduces kill/wipe distinction across the full analytics pipeline. Every boss fight is now stamped with `isKill` at grade time; all personal bests, weekly averages, Boss Board, and leaderboard scores are gated on kills only. A one-time retroactive cleanup script runs on first login to correct legacy M+/Delve wipe data and rebuild bests from the corrected history.

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bump 1.4.10 → 1.4.11 |
| `Core.lua` | Fallback version bump 1.4.10 → 1.4.11; Core.CHANGELOG 1.4.11 entry; `/ms debug cleanup history` and `/ms debug cleanup history confirm` slash commands |
| `Analytics/Engine.lua` | `result.isKill` added: `true` for non-boss and kills, `false` for boss wipes (reuses `bossKillSuccess` from 1.4.10) |
| `Analytics/EncounterStore.lua` | `isKill` gates on all bests, weekScores/weeklyAvg, and bossBests in `SaveEncounter`; new `RebuildBests()` function |
| `BossBoard.lua` | `IngestFromHistory` gated on `isKill ~= false`; `BB.CleanupHistory(dryRun)` function; SESSION_READY one-time auto-run handler |
| `UI.lua` | History rows: `[B]` replaced with `[K]` (green) / `[W]` (red); stats bar computes from kills only; wipe count suffix added |

## Commits

```
feat(engine): add isKill to result struct — true for non-boss and kills, false for boss wipes

feat(store): gate all bests, weekScores, and bossBests on isKill in SaveEncounter

feat(store): add RebuildBests() — replays history kills-only to recompute all personal bests

fix(bossboard): gate IngestFromHistory on isKill ~= false; wipes excluded from bossBests

feat(bossboard): add CleanupHistory(dryRun) — retroactive M+/Delve wipe detection with 20-min window

feat(bossboard): SESSION_READY one-time auto-run for CleanupHistory per character

feat(ui): replace [B] tag with [K]/[W] kill-wipe indicators in fight history rows

feat(ui): grade history stats (avg/best/worst) computed from kills only; wipe count suffix shown

chore: version bump 1.4.10 → 1.4.11
```
