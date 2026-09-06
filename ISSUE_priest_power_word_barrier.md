## [Enhancement] Priest Discipline: Power Word: Barrier cooldown tracking

**Description:** Power Word: Barrier was not tracked as a cooldown for Discipline Priest, despite being a real, selectable talent.

**Context:** A stale note marked it as "not in the talent tree," recorded against an old talent snapshot from early in the addon's history. That check was either wrong at the time or predated the finalized talent tree.

**Fix:** Power Word: Barrier added to Discipline as a tracked, situational cooldown (no penalty for holding it — it's use-when-needed, not use-on-cooldown).

**Steps to reproduce (before fix):** Talent into Power Word: Barrier and cast it during a fight — the addon would never register the cast.
