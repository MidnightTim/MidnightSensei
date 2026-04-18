# Commit Notes — MidnightSensei v1.4.11

**Date:** 2026-04-18  
**Author:** Midnight - Thrall (US)  
**Tag:** v1.4.11

## Summary

Introduces kill/wipe distinction across the full analytics pipeline. Every boss fight is stamped with `isKill`; all personal bests, weekly averages, Boss Board, and leaderboard scores are gated on kills only. A one-time retroactive cleanup script runs on first login to correct legacy M+/Delve wipe data, with safe selective bossBests correction that preserves entries outside the history window. Includes a snapshot restore command for recovery.

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bump 1.4.10 → 1.4.11 |
| `Core.lua` | Fallback version bump; Core.CHANGELOG 1.4.11 entry; `/ms debug cleanup history`, `/ms debug cleanup history confirm`, `/ms debug bossboard restore` slash commands |
| `Analytics/Engine.lua` | `result.isKill` added: `true` for non-boss and kills, `false` for boss wipes |
| `Analytics/EncounterStore.lua` | `isKill` gates on all bests, weekScores/weeklyAvg, and bossBests in `SaveEncounter`; `RebuildBests()` utility function |
| `BossBoard.lua` | `IngestFromHistory` gated on `isKill ~= false`; `BB.CleanupHistory(dryRun)` with selective bossBests correction; SESSION_READY one-time auto-run; `BB.RestoreFromSnapshot()` recovery function |
| `UI.lua` | History rows: `[B]` replaced with `[K]` (green) / `[W]` (red); stats bar computes from kills only; wipe count suffix |

## Commits

```
feat(engine): add isKill to result struct — true for non-boss and kills, false for boss wipes

feat(store): gate all bests, weekScores, and bossBests on isKill in SaveEncounter

feat(store): add RebuildBests() — replays history kills-only to recompute all personal bests

fix(bossboard): gate IngestFromHistory on isKill ~= false

feat(bossboard): CleanupHistory(dryRun) — retroactive M+/Delve wipe detection, selective bossBests correction, SESSION_READY one-time auto-run

feat(bossboard): RestoreFromSnapshot() — recovers bossBests from account-wide shared snapshot

feat(ui): [K]/[W] kill-wipe indicators; kill-only stats; wipe count suffix in grade history

chore: version bump 1.4.10 → 1.4.11
```
