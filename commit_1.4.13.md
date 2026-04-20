# Commit Notes – MidnightSensei v1.4.13

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.4.13

## Summary

Two spec correctness fixes: Grimoire: Fel Ravager interrupt tracking for Demonology Warlock via the pet's Spell Lock alt ID, and Time Skip suppression for Augmentation Evoker when Interwoven Threads is talented. The altIds infrastructure is now fully general — majorCooldowns entries can carry altIds just like rotationalSpells.

## Changed Files

| File | Change |
|---|---|
| `Specs/Warlock.lua` | Grimoire: Fel Ravager — `altIds = {132409}` (Spell Lock) |
| `Specs/Evoker.lua` | Time Skip — `suppressIfTalent = 412713` (Interwoven Threads) |
| `Combat/CastTracker.lua` | altIdMap build extended to majorCooldowns; CD alt-ID fallback in ABILITY_USED |
| `Core.lua` | Version 1.4.13; CHANGELOG entry; verify altIdOwner extended to majorCooldowns |
| `MidnightSensei.toc` | Version bump to 1.4.13 |

## Commits

```
fix(warlock): credit Grimoire: Fel Ravager when Spell Lock (132409) fires

Grimoire: Fel Ravager summons a Fel Ravager pet; interrupt uses fire
id=132409 (Spell Lock) rather than the summon spell id=1276467.
Added altIds={132409} to the spec entry and extended CastTracker's
altIdMap to cover majorCooldowns so the pet cast credits the primary CD.

fix(evoker): suppress Time Skip when Interwoven Threads is talented

Interwoven Threads (412713) replaces Time Skip on the Augmentation bar.
Added suppressIfTalent=412713 — same pattern as CA/Incarnation.

feat(casttracker): extend altIdMap to cover majorCooldowns entries

altIdMap was previously built only from rotationalSpells. Any
majorCooldown with an altIds field now participates in the reverse-lookup,
and ABILITY_USED credits cdTracking when an alt ID fires.

chore: v1.4.13 — bump TOC, Core.VERSION, CHANGELOG
```
