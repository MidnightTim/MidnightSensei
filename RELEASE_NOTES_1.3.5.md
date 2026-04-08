# MidnightSensei 1.3.5

## Summary
Guild leaderboard data sync now works end-to-end across all guild members regardless of rank. Officers push their complete guild DB to all members on login, leaderboard open, and Refresh. Non-officers receive a fully populated leaderboard passively. Multiple bugs in rank detection, content-type display isolation, delve boss capture, and layout were resolved.

## Files Changed

| File | Changes |
|------|---------|
| `Leaderboard.lua` | Officer Pull/Push protocol, roster cache, rank detection, PUSHDATA payload, layout fixes, raid tab bleed fix |
| `Core.lua` | `officerRankThreshold` setting, debug inject commands, changelog |
| `Analytics.lua` | Delve boss name capture fix (`BOSS_START` guard removed) |
| `UI.lua` | `TruncateLabel()` helper, history panel spec column width |

## Included Changes

### Officer Pull/Push leaderboard sync protocol
Implements a 4-message guild sync protocol that populates leaderboard data across all guild members without requiring everyone to be online simultaneously.

- `PULLREQ` — officer → guild: "send me your scores"
- `PULLDATA` — member → guild: score summary response
- `REQPUSH` — member → guild: "please push me the current data"
- `PUSHDATA` — officer → guild: full DB broadcast to all members

Officers fire `PULLREQ` on SESSION_READY (10s), on leaderboard open, and on Refresh. Non-officers send `REQPUSH` on those same triggers. A 15-second cooldown prevents spam. `PUSHDATA` carries 20 fields including scores, weekly bests, and dungeon, raid, and delve location data.

### Roster cache replaces unavailable WoW APIs
`GuildRoster()` and `GuildControlGetRankFlags()` are both unavailable in Midnight 12.0, so all calls were removed.

- Added `rosterCache` as `[shortName] = rankIndex`, rebuilt on every `GUILD_ROSTER_UPDATE`
- Added `rosterReady` flag and `pendingActions` queue to defer rank checks until roster loads
- Added `WhenRosterReady(fn)` wrapper for rank-dependent operations
- Added `officerRankThreshold` setting, default `3`, so `rankIndex <= threshold` determines officer-tier authority

### PUSHDATA duplicate row and self-skip fixes
Fixed two bugs causing incorrect display on receiving clients.

1. Duplicate rows: receiver created short-name keys even when a full-name key already existed from SCORE broadcasts. Added key resolution to reuse existing full-name keys.
2. Self-data dropped: self-skip logic was too broad and dropped valid pushed data. Fixed to only skip when sender is self.

### Officer self-entry missing location data in PUSHDATA
When an officer entry was freshly created, self-injection only wrote scores and left location fields empty. This caused empty dungeon, boss, and instance names for the officer row.

Fixed by walking `CharDB.encounters` newest-first to populate best encounter data per content type before push.

### Dungeon names bleeding into raid leaderboard tab
`GetGuildData()` was using the single most-recent boss fight across dungeons and raids. If the latest fight was a dungeon, raid rows could inherit dungeon location text.

Fixed in two places:
- `GetGuildData()` now tracks dungeon and raid encounter context separately
- Raid tab now reads raid-specific location fields guarded on `raidBest > 0`

### Delve boss name not captured in Midnight 12.0
In Midnight 12.0 delves, `ENCOUNTER_START` fires before `PLAYER_REGEN_DISABLED`. The old `BOSS_START` guard blocked boss context capture because combat had not started yet.

Removed the `fightActive` guard so `currentBossContext` is always set when `ENCOUNTER_START` fires.

### Leaderboard frame width and history panel text overflow
- Frame widened from `520px` to `620px`
- DIFF/BOSS column widened from `230px` to `296px`
- History panel spec column narrowed from `100px` to `94px`
- Added `TruncateLabel(s, maxChars)` helper to strip WoW color codes before measuring length and cap history boss labels

### Debug inject commands for pipeline validation
Added new debug commands for testing guild sync without running live content:

- `/ms debug guild inject dungeon`
- `/ms debug guild inject raid`
- `/ms debug guild inject delve`
- `/ms debug guild inject remove`

### officerRankThreshold setting
Added saved setting `officerRankThreshold` with default `3`. Any guild rank with `rankIndex <= threshold` is treated as officer-tier for sync authority.

## Known Issues Carried Forward
- `officerRankThreshold` is not yet exposed in `/ms options` UI
- `bossBests[bossID]` continues to accumulate for future Boss Board work
- Spell IDs marked `-- VERIFY` still need in-game confirmation

## Confirmed Not Working in Midnight 12.0
- `GuildRoster()`
- `GuildControlGetRankFlags()`
- BNet friend enumeration
- `C_Delves` tier API