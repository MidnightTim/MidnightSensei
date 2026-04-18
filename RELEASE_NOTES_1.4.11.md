# MidnightSensei v1.4.11 Release Notes

---

> **Note:** Personal bests, leaderboard scores, and Boss Board entries will fully reflect kill-only data after your next kill in each category (dungeon, delve, raid). The one-time cleanup script corrects legacy wipe data on first login, but corrected bests are re-broadcast to guild and friends on your next eligible fight completion — not immediately on login.

---

## Overview

1.4.11 introduces kill/wipe distinction across the full analytics pipeline. Previously, boss wipes were scored and recorded identically to kills — a high-performance wipe could inflate your personal best, Boss Board entry, or leaderboard score. This release stamps every boss fight with an outcome and gates all bests, averages, and the Boss Board on kills only. A retroactive cleanup script runs on first login to correct existing history within safe bounds.

---

## Kill/Wipe Tracking

`result.isKill` is now set in `Engine.CalculateGrade()`:
- `true` for any non-boss fight (surviving is the success condition)
- `true` for boss fights where `BOSS_END` fired with `success == 1`
- `false` for boss wipes

This reuses the `bossKillSuccess` signal introduced in 1.4.10 for `healerConditional` scoring.

All personal bests (`allTimeBest`, `dungeonBest`, `raidBest`, `delveBest`, weekly variants), `weekScores` / `weeklyAvg`, and `bossBests` in `SaveEncounter` are now gated on `isKill`. `BossBoard.IngestFromHistory` also skips `isKill == false` encounters. Legacy encounters without `isKill` set (`nil`) are treated as kills everywhere — existing data is preserved.

---

## Grade History UI

The `[B]` boss tag is replaced with outcome-coloured tags: `[K]` (green) for kills, `[W]` (red) for wipes. The stats bar (Avg / Best / Worst) now computes from kills only. A red wipe count suffix is shown when wipes are present in the current filter view.

---

## Legacy History Cleanup

A one-time cleanup script detects likely wipes in existing M+ and Delve history and corrects them.

**Heuristic:** For M+/Delve boss encounters where `isKill == nil` (pre-patch), grouped by boss + content tier: if the same boss appears again within 20 minutes, the earlier encounter is flagged as a wipe. Raids are excluded.

**Auto-run:** Fires once per character 5 seconds after login. Gated by `CharDB.cleanupHistoryDone` — never repeats. Prints a single summary line to chat.

**What the cleanup touches:**
- Fight history `isKill` stamps on identified wipe encounters
- `bossBests` — only entries for bosses where wipes were found. If a kill in history has a lower score than the current entry, the entry is corrected down to that kill score. If no kill is found in history for a boss, the entry is left completely untouched — the best may be from a fight outside the 200-encounter history window.
- `allTimeBest`, `dungeonBest`, `delveBest`, and similar are **not modified** — these cannot be safely rebuilt from a partial history window and will self-correct as new kills come in.

**Manual commands:**
- `/ms debug cleanup history` — dry run; lists every encounter that would be flagged with reason
- `/ms debug cleanup history confirm` — applies the fix

---

## Boss Board Snapshot Restore

If the previous version of the cleanup script wiped your Boss Board entries, run `/ms debug bossboard restore` to recover them. The account-wide shared snapshot (`MidnightSenseiDB.bossBoardShared`) is written 3 seconds before the cleanup fires and is never destructively cleared — it holds your pre-cleanup records. Restored entries recover score, grade, date, boss name, instance, and spec. Fight feedback and component scores are not stored in the snapshot and will not be restored.
