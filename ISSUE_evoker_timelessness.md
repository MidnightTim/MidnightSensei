## [Enhancement] Evoker Augmentation: Timelessness cooldown tracking

**Description:** Timelessness was never tracked as a cooldown for Augmentation Evoker — this was a plain gap, not a prior incorrect finding.

**Context:** Timelessness is cast on an ally (a threat-reduction enchant), similar to already-tracked abilities like Rescue. The cast itself still fires normally from the caster's perspective regardless of who the effect lands on, so it should track the same way those other ally-targeted utility spells already do.

**Fix:** Timelessness added to Augmentation as a tracked, situational cooldown (no penalty for holding it).

**Steps to reproduce (before fix):** Talent into Timelessness and cast it on an ally during a fight — the addon would never register the cast.

**Follow-up:** Detection should work the same way Rescue's does, but this hasn't been confirmed with a live combat log yet since the ability was never tracked before. Worth a quick `/ms verify` check on the next fight where it gets used.
