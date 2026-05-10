# Commit — Midnight Sensei v1.6.4

**Date:** 05/10/2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.6.4

## Summary

Spec DB catch-up from v3.3 Archon audit review: four enhancements across MM Hunter, Assassination Rogue, Holy Paladin, and Restoration Shaman. Primary fix eliminates false Kill Shot penalty for Dark Ranger MM Hunters. Remaining additions cover three untracked cooldowns and one hero talent replacement pair.

## Changed Files

- `MidnightSensei.toc` — Version bump 1.6.3 → 1.6.4
- `Core.lua` — Fallback version string + CHANGELOG entry
- `Specs/Hunter.lua` — MM: Kill Shot suppressIfTalent=94987; Black Arrow talentGated rotational
- `Specs/Rogue.lua` — Assassination: Thistle Tea talentGated majorCooldown
- `Specs/Paladin.lua` — Holy: Beacon of Faith + Beacon of Virtue healerConditional choice-node pair
- `Specs/Shaman.lua` — Restoration: Nature's Swiftness talentGated + suppressIfTalent=443454; Ancestral Swiftness talentGated

## Commits

```
feat(hunter): suppress Kill Shot for Dark Ranger MM Hunters; add Black Arrow talentGated rotational

feat(rogue): add Thistle Tea as talentGated majorCooldown for Assassination

feat(paladin): add Beacon of Faith and Beacon of Virtue as healerConditional choice-node pair for Holy

feat(shaman): add Nature's Swiftness and Ancestral Swiftness (Farseer) for Restoration

chore: version bump 1.6.3 → 1.6.4 (TOC + Core.lua fallback)
```
