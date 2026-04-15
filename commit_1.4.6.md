# Commit — Midnight Sensei v1.4.6

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Branch:** main
**Tag:** v1.4.6

---

## Summary

Nightly polish pass targeting three user-facing bugs: verify report showing FAIL for spells the player hasn't talented, offline guild members generating "not available" spam on login, and the self-entry WK AVG column never showing (prev) after a weekly reset. The (prev) fix required a full redesign of the self-entry week detection to use epoch arithmetic instead of GetWeekKey(), which can return a stale week key for hours after the actual WoW reset.

---

## Changed Files

- `Core.lua` — version 1.4.6, verify report SKIP logic, debug guild self-entry diagnostics, HELLO whisper loop guard
- `Leaderboard.lua` — GetWeekStartEpoch(), epoch-based self-entry week detection, prevWeek flag, WhisperOnlineGuildMembers offline guard

---

## Commits

### chore: bump version to 1.4.6, update changelog

### fix(verify): SKIP instead of FAIL for untalented or suppressed spells
- Verify report now emits SKIP (not FAIL) for spells not active in the current build
- talentGated spells skipped when IsPlayerSpell returns false
- suppressIfTalent spells skipped when the suppressing talent is active
- allTracked table now carries talentGated, suppressIfTalent, combatGated flags through to the report loop

### fix(leaderboard): self-entry WK AVG now shows (prev) after weekly reset
- GetWeekKey() can return the old week key for hours after the WoW reset due to date() timezone/shift edge cases — do not rely on it for "is this week" decisions on the self-entry
- Added GetWeekStartEpoch(): pure integer arithmetic (time() - ((time() - 482400) % 604800)) that is timezone-immune and reset-timing-immune
- All three self-entry builders (GetPartyData, GetGuildData, GetFriendsData) now use epoch-based boss kill counting instead of enc.weekKey == wk
- hasThisWeek derived from epoch wCount/dungCount/raidCount — not selfEntry.weeklyAvg, which can be polluted by the cb merge before the check runs
- cb weekly data merge gated on hasThisWeek — when wk is stale, cb.weekKey == wk is true but the avg is last week's data; merging it would block (prev) indefinitely
- prevWeek flag set on self-entry when no epoch-confirmed fights exist but cb.weeklyAvg > 0
- Display checks entry.prevWeek in addition to weekKey ~= wk for isSelf entries

### fix(leaderboard): offline guild members no longer generate "not available" spam
- WhisperOnlineGuildMembers staggered each whisper with C_Timer.After but did not re-check online status at fire time
- Each callback now re-scans the guild roster and skips the send if the member went offline during the stagger window

### fix(leaderboard): HELLO whisper infinite loop between two addon instances
- When addon A whispered HELLO to B, B whispered HELLO back, triggering A to reply again
- Added helloWhisperReplied session table; each sender is only replied to once per session

### feat(debug): /ms debug guild shows self-entry weekly avg state
- Prints GetWeekKey(), cb.weekKey, cb.weeklyAvg, cb.weekKey==wk
- Prints selfEntry.weekKey, weeklyAvg, dungeonAvg, raidAvg, dungeonBest, prevWeek
- Prints whether (prev) would fire — critical for diagnosing post-reset display issues
