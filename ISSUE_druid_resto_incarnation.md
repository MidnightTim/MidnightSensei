## [Enhancement] Druid Restoration: Incarnation: Tree of Life cooldown tracking

**Description:** Incarnation: Tree of Life was not tracked as a cooldown for Restoration Druid, despite being a real, selectable talent.

**Context:** A stale note marked it as "not in the talent tree," recorded against an old talent snapshot from early in the addon's history. That check was either wrong at the time or predated the finalized talent tree. It shares its talent-tree slot with the already-tracked Convoke the Spirits, so the two are mutually exclusive picks.

**Fix:** Incarnation: Tree of Life added as a tracked, situational cooldown, mutually exclusive with Convoke the Spirits — only whichever one is actually talented affects your cooldown score.

**Steps to reproduce (before fix):** Talent into Incarnation: Tree of Life and use it during a fight — the addon would never register the cast.
