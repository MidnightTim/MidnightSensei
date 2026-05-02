# Commit Notes — v1.5.9

**Date:** April 29, 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.5.9

## Summary

Archon.gg adopted as primary rotation and talent source. Corrects all three Rogue primary builder IDs (1752 was wrong for Backstab, Mutilate, and Sinister Strike), fixes Envenom/Dispatch/Rupture IDs, adds missing abilities across Assassination and Subtlety, and fills rotation gaps across all three Death Knight specs.

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bump 1.5.8 → 1.5.9 |
| `Core.lua` | Version bump + CHANGELOG entry for 1.5.9; Archon.gg added to CREDITS |
| `Specs/Rogue.lua` | Assassination: Mutilate/Envenom/Rupture ID fixes, Fan of Knives added, Ambush added; Outlaw: Sinister Strike/Dispatch ID fixes; Subtlety: Backstab ID fix, Secret Technique + Black Powder added |
| `Specs/DeathKnight.lua` | Unholy: Festering Scythe moved to rotational, Epidemic/Necrotic Coil/Death Strike/Death and Decay added; Frost: Remorseless Winter/Frostbane/Glacial Advance added; Blood: Icebound Fortitude/Anti-Magic Shell/Death and Decay added |

## Commits

```
fix(rogue): Mutilate ID 1752 → 1329 with altIds={5374,27576} — MH+OH hit IDs confirmed in session log
fix(rogue): Envenom ID 196819 → 32645 with altIds={276245} — session log confirmed
fix(rogue): Rupture ID 1943 → 199672 — Assassination spec-variant confirmed in session log
feat(rogue): Fan of Knives (51723) added to Assassination rotational
feat(rogue): Ambush (8676) added to Assassination as isUtility talentGated — stealth opener
fix(rogue): Sinister Strike ID 1752 → 193315 — Outlaw session log confirmed
fix(rogue): Dispatch ID 196819 → 2098 — Outlaw session log confirmed; prior correction was wrong
fix(rogue): Backstab ID 1752 → 53 — Subtlety session log confirmed
feat(rogue): Secret Technique (280719) added to Subtlety majorCooldowns talentGated
feat(rogue): Black Powder (319175) added to Subtlety rotational — baseline AoE finisher
fix(dk): Festering Scythe moved from majorCooldowns to rotational — confirmed not a CD
feat(dk): Epidemic (207317) added to Unholy rotational — baseline AoE RP spender
feat(dk): Necrotic Coil (1242174) added to Unholy rotational talentGated — Forbidden Knowledge
feat(dk): Death Strike + Death and Decay added to Unholy rotational talentGated
feat(dk): Remorseless Winter (196771) added to Frost rotational — session log x39
feat(dk): Frostbane (1228433) added to Frost rotational talentGated — altIds={1228436}
feat(dk): Glacial Advance (194913) added to Frost rotational talentGated
feat(dk): Icebound Fortitude (48792) + Anti-Magic Shell (48707) added to Blood majorCooldowns healerConditional
feat(dk): Death and Decay added to Blood rotational talentGated
feat(credits): Archon.gg added as primary rotation and talent build reference
chore: version bump 1.5.8 → 1.5.9
```
