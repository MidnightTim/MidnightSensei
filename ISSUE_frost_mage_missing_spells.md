# [Enhancement] Frost Mage missing Mirror Image, Supernova, and Frostbolt alt ID

## Summary

Three gaps in Frost Mage spell coverage discovered via `/ms verify`:

1. **Mirror Image (55342)** — class talent CD, firing x2, not tracked
2. **Supernova (157980)** — class talent rotational, firing x3, not tracked
3. **Frostbolt id=228597** — fires UNIT_SPELLCAST_SUCCEEDED x26 alongside the primary Frostbolt (116); previously noted as a passive auto-cast but confirmed player-visible via verify

## Fix

- `Specs/Mage.lua` Frost spec:
  - Mirror Image (55342) added to `majorCooldowns`, `talentGated = true`
  - Supernova (157980) added to `rotationalSpells`, `talentGated = true`, `minFightSeconds = 20`
  - Frostbolt (116) gains `altIds = {228597}` — either ID credits the same rotational slot
