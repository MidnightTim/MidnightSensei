## [Enhancement] Druid Feral: Incarnation: Avatar of Ashamane cooldown tracking

**Description:** Incarnation: Avatar of Ashamane was not tracked as a cooldown for Feral Druid, despite being a real, selectable talent that replaces Berserk on the action bar.

**Context:** A stale note marked it as "not in the talent tree," recorded against an old talent snapshot from early in the addon's history. That check was either wrong at the time or predated the finalized talent tree. It also shares its talent-tree slot with the already-tracked Convoke the Spirits, so the two are mutually exclusive picks.

**Fix:** Incarnation: Avatar of Ashamane added as a tracked cooldown. Berserk no longer gets flagged as unused when Ashamane is talented instead (since Ashamane replaces it). Ashamane and Convoke the Spirits are tracked as mutually exclusive — only whichever one is actually talented affects your cooldown score.

**Steps to reproduce (before fix):** Talent into Incarnation: Avatar of Ashamane and use it during a fight — the addon would never register the cast, and would incorrectly flag Berserk as unused.
