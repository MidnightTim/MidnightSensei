# Midnight Sensei v1.5.1 Release Notes

## Overview

v1.5.1 delivers patch 12.0 spec corrections for Demonology Warlock, Marksmanship Hunter, and Preservation Evoker; fixes a recurring "You are not in a raid group" system message caused by addon messaging inside LFR groups; and adds a debug silent mode for user-side triage.

---

## Demonology Warlock: Grimoire: Fel Ravager Reclassified

**What changed:** Grimoire: Fel Ravager (1276467) was tracked as `isInterrupt` with `altIds = {132409}` (Spell Lock) to credit the pet's interrupt. In patch 12.0, the spell was redesigned — it no longer interrupts. It now purges 1 beneficial magic effect from an enemy and turns into Devour Magic while on cooldown.

**Fix:** `isInterrupt` changed to `isUtility`. `altIds` removed (Spell Lock no longer fires). The spell is now tracked as a utility reminder with no penalty for not using it.

---

## Marksmanship Hunter: Explosive Shot Added

Explosive Shot (212431) added to Marksmanship `majorCooldowns` as `talentGated = true`. Shrapnel Shot (473520) and Precision Detonation (471369) are both PASSIVE modifiers — they are not cast directly and require no tracking.

---

## Preservation Evoker: Temporal Barrier Added

Temporal Barrier (1291636) added to Preservation `majorCooldowns` as `talentGated = true`. The spell sends a ripple of temporal energy that absorbs damage and applies Echo at 30% effectiveness to up to 5 allies — a significant on-CD ramp tool.

Resonating Sphere and Energy Cycles were removed from the game in this patch. Neither was tracked in the spec DB, so no removal action was needed.

---

## LFR "You Are Not in a Raid Group" Fix

**What was happening:** When queueing for Raid Finder, `GROUP_ROSTER_UPDATE` fires on every roster change. `BroadcastVersion()` in Core.lua was sending to the `"RAID"` addon message channel when `IsInRaid()` returned true — but LFR groups are not valid targets for the `"RAID"` channel, causing WoW to print "You are not in a raid group" on every roster event.

**Fix:** Added `not IsInGroup(LE_PARTY_CATEGORY_INSTANCE)` guard to `BroadcastVersion()`, matching the guard already present in `Leaderboard.lua`'s `BroadcastToAll`. The addon no longer attempts RAID channel sends inside instance/LFR groups.

---

## Debug Silent Mode

`/ms debug silent` toggles a `Core.SilentMode` flag that suppresses all outbound `C_ChatInfo.SendAddonMessage` calls from the addon. Use it to conclusively rule out Midnight Sensei as the source of chat messaging errors. The flag resets on reload.

---

## Files Changed

- `MidnightSensei.toc` — version bump to 1.5.1
- `Core.lua` — version bump, CHANGELOG, BroadcastVersion LFR guard, `/ms debug silent`
- `Leaderboard.lua` — SafeSend SilentMode check
- `Specs/Warlock.lua` — Grimoire: Fel Ravager isUtility, altIds removed
- `Specs/Hunter.lua` — MM: Explosive Shot added
- `Specs/Evoker.lua` — Preservation: Temporal Barrier added; sourceNotes updated
