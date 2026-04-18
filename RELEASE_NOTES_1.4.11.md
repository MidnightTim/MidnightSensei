# MidnightSensei v1.4.11 Release Notes

---

> **Data correction note:** After updating, your personal bests, leaderboard scores, and Boss Board entries will fully reflect kill-only data once you complete your next kill in each category (dungeon, delve, raid). The one-time cleanup script runs automatically on your first login and corrects legacy wipe data in your history — but bests are re-broadcast to guild and friends on your next eligible fight completion, not immediately on login.

---

## Overview

1.4.11 introduces kill/wipe distinction across the entire analytics pipeline. Previously, a boss wipe was scored and recorded identically to a kill — meaning a high-performance wipe could inflate your personal best, Boss Board entry, and leaderboard scores. This release stamps every fight with a kill/wipe outcome and gates all bests, averages, and the Boss Board on kills only. A retroactive cleanup script runs on first login to correct existing history within safe heuristic bounds.

---

## Kill/Wipe Tracking

**Problem:** The `result` struct had no `isKill` field. Both boss kills and wipes flowed through `SaveEncounter` and updated personal bests, `weekScores`, and `bossBests` identically. A wipe score could be your "all-time best" for a content type.

**Fix:** `result.isKill` is now set in `Engine.CalculateGrade()`:
- `true` for any non-boss fight (trash, dungeon runs, delve clears — surviving is the success condition)
- `true` for boss fights where `BOSS_END` fired with `success == 1`
- `false` for boss fights where `BOSS_END` fired with `success == 0` (wipe)

This reuses the same `bossKillSuccess` signal introduced in 1.4.10 for `healerConditional` scoring.

**Scope of gating:**
- `EncounterStore.SaveEncounter`: `allTimeBest`, `dungeonBest`, `raidBest`, `delveBest`, all weekly content bests, `weekScores`/`weeklyAvg`, and `bossBests` are now only updated on `isKill = true`
- `BossBoard.IngestFromHistory`: skips `isKill == false` encounters when seeding `bossBests`
- Legacy encounters without `isKill` set (`nil`) are treated as kills everywhere — old data is preserved as-is

---

## Grade History UI

The `[B]` boss tag in fight history rows has been replaced with outcome-coloured tags:
- `[K]` (green) — boss kill
- `[W]` (red) — boss wipe

The stats bar (Avg / Best / Worst) now computes from kill fights only. When wipes are present in the current filter view, a red "N wipes" suffix is shown so the total fight count still reflects reality.

---

## Legacy History Cleanup

Existing history recorded before 1.4.11 has no `isKill` field. A one-time cleanup script detects likely legacy wipes using a conservative heuristic and corrects them.

**Heuristic:** For M+ dungeon and Delve boss encounters where `isKill == nil`, grouped by boss + content tier: if the same boss appears again within 20 minutes, the earlier encounter is flagged as a wipe. Raids are excluded.

**Auto-run:** Fires once per character 5 seconds after login (`SESSION_READY`). Gated by `CharDB.cleanupHistoryDone` — never repeats. Prints a single summary line to chat.

**Manual commands:**
- `/ms debug cleanup history` — dry run; lists every encounter that would be flagged with a reason
- `/ms debug cleanup history confirm` — applies the fix, then calls `RebuildBests()` and `IngestFromHistory()` to rebuild leaderboard scores and Boss Board from corrected data

After the cleanup applies, bests are corrected locally. The updated scores are broadcast to guild and friends on your next boss kill.

---

## RebuildBests

New `EncounterStore.RebuildBests()` resets all personal bests to zero and replays every encounter in history (kills only) to recompute `allTimeBest`, all content bests, all weekly bests, and `weeklyAvg`. Called automatically by the cleanup confirm path. Available standalone for future use.
