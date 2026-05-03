# Midnight Sensei v1.6.1 — Release Notes
**Date:** May 3, 2026 | **Patch:** WoW 12.0.5

---

## Overview

v1.6.1 resolves five critical leaderboard sync bugs that were preventing cross-client score exchange, completes the Evoker spec database with four previously missing abilities confirmed via in-game tooltip inspection, and ships the redesigned update notification banner.

---

## Critical — Leaderboard Sync (5 Fixes)

### Delves Tab: Self-Entry Showed All-Time Best, Not Most Recent

The Delves tab "RECENT DELVE / BOSS" column showed the player's highest-scoring delve run for themselves, while other players' entries showed their most recent broadcast. This caused visible inconsistency (e.g. "Collegiate Calamity" for self while peers showed the correct "Shadow Enclave" from a run completed together).

**Root cause:** `LB.GetDelveData()` stored `lastEnc` only when a new best score was found. The display label (instance name, boss name) came from this best-scoring encounter.

**Fix:** The aggregation loop now tracks `bestEnc` (for score/grade ranking) and `mostRecentEnc` (for display labels) separately. Since encounter history is chronological, `mostRecentEnc` is unconditionally advanced on each entry. Self-entry now matches peer semantics: ranked by best score, labelled by most recent run.

---

### REQ Responses Only Broadcast One Content Type

When a player joined a group or reloaded, REQ responses only sent the single most recent encounter overall. Delve data would never cross if the most recent encounter was a dungeon boss, and vice versa.

**Root cause:** The REQ handler called `GetLastEncounter()` once and emitted a single `GRADE_CALCULATED`. The delve suppression check in `BroadcastScore` further blocked scores below the player's all-time best delve.

**Fix:** REQ and REQD handlers now loop over `{"delve", "dungeon", "raid"}`, call `GetLastEncounterByType(ctype)` per type, and broadcast each directly via `BuildScorePayload()` + `BroadcastToAll()` — bypassing delve suppression (which is correct for live-fight spam reduction, not for REQ responses). Broadcasts are staggered 0.6s apart to avoid flooding.

---

### GetLastEncounter() Blocked by Trash Pulls

Players with many open-world or trash-pull encounters at the top of their history (e.g. long-time testers) could not broadcast any score. The REQ handler received a `encType=normal` encounter and silently emitted nothing.

**Root cause:** `Analytics.GetLastEncounter()` returned the most recent entry unconditionally.

**Fix:** Added `IsEligibleEncounter(enc)` filter (boss OR dungeon/raid/delve). `GetLastEncounter()` now walks backwards past non-eligible entries. `GetLastEncounterByType(encType)` added as a new getter for per-type lookups.

---

### Group Join Never Requested Existing Members' Data

Joining a group where other members were already playing showed empty rows for all pre-existing members until those members finished a new fight.

**Root cause:** `GROUP_ROSTER_UPDATE` only pruned departed members. It never detected new members with missing `partyData`.

**Fix:** `GROUP_ROSTER_UPDATE` now checks all current group members against `partyData`. If any member lacks an entry, a REQ is sent after a 1.5s delay (to avoid firing during rapid roster churn at group formation).

---

### "Online — Updated" Chat Spam on Tab Switch

Every leaderboard tab switch could print "Polkatron (Online) — Updated" repeatedly in chat as background whisper syncs arrived.

**Root cause:** The whisper confirmation print fired for any SCORE message received via WHISPER channel, including background sync responses from `SyncGuildOnlineStatus`.

**Fix:** Print is now gated on `LB._pendingFriendQuery ~= nil`. Only fires for explicit `/ms friend <name>` queries. Background sync whispers are silently processed.

---

## Evoker — May 2026 Tooltip Pass

Four abilities confirmed in-game and added to all three specs (Devastation, Preservation, Augmentation):

| Ability | ID | Notes |
|---|---|---|
| Rescue | 370665 | `isUtility, talentGated` — 1 min CD; movement + cleanse |
| Cauterizing Flame | 374251 | `isUtility` — baseline dispel utility |
| Expunge | 365585 | `isUtility`, `altIds={360823}` — Naturalize replaces when talented |
| Stasis | 370537 | Major healer CD (Preservation only) — stores/releases 3 casts |

15 additional abilities confirmed PASSIVE and documented to prevent future regression.

---

## Update Notification Redesign

Version update alerts no longer print to chat. A persistent amber bar now appears above the HUD frame when a newer version is detected. Clicking it opens a details popup; the X button dismisses it for the session.

---

## Debug Tools

- `/ms debug encounters` — prints last 10 encounter history entries with `encType`, `isBoss`, grade, score, duration, and instance name; also shows the most recent encounter found per content type (delve/dungeon/raid). Critical for diagnosing broadcast and classification issues.
- `/ms debug broadcast` extended — now also shows non-eligible entries that were skipping broadcast.
