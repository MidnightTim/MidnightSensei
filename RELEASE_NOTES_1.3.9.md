# Midnight Sensei v1.3.9 — Boss Board, Snapshot System & Debug Overhaul

## Summary

1.3.9 introduces the Boss Board — a personal all-time boss best leaderboard tracking your highest score per boss encounter across Dungeons, Raids, and Delves. A persistent spell and talent snapshot system is added for contributor tooling, replacing live API enumeration with reliable per-login stored data. The debug window is reorganised with distinct sections, the X button rendering bug is fixed, and the All Characters history filter is removed as it was silently broken since the schema v3 split.

---

## Boss Board

A new personal leaderboard tracking your all-time best score per boss encounter, accessible via `/ms bossboard`, `/ms bb`, the HUD right-click context menu, or Ctrl+Right-click on the minimap.

### Tabs
Three content tabs: **Dungeons** | **Raids** | **Delves**

### Columns
| Column | Notes |
|---|---|
| DATE | MM/DD/YYYY format — date the best score was achieved |
| CHARACTER | Class-coloured character name |
| SPEC | Specialisation at time of best |
| DIFF / BOSS | Difficulty + instance + boss name |
| SCORE | Grade letter and numeric score, colour-coded |

All five columns are sortable. Clicking the active sort column toggles ascending/descending direction.

### Data
- Keyed by `bossID` (Blizzard's `ENCOUNTER_START` encounter ID) — one row per unique boss
- Stores all-time best only — score only updates when a new best is achieved
- `bossBests` entries now include `charName`, `specName`, `className`, and `keystoneLevel` — fields that were previously missing

### Shared Snapshot
`MidnightSenseiDB.bossBoardShared` stores a copy of all personal bests account-wide, keyed by `"Name-Realm|bossID"`. Always keeps the higher score. Updated at login (3s delay) and after every boss fight. Intended for recovery and future guild/friend comparison features.

### Debug Ingest
`/ms debug bossboard ingest` (also accessible via the Debug Tools window) scans `CharDB.encounters` and seeds `bossBests` from existing history. Prints added/updated/skipped counts on completion.

**Ingest identity resolution for legacy encounters:**
Encounters recorded before `charName`/`specName`/`className` were added to the result struct will now fall back to the current character and active spec rather than storing `"?"`. Skipped entries (score not better) are also patched if their stored identity is `"?"`. Running ingest a second time after upgrading will repair previously stored `"?"` values.

### Access
| Method | Action |
|---|---|
| `/ms bossboard` or `/ms bb` | Toggle Boss Board |
| Right-click HUD | Boss Board between Leaderboard and Options |
| Ctrl+Right-click minimap | Toggle Boss Board |
| Debug Tools window | Boss Board Ingest under Recovery Tools |

---

## Spell & Talent Snapshot System

A persistent snapshot system captures the player's full spellbook and active talent tree automatically on login and whenever spells or talents change. Both snapshots are stored in `CharDB` so export tools read from reliable persisted data rather than making live API calls.

### Triggers
| Event | Action | Delay |
|---|---|---|
| `SESSION_READY` | Build both snapshots | 2s |
| `SPELLS_CHANGED` | Rebuild spell snapshot | 1s debounced |
| `PLAYER_TALENT_UPDATE` / `PLAYER_SPECIALIZATION_CHANGED` | Rebuild both | 1s debounced |

### Storage
**`CharDB.spellSnapshot`** — `{ timestamp, specName, className, spells[] }` where each spell has `spellID`, `name`, `subName`. Enumerated via `C_SpellBook.GetSpellBookItemInfo`. Sorted by spellID.

**`CharDB.talentSnapshot`** — `{ timestamp, specName, className, talents[] }` where each talent has `spellID`, `nodeID`, `name`, `rank`. Enumerated via `C_Traits` tree walk. Sorted by nodeID.

Both include the spec they were captured under and a timestamp.

### Export
Both export tools open the same copy-paste window used by `/ms verify report`. If no snapshot exists yet, the command directs to `/reload`. Output format matches the uploaded Midnight 12.0 spell list and talent tree files for direct diff comparison.

---

## Debug Tools Window

### X Button Fix
The close button rendered as a box (□) due to `✕` (U+2715) being outside FRIZQT__.TTF's basic Latin coverage. Replaced with plain `"X"`.

### Section Reorganisation

**General** (no label):
- Self — Delve History
- Zone / Instance
- Version
- Rotational Spells
- Debug Log

**Class Debugging** (cyan separator) — contributor tooling:
- Talent Export
- Spells Export

**Recovery Tools** (orange separator) — operational recovery:
- Boss Board Ingest *(new)*
- Backfill M+ Keys
- Clean Payload

A reusable `AddSectionLabel(text, color)` helper handles section separators.

---

## HUD Context Menu

"Boss Board" added between Leaderboard and Options. Frame height adjusted to accommodate the additional item.

---

## Minimap Button

Ctrl+Right-click opens the Boss Board. Tooltip updated:

```
Left-click:          Toggle HUD
Right-click:         Leaderboard
Ctrl+Right-click:    Boss Board
Shift+Right-click:   Options
```

---

## Grade History

The **All Characters** filter tab is removed. Since the schema v3 migration in 1.3.2, encounters are stored in `SavedVariablesPerCharacter` — a separate DB per character only loaded for the current character. The filter was silently identical to "This Character" and has been removed rather than repaired, as reverting to account-wide encounter storage would reintroduce the cross-character data bleed that motivated the v3 split.

---

## Technical Notes

- `BossBoard.lua` is a new file — add to TOC between `Leaderboard.lua` and `UI.lua`
- `MidnightSensei.BossBoard` declared in Core.lua module table
- `MidnightSenseiDB.bossBoardShared` initialised in `InitSavedVariables`
- `SPELLS_CHANGED` registered as a new event
- `Core.ScheduleSnapshots()` exposed on the Core table for event dispatch
- All snapshot builds fully wrapped in `pcall` — API failures skipped silently
- `CharDB.spellSnapshot` and `CharDB.talentSnapshot` are `nil` until first built

---

## Open Items (carry to 1.4.0+)

- Tempest (454009) — VERIFY cast ID vs aura ID in game
- Call of the Ancestors (443450) — VERIFY in game
- iLvl plausibility integrity gate — deferred, noted as backlog
- Detail share via REQD_DETAIL whisper protocol — noted as backlog

---

*Midnight Sensei is a combat performance coaching addon for World of Warcraft: Midnight (Patch 12.0)*
*Created by Midnight - Thrall (US)*
