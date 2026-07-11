# Commit Notes - v1.7.3
**Date:** 07/07/2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.7.3

## Summary

Fixes Enhancement Shaman Doom Winds being tracked when Ascendance is talented. Ascendance fully replaces Doom Winds on the action bar and is a choice node - Doom Winds is now suppressed when Ascendance is taken.

## Changed Files

- `MidnightSensei.toc` - version bump to 1.7.3
- `Core.lua` - version fallback updated to "1.7.3"; Core.CHANGELOG entry added for 1.7.3
- `Specs/Shaman.lua` - Enhancement: Doom Winds suppressIfTalent=114051 (Ascendance) added; stale comment about Ascendance corrected

## Commits

```
fix(specs): Enhancement Shaman - Doom Winds suppressIfTalent=114051 (Ascendance choice node)
```
