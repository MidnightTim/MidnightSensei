# Commit Notes — v1.5.7

**Date:** April 27, 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.5.7

## Summary

Fixes Brewmaster Monk cast tracking (Blackout Kick alt ID 205523, Expel Harm added, Rushing Jade Wind as optional), corrects a verify report accumulation bug where spell counts persisted across multiple fights, adds verify history auto-save and a side-by-side compare window, and fixes the weekly reset announcement firing a day early for US players due to a 14-hour offset error in GetWeekBucket().

## Changed Files

| File | Change |
|---|---|
| `MidnightSensei.toc` | Version bump 1.5.6 → 1.5.7 |
| `Core.lua` | Version bump + CHANGELOG entry for 1.5.7; VerifySeenSpells/VerifySeenAuras reset on COMBAT_START; Core.BuildVerifyReportLines() extracted; Core.SaveVerifySnapshot() + COMBAT_END auto-save; CharDB.verifyHistory init; weekly RESET_OFFSET corrected |
| `Specs/Monk.lua` | Blackout Kick altIds={205523} on Brewmaster + Windwalker; Expel Harm (322101) added to Brewmaster rotational; Rushing Jade Wind (116847) added to Brewmaster majorCooldowns as isUtility talentGated altIds={148187} |
| `UI.lua` | UI.ShowVerifyCompare() added; Compare button added to verifyExportFrame; verify report window auto-closes on compare open |

## Commits

```
fix(monk): Blackout Kick alt ID 205523 — combat cast fires different ID in Midnight 12.0 (Brewmaster + Windwalker)
feat(monk): Expel Harm (322101) added to Brewmaster rotational — 5s CD, consumes Gift of the Ox spheres
feat(monk): Rushing Jade Wind added as isUtility talentGated — tracked not scored; alt ID 148187
fix(verify): VerifySeenSpells reset on COMBAT_START — was accumulating across multiple fights
feat(verify): fight history auto-save to CharDB.verifyHistory on COMBAT_END (cap 20)
feat(verify): side-by-side compare window with snapshot selector and fight numbering
refactor(verify): BuildVerifyReportLines extracted from slash handler for reuse
fix(weekly): RESET_OFFSET corrected to Tue 14:00 UTC — was firing reset announcement on Monday for US players
chore: version bump 1.5.6 → 1.5.7
```
