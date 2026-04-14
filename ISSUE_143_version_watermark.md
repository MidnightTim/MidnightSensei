[Feature] Version Watermark on Fight Complete Window

**Labels:** `feature` `ux` `fixed-in-1.4.3`
**Fixed in:** v1.4.3

## Summary
No way to tell which addon version a player was running when they received a specific piece of feedback — required asking during every support interaction.

## Changes

**`UI.lua`**
- Version label added to Fight Complete frame at `BOTTOMRIGHT, -88, 34` — above the button row, clear of the scrollbar arrow
- 8pt font, `TEXT_DIM` colour, 50% alpha — readable but unobtrusive
- Stored as `resultFrame._verLabel` so `ShowResultPanel` can update it per-result
- Reads from `result.addonVersion` (the version that generated that feedback), not the live `Core.VERSION`
- Pre-1.4.3 encounters without a stored version fall back to `Core.VERSION`

**`Analytics.lua`**
- `addonVersion = Core.VERSION` added to the result struct in `CalculateGrade`
- Stored permanently with every encounter going forward
- Survives the 200-encounter cap rollover alongside the other result fields

## Positioning Note
Initial placement at `BOTTOMRIGHT, -12, 34` was obscured by the `UIPanelScrollFrameTemplate` scrollbar down-arrow. Corrected to `BOTTOMRIGHT, -88, 34` which clears the scrollbar and sits in the open gap between the Leaderboard and Close buttons.
