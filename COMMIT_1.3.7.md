# v1.3.7 — Leaderboard Overhaul, Minimap Button & Keystone Detection

## Leaderboard

### feat(leaderboard): dual score columns — LATEST and WK AVG
Single right column replaced with two distinct columns. Each shows grade letter + score (e.g. `B+ 81`). LATEST reflects the most recent fight; WK AVG reflects this week's boss kill average.

### feat(leaderboard): four clickable sort headers
PLAYER (A-Z), RECENT DIFF/BOSS (timestamp desc), LATEST (score desc), WK AVG (weekly avg desc). Active sort highlights in accent colour. Replaces the previous separate sort row.

### fix(leaderboard): LFR and raid location bleeding into Dungeons tab
Guild entries stored one shared `diffLabel`/`instanceName`/`bossName` triplet. A post-dungeon LFR broadcast would overwrite these fields, causing LFR location to render on the Dungeons tab. Per-content-type fields (`dungeonLabel`, `dungeonInstance`, `dungeonBoss`, `dungeonKs`, `raidLabel`, `raidInstance`, `raidBoss`) now stored separately on SCORE receive and on the self-entry, mirroring the existing delve pattern.

### fix(leaderboard): WK AVG showing -- for own raids and dungeons
Self-entry was missing `raidAvg` and `dungeonAvg` — only populated for peers via `MergeEntry`. Self-entry in `GetGuildData` now computes both from this week's boss kills in local `CharDB` history.

### fix(leaderboard): frame width 520 → 720px
Long location strings (e.g. Timewalking boss names) no longer break across lines.

---

## Keystone

### fix(keystone): key level was nil on all M+ encounters
`GetSlottedKeystoneInfo` returns nil after the key is consumed — by the time `PLAYER_REGEN_DISABLED` fires, the key is already activated. Switched to `GetActiveKeystoneInfo` as primary call. `GetSlottedKeystoneInfo` retained as fallback.

### feat(keystone): /ms debug backfill keys
Retroactively patches existing `"Mythic"` dungeon history using `GetSeasonBestForMap`. Probes three API paths, builds instance name → key level map from season best data, and patches matching entries marked `(inferred)`. `/ms debug backfill keys clear` reverts all patches.

---

## Grade History

### fix(history): SPEC / DIFF column truncating difficulty and keystone level
Column renamed `SPEC / DIFF`, widened 94 → 130px, truncation limit 22 → 28 chars. `"Enhancement M+10"` and similar now render without truncation.

---

## Minimap

### feat(minimap): LibDBIcon minimap button
Replaces custom frame implementation. Collapses and hides correctly with Minimap Map Icons, ButtonBin, ElvUI, TitanPanel, and all LDB manager addons. Left-click: toggle HUD. Right-click: toggle Leaderboard. Shift+right-click: Options context menu. Position persists in `MidnightSenseiDB.minimapIcon`.

### feat(minimap): logo.tga as icon
Button uses `logo.tga`. `## IconTexture` added to TOC — logo now appears in the WoW AddOns settings panel.

### chore(toc): bundle LibStub, LibDataBroker-1.1, LibDBIcon-1.0
Three libs added to `libs\` folder and registered in TOC load order before addon files.

---

## Bug Fixes

### fix(ui): _final leaking into component scores display
`scores._final` (scalar passed to `GenerateFeedback` for score-tier branching) was appearing as a raw `_final  81` row in both Fight Complete and Encounter Detail component scores panels. Filtered out in both display paths.

### fix(slash): /ms versions help text misleading
Was labelled "Ping and display" implying active pinging. Corrected to "Show addon versions passively collected this session".

---

## FAQ

### docs(faq): leaderboard section updated
Added: per-tab location accuracy, M+ key level display, one-new-run peer caveat, self-entry immediate correction note.

---

## Pilot Notes

- After updating, peers need one new dungeon or raid for per-tab location to populate correctly. Self-entry corrects immediately from local history. `/ms clean payload` on a peer's client triggers an immediate update on their side.
- Run `/ms debug backfill keys` once to patch existing M+ history with inferred key levels from season best data. Review output before committing — use `/ms debug backfill keys clear` to revert if needed.
- `MidnightSenseiDB.minimapIcon` is a new account-wide SavedVariable key managed by LibDBIcon. No migration needed.
