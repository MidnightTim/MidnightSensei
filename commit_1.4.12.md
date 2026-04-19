# Commit Notes — MidnightSensei v1.4.12

**Date:** 2026-04-19
**Author:** Midnight - Thrall (US)
**Tag:** v1.4.12

## Summary

Resto Shaman correctness pass: Healing Rain now tracked correctly under the Surging Totem hero path via an `altIds` mapping in CastTracker; Wind Shear and Purify Spirit added as interrupt/utility entries. Verify system updated to understand alt IDs. Generic healer feedback fixed to remove Disc Priest-specific "Atonement value" language. New `/ms debug auras` command for aura ID discovery.

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bump 1.4.11 → 1.4.12 |
| `Core.lua` | Fallback version bump; Core.CHANGELOG 1.4.12 entry; verify PASS/FAIL alt-ID support; altIds excluded from OTHER SPELLS; `/ms debug auras` slash command |
| `Combat/CastTracker.lua` | `altIdMap` built at COMBAT_START from `altIds` entries; ABILITY_USED and pre-combat replay fall back through altIdMap before rotationalTracking lookup |
| `Specs/Shaman.lua` | Healing Rain (73920) gains `altIds = {456366}`; Wind Shear (57994) added as `isInterrupt`; Purify Spirit (77130) added as `isUtility` |
| `Analytics/Feedback.lua` | Generic healer low-activity note: "Atonement value" removed |

## Commits

```
fix(shaman): map Healing Rain alt id=456366 to 73920 via altIds — Surging Totem hero path fires different spell ID

feat(casttracker): altIdMap built at COMBAT_START; ABILITY_USED and pre-combat replay resolve alt IDs to primary tracking slot

fix(verify): alt IDs count as PASS for primary spell; excluded from OTHER SPELLS; PASS note shows via alt id=X

feat(shaman): Wind Shear (57994) isInterrupt, Purify Spirit (77130) isUtility — Resto Shaman

fix(feedback): remove Atonement-value language from generic healer low-activity note

feat(core): /ms debug auras — dumps active player buff IDs for aura ID discovery

chore: version bump 1.4.11 → 1.4.12
```
