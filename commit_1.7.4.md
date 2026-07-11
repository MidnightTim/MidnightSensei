# Commit Notes - v1.7.4
**Date:** 07/11/2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.7.4

## Summary

Adds Ascendance (114051) tracking for Enhancement Shaman. Ascendance is a 2-minute major cooldown that shares a choice node with Doom Winds. Players who talent Ascendance now receive cooldown usage feedback. Spell ID and fire event confirmed in-game via tooltip debug.

## Changed Files

- `MidnightSensei.toc` - version bump to 1.7.4
- `Core.lua` - version fallback updated to "1.7.4"; Core.CHANGELOG entry added for 1.7.4
- `Specs/Shaman.lua` - Enhancement: Ascendance (114051) added to majorCooldowns as talentGated; stale VERIFY comment removed

## Commits

```
feat(specs): Enhancement Shaman - Ascendance (114051) added to majorCooldowns as talentGated 2 min CD
```
