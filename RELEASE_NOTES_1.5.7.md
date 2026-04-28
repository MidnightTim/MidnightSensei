# Midnight Sensei v1.5.7 — Release Notes

This release fixes Brewmaster Monk tracking gaps (Blackout Kick alt ID, missing Expel Harm, Rushing Jade Wind added as optional), corrects a verify report bug where spell counts accumulated across multiple fights instead of resetting each combat, adds a full verify history and side-by-side compare window, and fixes the weekly reset announcement firing a day early for US players.

---

## Brewmaster Monk: Blackout Kick not detected

**What broke:** Blackout Kick showed `FAIL — NOT SEEN` in the Verify Report and generated "never used" feedback even when pressed throughout a fight. Session log confirmed x174 casts all fired as spell ID **205523**, while the spec tracked spellbook ID 100784. Zero casts were ever credited.

**Fix:** Added `altIds = {205523}` to the Blackout Kick entry in both Brewmaster and Windwalker. The cast tracker now routes all 205523 events to the 100784 tracking entry. Verify shows `PASS (via alt id=205523)`.

---

## Brewmaster Monk: Expel Harm not tracked

Expel Harm (322101) was missing entirely from Brewmaster rotational tracking. It's a 5-second cooldown energy spender that heals the Brewmaster and consumes all active Healing Spheres from Gift of the Ox — pressed x185 times in a single fight in session data. Added to `rotationalSpells` with `minFightSeconds = 15`.

---

## Brewmaster Monk: Rushing Jade Wind added as informational

Rushing Jade Wind (116847) was not tracked. It appeared frequently in OTHER SPELLS in verify reports (combat cast ID 148187 × 27 per session). It's a situational AoE ability — not universally expected on cooldown — so it's added as `isUtility = true, talentGated = true`. Tracked and shown in verify, but never scored against. Combat alt ID 148187 added.

---

## Verify Report: spell counts accumulated across fights

**What broke:** `VerifySeenSpells` was never reset between combats. Counts accumulated from every pull since verify mode was enabled — a player running a full dungeon with verify on would see counts representing 10+ fights combined, making the report useless for evaluating any single pull.

**Fix:** Both `VerifySeenSpells` and `VerifySeenAuras` are now reset at every genuine new `COMBAT_START`. The grace-window resume path (brief de-aggro) is unaffected — the reset only fires on a true new combat.

---

## Verify: fight history and side-by-side compare window

New feature: verify snapshots are now saved automatically at `COMBAT_END` when verify mode is active. Each snapshot captures the spec, zone, timestamp, and full spell cast data. Up to 20 snapshots are retained per character.

A **Compare** button has been added to the Verify Report window. Clicking it opens a 1100px side-by-side panel showing two snapshots at once. Each panel has `<` / `>` buttons to cycle through your full snapshot history. Left panel defaults to the most recent saved fight; right panel defaults to the current session. Each snapshot is labeled with a fight number, spec, time, and zone so pulls are easy to identify at a glance.

The single-report window closes automatically when the compare window opens.

---

## Weekly Reset: announcement was a day early for US players

**What broke:** The "Weekly Reset Detected" message fired on Monday evening for US players (Pacific, Central, Eastern timezones) instead of after the actual Tuesday server reset.

**Root cause:** `GetWeekBucket()` in Core.lua used a reset boundary of Tuesday 00:00 UTC. For US players, Tuesday 00:00 UTC is Monday evening local time. The actual WoW reset is Tuesday 14:00 UTC. `GetWeekKey()` and `GetWeekStartEpoch()` in Leaderboard.lua already used the correct 14-hour offset — `GetWeekBucket()` was inconsistent.

**Fix:** `RESET_OFFSET` updated from `5 * 86400` to `5 * 86400 + 14 * 3600`. All three week-boundary functions now reference Tuesday 14:00 UTC.
