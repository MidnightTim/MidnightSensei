# Midnight Sensei v1.7.4 - Release Notes
**Date:** July 11, 2026

## Overview

Version 1.7.4 adds Ascendance tracking for Enhancement Shaman players who chose Ascendance over Doom Winds on their choice node.

---

## Enhancement Shaman: Ascendance Now Tracked as a Major Cooldown

Ascendance (id 114051) is a 2-minute transformation cooldown in the Enhancement talent tree. It shares a choice node with Doom Winds — players who talent Ascendance cannot use Doom Winds separately (Ascendance triggers it automatically).

As of v1.7.3, Doom Winds was already suppressed for Ascendance-talented players. However, Ascendance itself was not tracked, so those players were missing cooldown usage feedback entirely for their primary 2-minute burst window.

**Fix:** Ascendance is now tracked as a major cooldown for Enhancement Shaman. Players with Ascendance talented will see cooldown usage feedback for it. Players with Doom Winds talented are unaffected.

**Spell ID confirmed:** 114051, nodeID 92219, 2 min cooldown. Fires UNIT_SPELLCAST_SUCCEEDED (confirmed in-game 07/11/2026).
