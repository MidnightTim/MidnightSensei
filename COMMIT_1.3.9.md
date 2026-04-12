# Commit — Midnight Sensei v1.3.9

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Branch:** main
**Tag:** v1.3.9

---

## Summary

Boss Board personal leaderboard, persistent spell/talent snapshot system for contributor tooling, debug window reorganisation, X button fix, All Characters history filter removal, and minimap/context menu Boss Board access.

---

## Changed Files

- `MidnightSensei.toc` — version bump to 1.3.9, add BossBoard.lua to load order
- `BossBoard.lua` — new file
- `Core.lua` — module declaration, SavedVariables init, slash commands, version, changelog
- `Analytics.lua` — bossBests schema expanded with charName, specName, className, keystoneLevel
- `UI.lua` — context menu, minimap, debug window, grade history filter

---

## Commits

### feat(bossboard): new BossBoard.lua — personal boss best leaderboard
New file. Three tabs (Dungeons, Raids, Delves). Columns: Date, Character, Spec, Diff/Boss, Score — all five sortable with toggle direction. Keyed by `bossID`. All-time best only, never resets. Class-coloured character names. Per-row hover tooltip with boss name, instance, grade, date, kill count. `BB.Toggle()`, `BB.Show()`, `BB.RefreshUI()`.

### feat(bossboard): shared snapshot — MidnightSenseiDB.bossBoardShared
Account-wide best snapshot, keyed by `"Name-Realm|bossID"`. Always keeps higher score. Updated at `SESSION_READY` (3s delay) and after every boss fight via `GRADE_CALCULATED`. Intended for recovery and future cross-character comparison.

### feat(bossboard): BB.IngestFromHistory() — debug ingest from encounter history
Scans `CharDB.encounters`, seeds `bossBests`. Prints added/updated/skipped counts. Resolves identity fields from current character/spec as fallback for legacy encounters. Patches `"?"` identity on skipped entries. Triggered via `/ms debug bossboard ingest` or Debug Tools window.

### fix(bossboard): identity fallback for legacy encounter records
Legacy encounters predating `charName`/`specName`/`className` fields now resolve to current `UnitName("player")` and `Core.ActiveSpec`. Skipped entries (score not better) are also patched if their stored identity is `"?"`. Running ingest a second time after upgrading repairs previously stored `"?"` values.

### fix(analytics): expand bossBests schema with missing identity fields
`bossBests[bossID]` entries now store `charName`, `specName`, `className`, `keystoneLevel` on both create and best-score update paths. Previously missing — caused `"?"` display in Boss Board Character and Spec columns.

### feat(core): BossBoard module declaration and SavedVariables init
`MidnightSensei.BossBoard` declared in module table. `MidnightSenseiDB.bossBoardShared` initialised in `InitSavedVariables`. TODO comment removed from `bests` struct (bossBests now implemented).

### feat(core): slash commands — /ms bossboard, /ms bb, /ms debug bossboard ingest
Three new slash handlers added before the Unknown command fallback. `/ms bossboard` and `/ms bb` both call `MS.BossBoard.Toggle()`. `/ms debug bossboard ingest` calls `MS.BossBoard.IngestFromHistory()`. `/ms bossboard` added to `/ms help` output.

### feat(ui): Boss Board in HUD right-click context menu
"Boss Board" item added between Leaderboard and Options. All subsequent `yOff` values shifted -24px. Frame height bumped 206 → 230.

### feat(ui): Ctrl+Right-click minimap opens Boss Board
`IsControlKeyDown()` branch added before the plain `RightButton` handler. Tooltip updated with `"Ctrl+Right-click: Boss Board"` line.

### feat(debug): persistent spell snapshot — SPELLS_CHANGED → CharDB.spellSnapshot
`SPELLS_CHANGED` registered. `BuildSpellSnapshot()` enumerates spellbook via `C_SpellBook.GetSpellBookItemInfo` / `C_SpellBook.GetSpellBookSkillLineInfo`. Stores `{ timestamp, specName, className, spells[] }` in `CharDB`. Sorted by spellID. Debounced 1s.

### feat(debug): persistent talent snapshot — PLAYER_TALENT_UPDATE → CharDB.talentSnapshot
`BuildTalentSnapshot()` walks `C_Traits` tree. Stores `{ timestamp, specName, className, talents[] }` in `CharDB`. Sorted by nodeID. Debounced 1s via shared `ScheduleSnapshots()`.

### feat(debug): export commands read from persisted snapshots
`/ms debug talents` and `/ms debug spells` read from `CharDB.talentSnapshot` and `CharDB.spellSnapshot`. Include capture timestamp and spec in output header. Direct to `/reload` if no snapshot exists yet.

### fix(ui): debug window X button rendering as box
`✕` (U+2715) replaced with plain `"X"`. FRIZQT__.TTF covers basic Latin only — documented constraint. Title anchor adjusted to clear button area.

### feat(ui): debug window section labels — Class Debugging and Recovery Tools
Reusable `AddSectionLabel(text, color)` helper added. Two new sections: Class Debugging (cyan `{0.00, 0.82, 1.00}`) containing Talent Export and Spells Export; Recovery Tools (orange `{1.0, 0.5, 0.0}`) containing Boss Board Ingest, Backfill M+ Keys, Clean Payload. `btnY` scoping corrected — declared before both helper closures.

### feat(debug): Boss Board Ingest button in Recovery Tools
`AddDebugBtn("Boss Board Ingest", ...)` added above Backfill M+ Keys.

### fix(ui): remove All Characters filter from Grade History
`FilterEncounters` early-return for `mode == "all"` removed. Filter button removed from `filterDefs`. Since schema v3 (1.3.2), encounters live in `SavedVariablesPerCharacter` — "All Characters" was silently identical to "This Character".

### chore(core): version bump to 1.3.9
`Core.VERSION` fallback updated to `"1.3.9"`. Full 1.3.9 changelog entry added.

---

## TOC Changes

Add `BossBoard.lua` between `Leaderboard.lua` and `UI.lua`:
```
Leaderboard.lua
BossBoard.lua
UI.lua
```

Bump `## Version: 1.3.9`

---

## Pilot Notes

- Run `/ms debug bossboard ingest` on first login after updating to seed Boss Board from existing history
- Tempest (454009) and Call of the Ancestors (443450) still marked VERIFY — confirm cast IDs in game with `/ms verify`
- `CharDB.spellSnapshot` and `CharDB.talentSnapshot` are `nil` until first built — snapshots build within 2s of login
- `bossBoardShared` is `nil`-safe — no bloat on fresh installs until first boss kill
