# MidnightSensei v1.4.10 — Release Notes

This release delivers a major healer scoring overhaul, Elemental Shaman Farseer hero path support, two Resto Shaman spell additions, and three Mage spec data corrections confirmed through live in-game verification.

---

## healerConditional Scoring — Fight-Dependent Healer CDs Now Scored Fairly

**Problem:** Healer cooldowns like Spirit Link Totem, Lay on Hands, and Tranquility are fight-reactive — correct play on an easy fight is to *not* use them. The old engine gave 0% credit for any unused CD, unfairly penalizing healers on clean content.

**Fix:** New `healerConditional = true` flag on fight-reactive CDs. If a flagged CD goes unused and the fight succeeds (not a wipe), 90% credit is awarded. On a wipe, 0% credit still applies — the CD was needed and wasn't used.

**Engine changes:**
- `Engine.lua`: tracks `bossKillSuccess` from the existing `BOSS_END` event; non-boss fights always count as a success
- `Scoring.lua`: `ScoreCooldownUsage` awards 90% weight for unused `healerConditional` CDs on successful fights

**Applied to all 7 healer specs:** Resto Shaman, Disc Priest, Holy Priest, Mistweaver, Holy Paladin, Preservation Evoker, Resto Druid. Throughput CDs with "on CD" usage (Unleash Life, Thunder Focus Tea, Dream Breath, etc.) were intentionally left unflagged.

---

## Resto Shaman: Healing Wave + Healing Stream Totem Added; Surging Totem Fix

**Healing Wave (77472):** The primary filler heal for Resto Shaman was completely absent from rotational tracking. Live-verified id=77472 fired=6x. Added with `minFightSeconds = 15`.

**Healing Stream Totem (5394):** A ~30s cooldown totem that should be dropped consistently throughout a fight. Live-verified id=5394 fired=3x. Added with `minFightSeconds = 30`.

**Surging Totem talentGated fix:** Surging Totem is gated behind the Totem hero talent path but was missing `talentGated = true`, causing it to appear in tracking for all Resto Shamans regardless of hero path. Fixed. Also marked `healerConditional = true`.

---

## Elemental Shaman: Farseer Hero Path Cooldowns Added

Two CDs were missing from the Elemental spec, leaving Farseer players with no coaching on spells unique to their hero path.

**Earth Elemental (198103):** Baseline defensive/tank-threat CD. Live-verified id=198103 fired=1x. Added to majorCooldowns.

**Ancestral Swiftness (443454):** Farseer hero talent CD with a ~30s cast window. Live-verified fired=1x. Added as `talentGated = true` with `minFightSeconds = 30`.

**Ascendance (114050) VERIFY resolved:** Confirmed fires `UNIT_SPELLCAST_SUCCEEDED` correctly on both Farseer and Stormbringer hero paths. Not a shapeshift suppression issue.

---

## Fire Mage: Fireball ID Corrected, Scorch Removed

**Fireball ID (116 → 133):** A prior audit comment had the correction backwards. Live verification confirmed id=133 fires as Fireball on a Fire Mage (fired=10x). id=116 is Arcane Blast and must never appear in a Fire spec.

**Scorch removed:** Scorch is a situational movement-only spell. Tracking it penalizes players more often than it rewards — any fight where the player correctly stood still and used Fireball would show Scorch as "not cast." Removed from rotationalSpells and priorityNotes.

---

## Frost Mage: id=228597 Passive Confirmed — Do Not Track

Long-standing VERIFY item resolved. id=228597 ("Frostbolt") fires automatically alongside Glacial Spike casts as part of the Icicle-building mechanic. It is not a player-initiated cast. Confirmed across multiple sessions at a consistent 1:1 ratio with Glacial Spike casts. Documented in spec comment and CLAUDE.md "What Does NOT Work" table.
