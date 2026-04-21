# Commit Notes – MidnightSensei v1.4.14

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.4.14

## Summary

Spell coverage pass for Frost Mage and Vengeance Demon Hunter. Multiple abilities confirmed firing via /ms verify were missing or only partially tracked. Fracture uses the altIds pattern to consolidate three variant IDs into one rotational entry.

## Changed Files

| File | Change |
|---|---|
| `Specs/Mage.lua` | Frost: Mirror Image CD, Supernova rotational, Frostbolt altIds={228597} |
| `Specs/DemonHunter.lua` | Vengeance: Immolation Aura + Fracture + Infernal Strike rotational; Demon Spikes in majorCooldowns; Felblade altIds={213243}; validSpells updated |
| `Core.lua` | Version 1.4.14; CHANGELOG entry |
| `MidnightSensei.toc` | Version bump to 1.4.14 |

## Commits

```
feat(mage): Frost — Mirror Image CD, Supernova rotational, Frostbolt alt ID 228597

feat(dh): Vengeance — Fracture (3 variant IDs), Infernal Strike, Immolation Aura rotational;
Demon Spikes in majorCooldowns; Felblade altIds={213243}; validSpells updated

chore: v1.4.14 — bump TOC, Core.VERSION, CHANGELOG
```
