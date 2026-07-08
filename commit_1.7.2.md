# Commit Notes - v1.7.2
**Date:** 07/07/2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.7.2

## Summary

Fixes two Elemental Shaman tracking bugs. Earth Shock is now suppressed when Elemental Blast is talented, stopping false "never used" feedback. Tempest (id 452201) is registered as a Lightning Bolt alt ID so Maelstrom proc casts are credited correctly in rotation tracking.

## Changed Files

- `MidnightSensei.toc` - version bump to 1.7.2
- `Core.lua` - version fallback updated to "1.7.2"; Core.CHANGELOG entry added for 1.7.2
- `Specs/Shaman.lua` - Elemental: Earth Shock suppressIfTalent=117014 added; Lightning Bolt altIds={452201} added

## Commits

```
fix(specs): Elemental Shaman - Earth Shock suppressIfTalent=117014 (Elemental Blast)

fix(specs): Elemental Shaman - Tempest (452201) altId on Lightning Bolt for Maelstrom proc casts
```
