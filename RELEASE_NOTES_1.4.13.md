# MidnightSensei v1.4.13 Release Notes

## Overview

Two spec correctness fixes and a CastTracker infrastructure expansion. Demonology Warlock's Grimoire: Fel Ravager interrupt is now properly detected via its pet's Spell Lock cast. Augmentation Evoker's Time Skip is correctly suppressed when Interwoven Threads replaces it. The underlying `altIds` system is now fully general — it covers both `rotationalSpells` and `majorCooldowns` entries.

---

## Fix: Grimoire: Fel Ravager Interrupt Not Detected (Demonology Warlock)

**What broke:** Grimoire: Fel Ravager (1276467) summons a Fel Ravager pet. When used as an interrupt, the pet fires **Spell Lock (id=132409)** rather than the original summon spell. CastTracker only watched for 1276467, so interrupt uses went undetected — the ability always showed 0 uses in the Fight Complete window.

**Why:** The existing `altIds` infrastructure in CastTracker only applied to `rotationalSpells`. The `altIdMap` reverse-lookup was never built for `majorCooldowns` entries, so there was no path to credit 1276467 when 132409 fired.

**What changed:**
- `Specs/Warlock.lua`: Added `altIds = {132409}` to the Grimoire: Fel Ravager entry
- `Combat/CastTracker.lua`: Extended `altIdMap` build loop to scan `spec.majorCooldowns`; added `elseif altIdMap[spellID]` branch in ABILITY_USED to credit `cdTracking` on the primary ID when an alt fires
- `Core.lua`: Extended verify `altIdOwner` to include majorCooldowns altIds — Spell Lock 132409 no longer appears in OTHER SPELLS

---

## Fix: Time Skip Tracked When Interwoven Threads Is Talented (Augmentation Evoker)

**What broke:** Interwoven Threads (id=412713) is a PASSIVE talent that replaces Time Skip on the Augmentation talent bar. When taken, Time Skip is inaccessible — but the tracker still expected it and flagged it as an unused CD.

**Why:** Time Skip had `talentGated = true` but no `suppressIfTalent` gate. Because Interwoven Threads is a replacement talent on the same node, `IsTalentActive(404977)` can return true in builds that include the replacement, causing the CD to pass the gate check even when it cannot actually be cast.

**What changed:**
- `Specs/Evoker.lua`: Added `suppressIfTalent = 412713` to Time Skip — same pattern as Celestial Alignment / Incarnation: Chosen of Elune
