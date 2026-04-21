# MidnightSensei v1.4.14 Release Notes

## Overview

Spell coverage pass for Frost Mage and Vengeance Demon Hunter. Both specs had multiple abilities confirmed firing via `/ms verify` that were either missing entirely or only partially tracked. No scoring system changes — this release is purely additive spell data.

---

## Frost Mage

**Mirror Image (55342)** — class talent cooldown, confirmed firing x2. Added to `majorCooldowns` with `talentGated = true`.

**Supernova (157980)** — class talent, confirmed firing x3. Added to `rotationalSpells` with `talentGated = true`. Previously existed in Fire spec majorCooldowns but was absent from Frost entirely.

**Frostbolt id=228597** — fires `UNIT_SPELLCAST_SUCCEEDED` alongside the primary Frostbolt (116). Previously noted as a passive auto-cast and excluded. Confirmed player-visible via verify at x26 casts. Added as `altIds = {228597}` on the Frostbolt (116) rotational entry — either ID credits the same slot.

---

## Vengeance Demon Hunter

**Immolation Aura (258920)** — confirmed firing x5, was in `validSpells` but absent from rotational tracking. Added to `rotationalSpells` as primary Fury generator.

**Demon Spikes (203720)** — was only in `uptimeBuffs` for physical mitigation uptime scoring. It is also a pressed spell with a cooldown. Added to `majorCooldowns` so cast usage is scored. The `uptimeBuffs` entry is retained — both trackers run independently.

**Fracture** — previously removed with a note that it was not in the Vengeance talent tree. Confirmed firing via three variant IDs (225919, 263642, 225921) at x15 each. Added to `rotationalSpells` with primary id=225919 and `altIds = {263642, 225921}` — all three variants credit the same entry.

**Infernal Strike (189110)** — gap-closer with charges, confirmed firing x5. Added to `rotationalSpells`.

**Felblade** — existing entry (232893) gains `altIds = {213243}`. The spec-variant ID 213243 was confirmed firing x4 and was appearing in OTHER SPELLS in verify.
