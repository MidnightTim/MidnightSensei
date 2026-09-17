## [Bug] Unholy Death Knight: Death Strike counted as part of core rotation

**Description:** Death Strike was tracked in Unholy's rotational spells with a `minFightSeconds` gate and no optional-use flag, meaning it was scored as an expected part of the core rotation. Reported by the user: it's available but not expected to be used in the core rotation for Unholy specifically.

**Context:** Death Strike is a survival/self-heal Runic Power spender - useful defensively, but not something an Unholy DK is expected to weave into their damage rotation on cooldown the way Blood (its tank spec) does. The tracking entry didn't distinguish between "core rotation" and "optional/situational," so any Unholy player who didn't lean on it for damage got docked for "not using" it.

**Fix:** Death Strike reclassified as `isUtility = true` in Unholy's rotationalSpells - same pattern already used for Restoration Shaman's Lava Burst (optional filler, bonus credit if used, never penalised if skipped).

**Steps to reproduce (before fix):** Play Unholy DK through a fight without pressing Death Strike - the addon would flag it as an unused rotational spell and dock activity/rotation scoring accordingly.
