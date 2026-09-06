## [Enhancement] Monk Brewmaster: Celestial Brew cooldown tracking

**Description:** Celestial Brew was not tracked as a cooldown for Brewmaster Monk, despite being a real, selectable talent.

**Context:** A stale note marked it as "not in the talent tree," recorded against an old talent snapshot from early in the addon's history. That check was either wrong at the time or predated the finalized talent tree.

**Fix:** Celestial Brew added to Brewmaster as a tracked cooldown, expected to be used regularly (it's a short-cooldown absorb shield, not an emergency-only defensive).

**Steps to reproduce (before fix):** Talent into Celestial Brew and use it during a fight — the addon would never register the cast, and it would never show up in cooldown usage scoring.
