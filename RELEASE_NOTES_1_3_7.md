# Midnight Sensei v1.3.7 — Leaderboard Overhaul, Minimap Button & Keystone Detection

## Summary

1.3.7 is a substantial UI and data quality release. The leaderboard gets a full column redesign with two distinct score columns and four sortable headers. Keystone level detection is fixed at the API level so M+ runs record correctly going forward, and a backfill tool is included for existing history. A minimap button using LibDBIcon is added for full compatibility with minimap manager addons.

---

## Leaderboard

### Dual Score Columns
The single right column is replaced by two distinct columns:

- **LATEST** — grade letter and score from the player's most recent fight (e.g. `B+ 81`)
- **WK AVG** — grade letter and weekly average score across this week's boss kills (e.g. `A- 86`)

Both columns show `(prev)` when the data is from a prior week.

### Sortable Headers
All four column headers are now clickable sort buttons. Active sort highlights in accent colour.

| Header | Sorts by |
|---|---|
| PLAYER | Name A → Z |
| RECENT DIFF / BOSS | Last activity timestamp — most recently active floats to top |
| LATEST | Most recent fight score descending |
| WK AVG | Weekly average descending (default) |

### Per-Tab Location Isolation
Guild entries previously stored a single shared `diffLabel`/`instanceName`/`bossName` triplet reflecting the last broadcast of any content type. An LFR score broadcast after a dungeon score would overwrite the location fields, causing LFR location text to appear on the Dungeons tab.

Each content type now stores its own location fields (`dungeonLabel`, `dungeonInstance`, `dungeonBoss`, `dungeonKs`, `raidLabel`, `raidInstance`, `raidBoss`) mirroring the existing pattern for Delves. The Dungeons tab only reads dungeon location fields, the Raids tab only reads raid location fields.

**Rollout note:** Existing guild entries will display correctly for your own character immediately (self-entry rebuilds from local history on every open). Peers need to complete one new dungeon or raid for their entry to populate the correct per-tab location. Running `/ms clean payload` on their client will also trigger an immediate update.

### WK AVG Fix for Self
The self-entry was missing `raidAvg` and `dungeonAvg` — these were only populated for peers via incoming score broadcasts. The self-entry now computes both directly from this week's boss kills in local `CharDB` history, so the WK AVG column correctly populates for your own character without requiring a new encounter.

### Frame Width
Frame widened from 520px to 720px. `"Timewalking - Throne of the Tides - Commander Ulthok"` and similar long location strings no longer break across multiple lines.

---

## Keystone Level Detection

### Root Cause Fix
`GetSlottedKeystoneInfo` was being called at `PLAYER_REGEN_DISABLED` (fight start). This API only returns data while the key is still sitting in the slot — by the time combat begins inside the dungeon, the key has been consumed and the API returns nil. Every M+ run was recording as `"Mythic"` with no level.

The fix uses `GetActiveKeystoneInfo` as the primary call, which returns the level of the run currently in progress. `GetSlottedKeystoneInfo` is retained as a fallback for the pre-activation window.

### History Backfill Tool
For encounters already recorded as `"Mythic"` with no keystone level, a new debug command attempts retroactive patching using Blizzard's season best data:

```
/ms debug backfill keys
```

The command probes available APIs (`GetSeasonBestForMap`, `GetSeasonBestAffixScoreInfoForMap`, `GetPlayerMythicPlusRatingSummary`), builds an instance name → key level map from season best data, and patches matching history entries. Levels are marked `(inferred)` since the season best for that map is used, not the specific run.

```
/ms debug backfill keys clear
```

Reverts all inferred patches and restores `"Mythic"` / nil on affected entries.

---

## Grade History

The `SPEC` column is renamed `SPEC / DIFF` and widened from 94px to 130px. Difficulty label and M+ key level were already being appended to the spec name in this column but were being truncated. The truncation limit is raised from 22 to 28 characters. Examples of what now renders in full:

- `Enhancement M+10`
- `[B] High Sage Viryx M+10`
- `Shadow Priest Mythic`

---

## Minimap Button

A minimap button is added using LibDBIcon, the community standard library for minimap buttons. This ensures correct behaviour with all minimap manager addons (Minimap Map Icons, ButtonBin, ElvUI minimap manager, TitanPanel, etc.).

**Controls:**
- Left-click — toggle HUD
- Right-click — toggle Leaderboard
- Shift+Right-click — open Options context menu
- Drag — reposition around minimap edge (position persists via SavedVariables)

**Icon:** uses `logo.tga` from the addon folder. The same icon now also appears in the WoW AddOns panel via `## IconTexture` in the TOC.

**Libraries bundled** (`libs\` folder, load order added to TOC):
- `LibStub`
- `LibDataBroker-1.1`
- `LibDBIcon-1.0`

---

## Bug Fixes

- **`_final` in component scores** — `scores._final` (a scalar passed into `GenerateFeedback` for score-tier branching) was leaking into the component scores display in both the Fight Complete panel and Encounter Detail view, showing as a raw `_final  81` row. Filtered out in both display paths.
- **`/ms versions` help text** — was labelled "Ping and display addon versions of nearby players" implying active pinging. Corrected to "Show addon versions passively collected this session".

---

## FAQ Updates

The Leaderboard section of the Help & FAQ panel is updated to document:
- Per-tab location accuracy (Dungeons and Raids tabs show content-specific location)
- M+ key level display
- The one-new-run requirement for peers after updating
- Self-entry exception (corrects immediately from local history)

---

## Technical Notes

- `GetActiveKeystoneInfo` is now the primary M+ level API. `GetSlottedKeystoneInfo` retained as fallback.
- Per-content location fields (`dungeonLabel`, `dungeonInstance`, `dungeonBoss`, `dungeonKs`, `raidLabel`, `raidInstance`, `raidBoss`) added to guild and friends entries on SCORE receive, and to the self-entry in `GetGuildData`.
- Self-entry `dungeonAvg` and `raidAvg` computed from this week's boss kills in local history during `GetGuildData` — previously missing from the self-entry entirely.
- Minimap button stored in `MidnightSenseiDB.minimapIcon` (account-wide, LibDBIcon managed).

---

*Midnight Sensei is a combat performance coaching addon for World of Warcraft: Midnight (Patch 12.0).*
*Created by Midnight - Thrall (US)*
