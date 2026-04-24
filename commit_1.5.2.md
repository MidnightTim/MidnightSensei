# Commit Notes – MidnightSensei v1.5.2

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.5.2

## Summary

Bug fixes for Unholy DK Festering Strike ID, Ret Paladin Divine Storm single-target penalisation, Ret Paladin Avenging Wrath with Radiant Glory, and tank mitigation feedback referencing wrong ability names.

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bump to 1.5.2 |
| `Core.lua` | Version 1.5.2; CHANGELOG |
| `Specs/DeathKnight.lua` | Unholy: Festering Strike 316239 → 85948 primary, altIds={316239} |
| `Specs/Paladin.lua` | Ret: Divine Storm → majorCooldowns isUtility; Avenging Wrath suppressIfTalent=458359 |
| `Analytics/Feedback.lua` | Spec-aware mitigation ability lookup; Protection Warrior/Paladin distinguished by className |

## Commits

```
fix(dk): Unholy Festering Strike corrected to id=85948 — 316239 never fires UNIT_SPELLCAST_SUCCEEDED
fix(paladin): Divine Storm reclassified as isUtility — no longer penalised in single-target
fix(paladin): Avenging Wrath suppressIfTalent=458359 — suppressed when Radiant Glory is talented
fix(feedback): tank mitigation hint now references correct ability per spec
chore: v1.5.2 CHANGELOG
```
