# [Enhancement] Vengeance Demon Hunter missing spell coverage

## Summary

Multiple Vengeance DH spells confirmed firing via `/ms verify` but not tracked:

| Spell | ID(s) | Count | Issue |
|---|---|---|---|
| Immolation Aura | 258920 | x5 | In validSpells but not rotational |
| Demon Spikes | 203720 | — | Only in uptimeBuffs; cast usage unscored |
| Fracture | 225919, 263642, 225921 | x15 each | Previously removed; three variant IDs |
| Infernal Strike | 189110 | x5 | Not tracked at all |
| Felblade | 213243 | x4 | Spec-variant ID; primary 232893 already tracked |

## Fix

- `Specs/DemonHunter.lua` Vengeance spec:
  - Immolation Aura (258920) added to `rotationalSpells`
  - Demon Spikes (203720) added to `majorCooldowns` — cast usage now scored; `uptimeBuffs` entry retained for physical mitigation uptime scoring
  - Fracture added to `rotationalSpells` with primary id=225919 and `altIds = {263642, 225921}`
  - Infernal Strike (189110) added to `rotationalSpells`
  - Felblade (232893) gains `altIds = {213243}` for spec-variant ID
  - All new IDs added to `validSpells` whitelist
