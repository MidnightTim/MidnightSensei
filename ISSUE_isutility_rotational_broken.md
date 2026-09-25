## [Bug] Optional rotational spells still flagged as "never used" despite isUtility flag

**Description:** Follow-up to the Unholy Death Knight Death Strike report. Marking a rotational spell as `isUtility = true` (meaning "optional, never penalise") had no effect at all - it still showed up in the Fight Complete window's "Rotational spell(s) never used" list.

**Root cause (two separate bugs, both required for the fix):**
1. `Combat/CastTracker.lua` builds a fresh runtime tracking table for each rotational spell at the start of combat, and that table only copied over `useCount`, `label`, `minFightSeconds`, `combatGated`, `cdSec`, and `orGroup` from the spec definition - `isUtility` was never one of the copied fields. So the flag was always `nil` at runtime, no matter what the spec file said.
2. `Analytics/Feedback.lua`'s "never used"/"low used" feedback block also had no `isUtility` check of its own to begin with (only `Scoring.lua`'s cooldown-usage scoring checked it, and only for major cooldowns, not rotational spells).

Fixing only the second bug first appeared to do nothing, because the field it checked didn't exist on the object yet - confirmed by testing after a full `/reload`.

**Fix:** Both bugs fixed together - the flag now survives from the spec definition into the runtime tracking table, and the feedback block now actually checks it.

**Scope:** This bug affected every spell in the game marked `isUtility` inside a `rotationalSpells` list, going back to whenever this pattern was first used (including Lava Burst, the original ability this pattern was built around). Confirmed affected: Unholy Death Knight (Death Strike), Feral Druid (Chomp), Windwalker Monk (Strike of the Windlord), Protection Paladin (Hammer of the Righteous), Holy Priest (Holy Word: Chastise), Elemental Shaman (Earth Shock), Restoration Shaman (Lava Burst), Affliction Warlock (Agony).

**Steps to reproduce (before fix):** Play any of the above specs, skip the listed optional spell, and check the Fight Complete window - it would list the spell as "never used" despite being correctly marked optional.
