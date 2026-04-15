# CLAUDE.md – MidnightSensei

World of Warcraft: Midnight (Patch 12.0) performance coaching addon.
**Current version:** 1.4.5 | **Author:** Midnight - Thrall (US)
**Repo:** https://github.com/MidnightTim/MidnightSensei

---

## File Structure & Load Order

```
MidnightSensei/
├── MidnightSensei.toc      ← bump ## Version: here on every release
├── Utils.lua               ← loaded first
├── Core.lua                ← spec DB, events, slash commands, version
├── CombatLog.lua           ← aura/uptime tracking
├── Analytics.lua           ← fight scoring, feedback generation
├── Leaderboard.lua         ← guild/friend score sharing
├── UI.lua                  ← HUD, Fight Complete window, debug tools
```

**SavedVariables:**
- `MidnightSenseiDB` – account-wide (leaderboard guild/friends, debug log)
- `MidnightSenseiCharDB` – per-character (encounters, settings, bests, snapshots)

---

## Architecture

### Core.lua
- `Core.VERSION = "1.4.5"` – must match TOC `## Version:`
- 13 classes / 39 specs in `Core.SPEC_DATABASE` keyed `[classID][specIdx]`
- Schema v3: `InitSavedVariables()` + `MigrateEncounters()` on first login
- `Core.SlashHandler = MSSlashHandler` – exposed for debug window buttons
- Registered events: `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_REGEN_ENABLED`, `PLAYER_REGEN_DISABLED`, `PLAYER_SPECIALIZATION_CHANGED`, `PLAYER_TALENT_UPDATE`, `UNIT_AURA`, `UNIT_SPELLCAST_SUCCEEDED`, `UNIT_SPELLCAST_CHANNEL_START`, `ENCOUNTER_START`, `ENCOUNTER_END`, `CHAT_MSG_ADDON`, `GROUP_ROSTER_UPDATE`, `GUILD_ROSTER_UPDATE`, `SPELLS_CHANGED`
- `COMBAT_LOG_EVENT_UNFILTERED` is **fully protected in Midnight 12.0** – `RegisterEvent` triggers `ADDON_ACTION_FORBIDDEN` regardless of timing. Do not attempt to register it.
- Both `UNIT_SPELLCAST_SUCCEEDED` and `UNIT_SPELLCAST_CHANNEL_START` must be registered – channeled spells (e.g. Collapsing Star) fire `CHANNEL_START` not `SUCCEEDED`
- `DetectSpec()` uses `classID = select(3, UnitClass("player"))` + `specIdx = GetSpecialization()`
- Version broadcast on login/group/guild roster update via `BroadcastVersion()`
- `Core.seenVersions` – passively populated from `VERSION|x.x.x` addon messages

### Analytics.lua
- `IsTalentActive(spellID)` – **IsPlayerSpell fast path first**, then C_Traits walk iterating `node.entryIDs` (not just `node.activeEntry` – choice nodes have multiple entries)
- `talentGated` entries in `majorCooldowns` use **IsPlayerSpell only** – not `IsTalentActive`. IsTalentActive returns true for prerequisite nodes whose button has been replaced (e.g. CA when Incarnation is talented)
- The `else` branch for empty `cdTracking` applies the same `suppressIfTalent` and `talentGated` gates as the setup loop – it does NOT dump all spec CDs blindly
- `suppressIfTalent` is checked for both `majorCooldowns` and `rotationalSpells`
- `minFightSeconds` gates feedback on both `majorCooldowns` and `rotationalSpells`

**bests structure** (per-character, never trimmed):
- `allTimeBest`, `dungeonBest`, `raidBest`, `delveBest`
- `weeklyDungeonBest`, `weeklyRaidBest`, `weeklyDelveBest` (reset Tuesday)
- `weeklyAvg`, `weekScores` (rolling 50 boss kills)
- `bossBests[bossID]` – per-boss bests (future Boss Board, never broadcast)

**Rotational spell flags:**
- `talentGated = true` – only include if `IsPlayerSpell(id)` (or `IsTalentActive` for passives)
- `suppressIfTalent = id` – exclude if `IsTalentActive(id)` or `IsPlayerSpell(id)` returns true
- `combatGated = true` – always include regardless of spellbook (combat-granted spells like Collapsing Star)

### CombatLog.lua
- Tracks **player self-auras only** – enemy debuff fields are secret values in Midnight 12.0, not readable
- `UpdateUptime(id, isActive, now)` – must be called with both `true` AND `false` or the timer never closes
- `C_UnitAuras.GetPlayerAuraBySpellID(spellID)` – correct API for player aura lookup in Midnight 12.0

### Leaderboard.lua
- `MidnightSenseiDB.leaderboard.guild` – persisted guild scores (account-wide)
- `MidnightSenseiDB.leaderboard.friends` – persisted friend scores (account-wide)
- Checksum validation disabled – float precision divergence between clients caused false failures
- GUILD channel trusted implicitly – `GetNumGuildMembers()` returns 0 during roster sync
- `MergeEntry` tracks: `allTimeBest`, `dungeonBest`, `raidBest`, `delveBest`, `dungeonWeekBest`, `raidWeekBest`, `delveWeekBest`, `weeklyAvg`, `weekScores`
- **Epoch-based week detection for self-entry:** `GetWeekKey()` uses a 14h UTC shift + `date("!*t", ...)` which can return the OLD week key hours after the actual WoW reset (timezone/shift edge case). All self-entry "is this fight from the current week?" logic uses `GetWeekStartEpoch()` instead — pure integer arithmetic: `time() - ((time() - 482400) % 604800)` where 482400 = epoch-to-first-Tuesday-14:00 offset (epoch 0 = Thursday, +5 days +14h). This is timezone-immune.
- **`(prev)` for self-entry uses `entry.prevWeek` flag** (not `weekKey ~= wk`) — because when GetWeekKey() is stuck on the old key, both would match and `(prev)` would never fire. The flag is set in all three self-entry builders (GetPartyData, GetGuildData, GetFriendsData) when epoch-confirmed fight count is 0 but cb.weeklyAvg > 0.
- **cb weekly merge is gated on `hasThisWeek`** — do NOT restore the old `if cb.weekKey == wk then` unconditional merge for weekly avg. When wk is stale, `cb.weekKey == wk` is true but cb's avg is last week's data; merging it makes hasThisWeek appear true and blocks (prev).

### UI.lua
- `MakeFont()` – always use this, never `SetNormalFontObject` (causes blocky font)
- WoW's FRIZQT__.TTF only covers basic Latin – no `⚡`, `→`, `↑↓`, emoji (render as boxes)
- Debug Tools: right-click HUD → Debug Tools
- Version watermark on Fight Complete window: BOTTOMRIGHT, -88, 34 – reads `result.addonVersion`
- Context menu height must be manually adjusted when items are added

---

## Spec DB – Key Rules

### Spell Flags

| Flag | Meaning | Detection |
|---|---|---|
| `talentGated = true` | Only include if spell is in spellbook | `IsPlayerSpell(id)` only for CDs; `IsPlayerSpell OR IsTalentActive` for rotational |
| `suppressIfTalent = id` | Exclude when this talent is active | `IsPlayerSpell(id)` fast path, then `IsTalentActive(id)` |
| `combatGated = true` | Always include – granted by combat state | No gate |
| `isInterrupt = true` | Tracked but never penalised in scoring | – |

### suppressIfTalent – All Active Entries

| Spell | ID | Suppress ID | Suppress Name | Reason |
|---|---|---|---|---|
| Backstab | 1752 | 200758 | Gloomblade | Choice node – only one tracks |
| SW:Pain | 589 | 238558 | Misery | VT auto-applies it passively |
| Vampiric Touch | 34914 | 1227280 | Tentacle Slam | Auto-applies VT to 6 targets |
| Celestial Alignment | 194223 | 102560 | Incarnation: Chosen of Elune | Replaces CA on bar |
| Celestial Alignment | 383410 | 102560 | Incarnation: Chosen of Elune | Orbital Strike variant |
| Starsurge | 78674 | 1271206 | Star Cascade | Auto-fires Starsurge passively |
| Wrath | 5176 | 429523 | Lunar Calling | Elune's Chosen – Lunar Eclipse only |
| Soul Immolation | 1241937 | 258920 | Spontaneous Immolation | Replaces with passive version |

### Shapeshift Spells – NEVER TRACK

These fire `UPDATE_SHAPESHIFT_FORM` not `UNIT_SPELLCAST_SUCCEEDED`. `useCount` permanently 0. Do not add to any tracked list.

| Spell | ID | Notes |
|---|---|---|
| Metamorphosis (Vengeance/Devourer) | 191427 | Havoc Metamorphosis `191427` is fine – different spec |
| Incarnation: Chosen of Elune | 102560 | "Talent, Shapeshift" tooltip confirmed |
| Incarnation: Guardian of Ursoc | 102558 | "improved Bear Form...freely shapeshift in and out" |

### VERIFY – Pending In-Game Confirmation

| Spell | ID | Spec | Concern |
|---|---|---|---|
| Ascendance | 114050 | Elemental Shaman | "Transform into a Flame Ascendant" – may be shapeshift |
| Ascendance | 114052 | Resto Shaman | "transforms into a Water Ascendant" – may be shapeshift |
| Voidform | 228260 | Shadow Priest | "twists your Shadowform" – likely fires SUCCEEDED |
| Celestial Alignment | 383410 | Balance | Orbital Strike variant ID – VERIFY runtime ID |
| Enrage aura | 184362 | Fury Warrior | Spell list shows 184361 |
| Shield of the Righteous | 132403 | Prot Paladin | VERIFY C_UnitAuras |
| Art of War | 406064 | Retribution | VERIFY C_UnitAuras |
| Killing Machine | 59052 | Frost DK | Talent shows 51128 |
| Rime | 51124 | Frost DK | Spell list shows 59057 |
| Hot Streak | 48108 | Fire Mage | Spell list shows 195283 |
| Brain Freeze | 190446 | Frost Mage | Talent shows 190447 |
| Fingers of Frost | 44544 | Frost Mage | Talent shows 112965 |

---

## What Does NOT Work – Do Not Retry

| Approach | Why |
|---|---|
| `COMBAT_LOG_EVENT_UNFILTERED` | Fully protected in Midnight 12.0 – `ADDON_ACTION_FORBIDDEN` regardless of when registered |
| `IsPlayerSpell` for passive talent detection | Returns false for talent tree nodes that don't add a castable spell |
| `talentGated` CDs using `IsTalentActive` | Returns true for prerequisite nodes whose button is replaced (e.g. CA when Incarnation is taken) |
| `suppressIfTalent` via `IsTalentActive` alone for choice nodes | C_Traits `defInfo.spellID` may not match cast spellID for shapeshifts |
| `UNIT_SPELLCAST_SUCCEEDED` for channeled spells | Channeled spells fire `CHANNEL_START` – must register both |
| `UNIT_SPELLCAST_SUCCEEDED` for shapeshifts | Shapeshifts fire `UPDATE_SHAPESHIFT_FORM` |
| Enemy debuff uptime tracking | Enemy aura fields are secret values in Midnight 12.0 |
| Checksum validation on leaderboard payloads | Float precision differences cause false failures |
| `GetNumGuildMembers()` as guild membership gate | Returns 0 during roster sync |
| `GetWeekKey()` for self-entry "is this week?" | Returns old week key hours after reset — use `GetWeekStartEpoch()` epoch arithmetic instead |
| `if cb.weekKey == wk` for self-entry weekly merge | When wk is stale, both match; merging sets weeklyAvg > 0 and blocks the (prev) fix — gate on `hasThisWeek` (epoch count) instead |
| `DebugLog()` from Core.lua | Scoped to Analytics.lua – not accessible from Core |
| `BNet` friend enumeration | Broken in Midnight 12.0 |
| `C_Delves` for delve tier number | Nil in current build |
| Active VPING for `/ms versions` | Passive collection from login broadcasts works on all versions |
| Incarnation: Chosen of Elune as trackable CD | Shapeshift – permanently untraceable |
| `SetNormalFontObject` in UI | Causes blocky font – use `MakeFont()` |
| Unicode characters in WoW UI text | FRIZQT__.TTF is basic Latin only |

---

## Slash Commands (complete)

```
/ms                      /ms show                /ms hide
/ms history              /ms lb                  /ms lb remove <n>
/ms lb debug             /ms options             /ms help
/ms faq                  /ms credits             /ms about
/ms report               /ms reset               /ms update
/ms versions             /ms verify              /ms verify report
/ms debug                /ms debug version       /ms debug rotational
/ms debug zone           /ms debug friends       /ms debug guild
/ms debug guild broadcast /ms debug guild inject  /ms debug guild ping
/ms debug guild receive  /ms debug self          /ms debug spells
/ms debug talents        /ms debuglog            /ms debuglog clear
/ms friend               /ms friend add <n>      /ms friend remove <n>
/ms clean payload        /ms bossboard           /ms bb
/ms config
```

### Key Debug Commands

- `/ms verify` – toggle verify mode; collects live spellcast IDs during combat
- `/ms verify report` – show full report: PASS/FAIL per tracked spell + OTHER spells seen
- `/ms debug rotational` – prints each CD/rotational entry with `IsPlayerSpell=` and `suppress_IPS=` values; critical for diagnosing gate failures
- `/ms debug talents` – exports full talent snapshot with descriptions; `>>>` flags keyword matches for `suppressIfTalent`/`talentGated` review
- `/ms debuglog` – show internal debug log

---

## Talent Snapshot Audit Workflow

1. In-game: `/ms debug talents` – copy output – paste to `.txt` file
2. Feed to parser (checks non-PASSIVE IDs against spec DB tracked entries)
3. Review untracked IDs: assess whether to add as `talentGated`, `suppressIfTalent`, or skip
4. Review `>>>` flagged entries: identify choice nodes and auto-proc patterns
5. Update spec DB, update `sourceNote` with snapshot version and node count

**Snapshot file naming:** `<SpecName>_Talents.txt` (e.g. `Balance_Druid_Talents.txt`)
**All 39 specs verified** against v1.4.3 snapshots. sourceNotes reflect verification date.

---

## Known Interference Sources

- **Single Button Assistant addon** – intercepts and redirects casts; can cause false NOT SEEN in `/ms verify` and false "never used" feedback. Disable for clean testing.

---

## Operational Notes

- Run `/ms clean payload` once after updating from any version prior to 1.3.2
- Guild leaderboard entries appear only after a successful score broadcast is received
- `bossBests` in `CharDB.bests` collects per-boss data for future Boss Board – never broadcast
- TOC `## Version:` must be bumped manually on every release alongside `Core.VERSION`
- The debug rotational output now shows `IsPlayerSpell=` and `suppress_IPS=` per CD entry – use this first when feedback seems wrong
