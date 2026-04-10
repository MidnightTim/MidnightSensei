# Commit — Midnight Sensei v1.3.6

**Date:** April 10, 2026  
**Author:** Midnight - Thrall (US)  
**Branch:** main  
**Tag:** v1.3.6

---

## Summary

Fix Devourer Collapsing Star tracking, improve feedback for high-scoring players, fix leaderboard Lua crash, and clean up Delve tab display issues.

---

## Changed Files

- `MidnightSensei.toc` — version bump to 1.3.6
- `Core.lua` — Collapsing Star ID/threshold fix, version, changelog
- `Analytics.lua` — feedback depth improvements
- `Leaderboard.lua` — nil crash fix, Delve tab display fixes

---

## Commits

### fix(devourer): correct Collapsing Star spell ID to 1221150
Tracking was using talent node ID 1221167 instead of the castable spell ID 1221150. Confirmed via MidnightTim debug tool session export showing 1221150 appearing in spellbook during a live Void Metamorphosis window.

### fix(devourer): lower Collapsing Star minFightSeconds from 90 to 45
Session data showed the spell appearing ~23s into a Void Metamorphosis window that opened at t=26.82 in a 73s fight. The 90s threshold suppressed feedback on most real fight lengths.

### fix(devourer): skip never-used feedback for combatGated spells
Collapsing Star only exists inside a Void Metamorphosis window. If the window never opened the spell was unavailable — reporting it as missed is incorrect. combatGated flag now stored on rotational tracking entries and respected in both the never-used and cast-count checks.

### fix(leaderboard): forward declare SyncGuildOnlineStatus before OnAddonMessage
Local function defined at line 1151 was being called from OnAddonMessage at line 734. In Lua a local defined after its caller is out of scope and resolves as a nil global. Caused attempt to call global 'SyncGuildOnlineStatus' (a nil value) 3x per session on GUILD_ROSTER_UPDATE.

### fix(leaderboard): remove force-online override from Delve tab
contentType == "delve" was included in the isOnline = true override, forcing all delve rows to show a green dot. Delve data is local character history with no live presence signal. Only party tab should force online status.

### fix(leaderboard): remove player count from Delve tab label
Delve tab was displaying Delves (N) where N was the count of characters with delve history. Count is not meaningful for local history data and was inconsistent with other tab labels. Label now reads Delves. Removed unused delveCount local.

### feat(feedback): lower activity feedback threshold from 80 to 85
Players at 80-84% activity were receiving no feedback. At 82% a DPS player loses ~7 GCDs per minute. New 80-84 band uses lighter tone: "X casts left on the table" rather than the severity message used below 80.

### feat(feedback): tier-aware nothing-flagged fallback
Previously all clean fights received a generic one-liner with no path forward. Fallback now branches on final score: 95+ receives role-specific next-step advice, 90-94 names the weakest scoring category, below 90 retains existing hints. scores._final passed into GenerateFeedback to enable branching without a second score calculation.

### feat(feedback): cast-count feedback for rotational spells with cdSec
Rotational spell entries now support an optional cdSec field. When defined, missed cast potential is calculated as floor(duration / cdSec). If missed >= 2, feedback fires: "Could have cast more: X (actual/potential)". Targets high-scoring players who use their spells but don't maximize them.

---

## Testing Notes

- Collapsing Star fix confirmed against debug tool session data — spell appeared as 1221150 at t=49.92 in a 73s fight
- Leaderboard nil crash was reproducible 3x per session; forward declaration resolves it
- Delve tab online dot and label changes are display-only with no data impact
- Activity threshold change is additive — no existing feedback paths affected
- nothing-flagged fallback only fires when no other feedback was generated; score tiers are non-overlapping
