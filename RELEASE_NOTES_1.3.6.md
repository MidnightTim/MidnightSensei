# Midnight Sensei — Release Notes v1.3.6

**Tagline:** Feedback Depth, Devourer Fixes & Leaderboard Stability  
**Date:** April 2026  
**Author:** Midnight - Thrall (US)

---

## Overview

1.3.6 is a targeted quality pass focusing on three areas: correcting Devourer Demon Hunter spell tracking that was broken by an incorrect spell ID, improving feedback quality for high-scoring players who were hitting a coaching dead-end in the 90+ range, and fixing a Lua crash in the leaderboard that fired on every guild roster update.

All changes were informed by live session data captured with the MidnightTim Debugging Tools companion addon.

---

## Bug Fixes

### Devourer Demon Hunter — Collapsing Star Tracking

Collapsing Star was being tracked against spell ID `1221167`, which is the **talent tree node ID**, not the castable spell. The actual ability that appears in the spellbook during a Void Metamorphosis window is `1221150`. This meant Collapsing Star casts were never detected, and the spell could never earn cast credit regardless of how many times it was used.

This was confirmed via debug tool session export showing `1221150` appearing in the spellbook at t=49.92 during a live Void Metamorphosis window, while `1221167` never appeared as a castable spell.

**Additional Collapsing Star fixes in this release:**

- `minFightSeconds` lowered from **90 to 45**. Session data showed the spell first becoming available ~23 seconds into a Void Metamorphosis window that opened at t=26.82 in a 73-second fight. The previous 90-second threshold would have suppressed feedback entirely on the majority of real fight lengths.
- Collapsing Star no longer triggers "never used" feedback when `combatGated = true`. Because the spell only exists inside a Void Metamorphosis window, if that window never opened during the fight the spell was never available — reporting it as missed is incorrect. The `combatGated` flag now gates both the never-used check and the cast-count check.

### Leaderboard — SyncGuildOnlineStatus Nil Crash

`SyncGuildOnlineStatus` was defined as a `local function` at line 1151 in Leaderboard.lua, but was called from `OnAddonMessage` which is defined at line 734. In Lua, a local defined after a calling function is not in scope for that function — it resolves as a nil global and throws `attempt to call global 'SyncGuildOnlineStatus' (a nil value)`.

This error fired 3x per session, triggered by every GUILD_ROSTER_UPDATE event. Fixed by adding a forward declaration `local SyncGuildOnlineStatus` before `OnAddonMessage`, which the later definition fills in correctly.

### Leaderboard — Delve Tab Online Dots Always Showing Green

All players in the Delve tab were showing a green online dot regardless of actual status. The online dot logic contained `if activeTab == "party" or contentType == "delve" then isOnline = true end`, which forced every delve row to appear online. This was incorrect — delve data is local character history pulled from `MidnightSenseiCharDB`, not live presence data. Only the party tab should force online status (since party members are by definition in your session). Removed `contentType == "delve"` from the override.

### Leaderboard — Delve Tab Showing Player Count

The Delve tab label was displaying a player count (e.g. `Delves (8)`). This count is meaningless for the Delve tab since it reflects local character history rather than online players, and it was inconsistent with the other tab labels. The label now reads `Delves` with no count.

---

## Feedback Improvements

### High-Score Players Now Receive Actionable Next Steps

Previously, players scoring 90+ with no specific issues flagged received a generic one-liner ("Strong execution — cooldowns and activity both on point.") with no path forward. The nothing-flagged fallback is now tiered by final score:

| Score Range | Feedback |
|---|---|
| **95+** | Role-specific next-step advice (e.g. "align burst windows with enemy vulnerability phases; reduce time between GCD ending and next cast to sub-0.2s") |
| **90–94** | Identifies the weakest component score by name and directs focus there |
| **Below 90** | Existing behavior retained |

### Activity Feedback Threshold Lowered to 85%

Players at 80–84% activity were previously receiving no downtime feedback — the threshold was `< 80`. This band is significant: at 82% activity a DPS player is losing roughly 7 GCDs per minute. The threshold is now `< 85`, with a lighter tone for the 80–84 range ("X casts left on the table") versus the more direct message used below 80.

### Cast-Count Feedback for Rotational Spells

Rotational spell entries in the spec database now support an optional `cdSec` field. When defined, Midnight Sensei calculates how many casts of that spell should have fit in the fight duration and compares against actual `useCount`. If a player used the spell but missed 2 or more potential casts, feedback fires:

> "Could have cast more: Void Ray (6/9) — press these on every available GCD when your primary spenders are on cooldown."

This surfaces improvement opportunities for players who are already using their rotational spells but not maximizing them — a gap that was previously invisible at high scores.

---

## Technical Notes

- `combatGated` flag is now stored on rotational tracking entries at fight start and respected in both the never-used check and the new cast-count check.
- `scores._final` is passed into `GenerateFeedback` to enable score-tier branching in the fallback without a redundant weighted score calculation.
- `cdSec` is an optional field on `rotationalSpells` spec entries. No existing specs define it yet — it is available for spec authors to add on spells where a cooldown duration is known and cast-count feedback would be meaningful.

---

## Files Changed

| File | Changes |
|---|---|
| `Core.lua` | Collapsing Star ID corrected, minFightSeconds lowered, version bumped to 1.3.6, changelog updated |
| `Analytics.lua` | Activity threshold, nothing-flagged fallback, cast-count feedback, combatGated flag, scores._final |
| `Leaderboard.lua` | SyncGuildOnlineStatus forward declaration, Delve tab online dot fix, Delve tab label count removed |
| `MidnightSensei.toc` | Version bumped to 1.3.6 |

---

*Midnight Sensei is a combat performance coaching addon for World of Warcraft: Midnight (Patch 12.0).*  
*Created by Midnight - Thrall (US)*
