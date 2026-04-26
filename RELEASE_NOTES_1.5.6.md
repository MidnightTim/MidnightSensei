# Midnight Sensei v1.5.6 — Release Notes

This release fixes a verify report crash that blocked Balance Druid spec validation, corrects a cast tracking gap that caused false coaching feedback on Wrath, adds Solar Beam interrupt awareness, makes Force of Nature optional, and resolves a longstanding mismatch where interrupts and utility spells were silently factoring into the cooldown usage score despite being documented as "never penalised." Also included are the debug tool improvements from last cycle: Fix Character Name, Clear Boss Board, and the updated Clear Fight History with the MigrateEncounters re-populate fix.

---

## Verify Report crash — `IsTalentActive` not in scope (Core.lua)

**What broke:** Running `/ms verify report` on any spec that has a `suppressIfTalent` entry crashed with "attempt to call a nil value" at Core.lua:1899. The crash happened because `IsTalentActive` is defined as a `local function` inside `Combat/CastTracker.lua` and is not visible from `Core.lua`. The verify report handler called it directly as if it were a global.

**Fix:** Changed the `suppressIfTalent` check in the verify report to use `IsPlayerSpell` only. `IsPlayerSpell` correctly identifies whether the suppressing talent's spell is active in the player's spellbook, which is sufficient for this check.

---

## Balance Druid: Wrath casts not detected — false "never used" feedback

**What broke:** Balance Druid players with the Eclipse talent received "Rotational spell(s) never used: Starfire / Wrath" coaching feedback even when actively pressing Wrath throughout a fight. Session log analysis showed the player casting Wrath 15+ times in a single fight with every cast appearing as spell ID **190984**, while the spec was tracking spell ID **5176** (the spellbook ID). Zero casts were ever credited.

**Root cause:** In Midnight 12.0 with the Eclipse talent active, the game sends spell ID 190984 ("Eclipse: Wrath") in `UNIT_SPELLCAST_SUCCEEDED` rather than the base spellbook ID 5176. This is the same spellbook-vs-combat-ID divergence seen in earlier releases on other specs.

**Fix:** Added `altIds = {190984}` to the Wrath rotational entry. The cast tracker's altId map now routes all 190984 events to the 5176 tracking entry. The verify report will show `PASS (via alt id=190984)` when Wrath is cast.

**Note:** Starfire (Lunar Eclipse variant) may have the same issue. The diagnostic session was Solar Eclipse only — no Starfire casts occurred to confirm its combat ID. A session log from a Lunar Eclipse fight is needed before a Starfire altId can be added.

---

## Balance Druid: Solar Beam added as interrupt

Solar Beam (78675) was not tracked at all. It is a talented Balance Druid silence/interrupt confirmed present via live session talent data (`Solar Beam, talentGated`). Added as `isInterrupt = true, talentGated = true` — tracked, never penalised, informational note at fight end when not used.

---

## Balance Druid: Force of Nature no longer scored against

Force of Nature (205636) is a talented cooldown that is not widely pressed on cooldown across the player population. Marking it `isUtility = true` keeps it tracked and visible in verify reports but removes it from the cooldown usage score. When not pressed, the fight-end note reads "Note: Force of Nature — not used or detected this fight. No penalty."

---

## Scoring: `isUtility` and `isInterrupt` now correctly excluded from score

**What broke:** `Feedback.lua` has always documented that `isInterrupt` and `isUtility` majorCooldown entries are "never penalised." However, `Scoring.lua`'s `ScoreCooldownUsage` function had no matching guard. These entries were present in `cdTracking` and contributed to the cooldown weight — if never pressed, they reduced the score.

This affected every spec that has an interrupt (Death Knight, Hunter, Evoker, Rogue, Mage, Monk, Paladin, Warrior, Shaman, Demon Hunter) and utility spells (Mage Spellsteal). Players were being silently penalised for not using abilities the system claimed it would never penalise.

**Fix:** Added `not cd.isUtility and not cd.isInterrupt` guard to the `ScoreCooldownUsage` loop. Scoring behaviour now matches the stated design intent.

---

## Debug Tools: Fix Character Name

New recovery tool for players who renamed their character. Accessible via `/ms debug fixname` or the Debug Tools Recovery section. Shows a confirmation dialog pre-filled with the detected old name from stored data. The user can edit the field. On confirm, validates the typed name exists in stored encounters, bossBests, or shared snapshot before applying. Repairs charName across all grade history, review fights, Boss Board records, and leaderboard self-entries.

Note: simultaneous name swaps (Character A renames to B while B renames to A) are not fixable in code — each character receives the other's SavedVariables data at the OS level. Use Clear Boss Board and Clear Fight History on the affected character, then re-ingest from encounter history.

---

## Debug Tools: Clear Boss Board

New destructive action in the Debug Tools Recovery section. Clears all personal boss best records (`bossBests`) and removes this character's entries from the account-wide shared snapshot. Requires typing "Confirm" to activate.

---

## Debug Tools: Clear Fight History — MigrateEncounters re-populate fix

**What broke:** After clearing fight history and reloading, all encounters reappeared. Root cause: the legacy `MidnightSenseiDB.encounters` account-wide store (left intact from the schema v2 migration) was never cleared. On reload, `MigrateEncounters()` detected an empty CharDB and re-populated it from the account-wide store.

**Fix:** Clear Fight History now also removes entries matching this character's name and realm from `MidnightSenseiDB.encounters`, leaving other characters' data intact. The HUD is also refreshed after clearing to prevent stale display.

Clear Fight History now requires typing "Confirm" to activate (previously a simple Yes/Cancel dialog).
