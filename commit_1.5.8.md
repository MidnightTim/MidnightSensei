# Commit Notes — v1.5.8

**Date:** April 29, 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.5.8

## Summary

Corrects Protection Paladin rotational tracking based on live session log data: removes Holy Shock (never pressed in combat), adds alt ID 204019 to Blessed Hammer (combat cast ID divergence), adds three missing rotational spells (Judgment, Hammer of Wrath, Word of Glory), and adds Templar Hero Spec entries for Hammer of Light and Divine Hammer as informational isUtility entries.

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bump 1.5.7 → 1.5.8 |
| `Core.lua` | Version bump + CHANGELOG entry for 1.5.8 |
| `Specs/Paladin.lua` | Prot: Holy Shock removed; Blessed Hammer altIds={204019}; Judgment + Hammer of Wrath + Word of Glory added to rotational; Hammer of Light + Divine Hammer added as isUtility talentGated (Templar Hero Spec) |

## Commits

```
fix(paladin): remove Holy Shock (20473) from Prot rotational — NOT SEEN in combat; not part of active Protection rotation
fix(paladin): Blessed Hammer alt ID 204019 — combat cast fires 204019, spellbook ID 35395 never seen in UNIT_SPELLCAST_SUCCEEDED
feat(paladin): Judgment (275779) added to Prot rotational — Holy Power generator; x33 per fight in session log
feat(paladin): Hammer of Wrath (1241413) added to Prot rotational talentGated — execute/AW window; x19 per fight
feat(paladin): Word of Glory (85673) added to Prot rotational talentGated — HP spender heal; x2 per fight
feat(paladin): Hammer of Light (427453) added as isUtility talentGated — Templar Hero Spec Light's Guidance proc window
feat(paladin): Divine Hammer (198137) added as isUtility talentGated — Templar Hero Spec passive proc from Divine Toll
chore: version bump 1.5.7 → 1.5.8
```
