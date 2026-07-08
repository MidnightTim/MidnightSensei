# Midnight Sensei v1.7.2 - Release Notes
**Date:** July 7, 2026

## Overview

Version 1.7.2 fixes two Elemental Shaman tracking bugs affecting feedback accuracy.

---

## Elemental Shaman: Earth Shock No Longer Flagged When Elemental Blast is Talented

Players running Elemental Blast in their build were receiving "Earth Shock never used" feedback despite correctly using Elemental Blast as their Maelstrom spender instead.

Earth Shock and Elemental Blast are mutually exclusive in the Elemental rotation. When Elemental Blast is talented, Earth Shock is not part of the priority list.

**Fix:** Earth Shock is now suppressed from tracking when Elemental Blast is talented. Players with Elemental Blast will no longer see any Earth Shock feedback.

---

## Elemental Shaman: Tempest Casts Now Tracked Correctly

The Tempest proc mechanic gives Elemental Shaman a chance (0.3% per Maelstrom spent) to replace the next Lightning Bolt with Tempest (a stronger AoE version). In Midnight 12.0, this replacement fires as spell id 452201 rather than the standard Lightning Bolt id 188196.

These Tempest casts were not being credited to Lightning Bolt in rotation tracking, causing them to appear as unrecognized spells in the verify report.

**Fix:** Tempest (id 452201) is now registered as an alternate cast ID for Lightning Bolt. Tempest casts correctly count toward Lightning Bolt use in rotation tracking.
