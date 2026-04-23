# Commit Notes – MidnightSensei v1.5.1

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.5.1

## Summary

Patch 12.0 spec corrections for Demonology Warlock, Marksmanship Hunter, and Preservation Evoker. Fixes LFR "You are not in a raid group" error from RAID channel sends inside instance groups. Adds debug silent mode for user-side message triage.

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bump to 1.5.1 |
| `Core.lua` | Version 1.5.1; CHANGELOG; BroadcastVersion `not IsInGroup(LE_PARTY_CATEGORY_INSTANCE)` guard; `/ms debug silent` toggle |
| `Leaderboard.lua` | `SafeSend` short-circuits when `Core.SilentMode` is true |
| `Specs/Warlock.lua` | Grimoire: Fel Ravager → `isUtility`; `altIds = {132409}` removed |
| `Specs/Hunter.lua` | MM: Explosive Shot (212431) added to majorCooldowns, `talentGated = true` |
| `Specs/Evoker.lua` | Preservation: Temporal Barrier (1291636) added to majorCooldowns, `talentGated = true`; sourceNotes updated to v1.5.0 snapshots |

## Commits

```
fix(warlock): Grimoire: Fel Ravager reclassified as isUtility — no longer interrupts in patch 12.0
feat(hunter): MM Explosive Shot (212431) added to majorCooldowns as talentGated
feat(evoker): Preservation Temporal Barrier (1291636) added to majorCooldowns as talentGated
fix(core): BroadcastVersion skips RAID channel inside LFR/instance groups — fixes repeated system error
feat(debug): /ms debug silent — suppress all outbound addon messages for error triage
chore: v1.5.1 CHANGELOG
```
