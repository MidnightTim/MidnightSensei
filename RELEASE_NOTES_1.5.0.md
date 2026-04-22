# Midnight Sensei v1.5.0 Release Notes

## Overview

v1.5.0 delivers the weekly reset notification system, a fully revamped Verify workflow with a HUD bar and in-window controls, Devourer DH Soul Immolation spec correction, and removal of three obsolete debug tools.

---

## Weekly Reset Notification

Midnight Sensei now announces when the WoW weekly reset has occurred. On the first login after the Tuesday reset, a chat message fires once per character. The detection uses a Tuesday-aligned week bucket derived from server time (`math.floor((serverTime - 5*86400) / 604800)`), stored in `MidnightSenseiCharDB.lastWeeklyBucket`. No configuration required — it fires automatically.

---

## Devourer: Soul Immolation Redesign

**What changed:** Soul Immolation (1241937) was previously listed in `majorCooldowns` with `suppressIfTalent = 258920` (Spontaneous Immolation). This modeled the old behavior where Spontaneous Immolation *replaced* Soul Immolation.

**Why it was wrong:** In patch 12.0, Spontaneous Immolation was redesigned — it now *buffs* Soul Immolation rather than replacing it. Both spells coexist. Keeping the suppressIfTalent caused Soul Immolation to be skipped for any Devourer with Spontaneous Immolation talented, which is nearly universal.

**Fix:** Soul Immolation moved from `majorCooldowns` (with suppressIfTalent) to `rotationalSpells` with `talentGated = true`. It now appears in rotation tracking correctly for any Devourer who has taken the talent.

---

## Verify System Improvements

### Debug Tools Window

MS Verify controls are now accessible directly from the Debug Tools window (right-click HUD → Debug Tools):

- **Toggle Verify Mode** — same as `/ms verify`
- **Verify Report** — same as `/ms verify report`
- **Auto-Enable on Login** — new `verifyAutoEnable` setting; when checked, verify mode starts automatically on every `PLAYER_LOGIN`

### Verify Report Flag Annotations

Each spell in the verify report now shows all applicable flags inline:

| Flag | Meaning |
|---|---|
| `[talentGated]` | Only active when talent is learned |
| `[combatGated]` | Granted by combat state |
| `[suppress:ID]` | Suppressed when talent ID is active |
| `[interrupt]` | Interrupt — tracked but never penalised |
| `[utility]` | Utility — tracked but never penalised |
| `[displayOnly]` | Spell List only — not tracked in analytics |
| `[healerCond]` | Reactive healer CD — 90% credit on success, 0% on wipe |
| `[alt:ID]` | Has alternate spell IDs |

### Verify HUD Bar

When verify mode is active, a compact green bar appears directly below the main Midnight Sensei frame. It shows **"Verify Mode On"** and a **"View Report"** button that opens and closes the verify export window without needing the slash command.

---

## Removed Debug Tools

Three debug tools were removed from the addon UI and slash command list. They are documented in `CLAUDE.md` for recovery if ever needed.

| Tool | Command | Reason Removed |
|---|---|---|
| Self-Delve History | `/ms debug self` | No longer needed — delve tracking stable |
| Zone/Instance Info | `/ms debug zone` | No longer needed — routing logic stable |
| Debug Log | `/ms debuglog`, `/ms debuglog clear` | Vestigial — nothing writes to the log; always empty |

---

## Weekly Reset Debug Commands

Two debug commands added for diagnosing the weekly reset detection:

- **`/ms debug weekly`** — prints the current bucket, stored bucket, time API in use, and reset status (same week / reset pending / first login)
- **`/ms debug weekly fire`** — forces the announcement to fire immediately and resets the stored bucket to the current week; useful for testing before the next Tuesday reset

---

## Files Changed

- `Core.lua` — weekly reset detection, verify auto-enable setting, debug tool removals, CHANGELOG
- `UI.lua` — debug window Verify section, verify HUD bar, `UI.UpdateVerifyBar()`, `UI.ToggleVerifyExport()`
- `Specs/DemonHunter.lua` — Soul Immolation moved to rotationalSpells; suppressIfTalent removed
