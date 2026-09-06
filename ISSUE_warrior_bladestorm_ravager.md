## [Enhancement] Warrior Arms/Fury: Bladestorm and Ravager cooldown tracking

**Description:** Bladestorm was not tracked as a cooldown for Arms, and neither Bladestorm nor Ravager were tracked for Fury, despite both being real, selectable choice-node talents in both specs.

**Context:** Arms previously had a stale note marking Bladestorm as "not in the talent tree," recorded against a very old talent snapshot from early in the addon's history. That check was either wrong at the time or predated the finalized talent tree. Ravager was already correctly tracked for Arms at the same choice node, so the gap was one-sided. Fury had neither ability tracked at all — a plain omission, not a prior incorrect finding.

**Fix:** Bladestorm added to Arms as a tracked cooldown, mutually exclusive with Ravager (only the one you've actually chosen affects your cooldown score). Ravager and Bladestorm both added to Fury as a tracked, mutually exclusive pair.

**Steps to reproduce (before fix):** Talent into Bladestorm on Arms, or either ability on Fury, and use it in a fight — the addon would never register the cast, and the cooldown usage score would silently ignore it.
