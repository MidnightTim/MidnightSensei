# Midnight Sensei v1.4.6 — Verify Report SKIP, Weekly Reset (prev) Fix, Leaderboard Stability

## Overview

1.4.6 is a nightly polish release fixing three quality-of-life bugs surfaced during live testing. The verify report now correctly distinguishes spells you haven't talented (SKIP) from spells you have but never cast (FAIL). The leaderboard self-entry now shows (prev) on WK AVG after a weekly reset, matching how guild and friend entries already behaved. Two leaderboard messaging bugs — offline spam and a HELLO whisper loop — are also resolved.

---

## Verify Report — SKIP vs FAIL

### Problem
`/ms verify report` was showing FAIL for spells that aren't active in the current build — for example, The Hunt appearing as FAIL on a Devourer Demon Hunter who hasn't talented it, or Celestial Alignment failing on a Balance Druid running Incarnation.

### Fix
The report now emits three statuses:

| Status | Meaning |
|---|---|
| `PASS` | Spell was seen during combat |
| `SKIP` | Spell is not active in this build (untalented or suppressed) |
| `FAIL` | Spell is active but was never cast during the verify window |

`talentGated` spells are SKIP when `IsPlayerSpell` returns false. `suppressIfTalent` spells are SKIP when the suppressing talent is active. Only spells that should have been cast but weren't reach FAIL.

---

## Leaderboard — Self-Entry (prev) After Weekly Reset

### Problem
After the WoW weekly reset, the self-entry WK AVG column continued showing last week's score without the `(prev)` label. Guild and friend entries showed `(prev)` correctly; only Traum (you) did not.

### Root Cause
`GetWeekKey()` uses a 14-hour UTC shift + `date("!*t", ...)` to identify the current WoW week. Due to timezone edge cases, it can return the old week key for hours after the actual reset. Because Sunday and Monday fights were tagged with that same old key, the code saw `cb.weekKey == wk` and treated last week's scores as this week's data — blocking the `(prev)` flag permanently.

A secondary issue: the `cb.weekKey == wk` block ran unconditionally and merged `cb.weeklyAvg` into `selfEntry.weeklyAvg` before the "has this week fights?" check, making `hasThisWeek` appear true even with zero post-reset boss kills.

### Fix
Replaced `GetWeekKey()` for all self-entry week detection with `GetWeekStartEpoch()`:

```
weekStartEpoch = time() - ((time() - 482400) % 604800)
```

Unix epoch 0 is Thursday; Tuesday 14:00 UTC is 5 days + 14 hours later (482400 seconds). No `date()` call, no timezone assumptions. Boss kills are now counted using timestamp comparison against this epoch.

`hasThisWeek` is derived from the epoch-counted boss kill totals (`wCount`, `dungCount`, `raidCount`). The cb weekly data merge only runs when `hasThisWeek` is true. When no epoch-confirmed fights exist but `cb.weeklyAvg > 0`, a `prevWeek` flag is set and the display appends `(prev)` regardless of whether `GetWeekKey()` has flipped to the new week key yet.

---

## Leaderboard — Offline Spam Fixed

### Problem
On login, the addon whispered all online guild members to exchange scores. These whispers were staggered using `C_Timer.After`. If a guild member went offline during the stagger window, each queued whisper generated a "Player not found" / "not available" system message in chat — one per queued member.

### Fix
Each `C_Timer.After` callback now re-scans the guild roster immediately before sending. If the target member is no longer listed as online, the send is silently skipped.

---

## Leaderboard — HELLO Whisper Loop Fixed

### Problem
When two clients running MidnightSensei joined a group together, they would exchange HELLO addon whispers in an infinite loop — each HELLO triggered a HELLO reply, which triggered another HELLO reply, visible as repeated whisper spam between the two clients.

### Fix
Added a `helloWhisperReplied` session table. Each sender receives at most one HELLO reply per session regardless of how many HELLO messages they send.

---

## Debug Improvements

`/ms debug guild` now prints a full self-entry weekly avg diagnostic at the bottom:

- `GetWeekKey()` and `cb.weekKey` — confirms whether GetWeekKey has flipped
- `cb.weeklyAvg`, `cb.weekKey==wk` — identifies the stale-key scenario
- `selfEntry.weeklyAvg`, `dungeonAvg`, `prevWeek` — confirms the fix fired
- `(prev) would fire` — direct yes/no for display diagnosis

---

## Open VERIFY Items (carry forward)

| Item | Spec | Detail |
|---|---|---|
| Ascendance `114050` | Elemental Shaman | Shapeshift? VERIFY via `/ms verify` |
| Ascendance `114052` | Resto Shaman | Shapeshift? VERIFY via `/ms verify` |
| Voidform `228260` | Shadow Priest | VERIFY SUCCEEDED fires |
| Celestial Alignment `383410` | Balance | Orbital Strike variant — VERIFY runtime ID |
| Killing Machine `59052` | Frost DK | Talent shows `51128` |
| Rime `51124` | Frost DK | Spell list shows `59057` |
| Hot Streak `48108` | Fire Mage | Spell list shows `195283` |
| Brain Freeze `190446` | Frost Mage | Talent shows `190447` |
| Fingers of Frost `44544` | Frost Mage | Talent shows `112965` |

---

*Midnight Sensei — Combat performance coaching for all 13 classes*
*Created by Midnight - Thrall (US)*
