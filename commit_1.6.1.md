# Commit — Midnight Sensei v1.6.1

**Date:** May 3, 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.6.1

---

## Summary

Five critical leaderboard sync bugs resolved — delve data now reliably crosses between clients, self-entries show the most recent run instead of the all-time best, and group joins trigger data requests for existing members. Evoker spec database completed with four missing utilities confirmed via tooltip. Update notification redesigned to amber HUD bar.

---

## Changed Files

| File | Description |
|---|---|
| `MidnightSensei.toc` | Version bump 1.6.0 → 1.6.1 |
| `Core.lua` | Version fallback bump; `/ms debug encounters` command; `/ms debug broadcast` extended |
| `Analytics/Engine.lua` | `IsEligibleEncounter()` filter on `GetLastEncounter()`; new `GetLastEncounterByType(encType)` |
| `Leaderboard.lua` | REQ/REQD per-type broadcast loop; `BuildScorePayload()` refactor; `GROUP_ROSTER_UPDATE` new-member detection; `GetDelveData` bestEnc/mostRecentEnc split; whisper print gate |
| `Specs/Evoker.lua` | Rescue, Cauterizing Flame, Expunge+altId, Stasis added; 15 passives documented |
| `Specs/Warlock.lua` | sourceNote updated: May 2026 second-pass |
| `Specs/Warrior.lua` | sourceNote updated: May 2026 second-pass |
| `Specs/Paladin.lua` | sourceNote updated: May 2026 second-pass |
| `Specs/Shaman.lua` | sourceNote updated: May 2026 second-pass |
| `UI.lua` | Update notification: amber bar + popup replaces chat print |

---

## Commits

```
fix(leaderboard): GetDelveData self-entry shows mostRecentEnc label, not best-scoring enc

fix(leaderboard): REQ/REQD now broadcast per content type (delve/dungeon/raid separately)

fix(analytics): GetLastEncounter skips non-eligible encTypes (normal/trash pulls)

fix(leaderboard): GROUP_ROSTER_UPDATE sends REQ when new members lack partyData

fix(leaderboard): suppress whisper "Online — Updated" print for background syncs

feat(evoker): Rescue, Cauterizing Flame, Expunge+Naturalize altId, Stasis added

feat(ui): amber update bar above HUD replaces chat print for version alerts

chore: version bump 1.6.0 → 1.6.1
```
