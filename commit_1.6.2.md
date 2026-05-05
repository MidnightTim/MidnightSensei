# Commit — Midnight Sensei v1.6.2

**Date:** May 4, 2026
**Author:** Midnight - Thrall (US)
**Tag:** v1.6.2

---

## Summary

Spec DB May 2026 audit pass. Six new tracked abilities across Warrior, Priest, and Death Knight. Twelve alt ID corrections across seven specs resolve detection gaps where the game fires a different spell ID under certain talents or hero paths. Spec count corrected 39 → 40 (Devourer confirmed as third DH spec).

---

## Changed Files

| File | Description |
|---|---|
| `MidnightSensei.toc` | Version bump 1.6.1 → 1.6.2 |
| `Core.lua` | Version fallback bump; 1.6.2 changelog entry |
| `Specs/Warrior.lua` | Rallying Cry (all 3 specs); Enraged Regeneration (Fury); Shockwave (Protection) |
| `Specs/Priest.lua` | Void Shield + Shadow Word: Pain added to Discipline rotational |
| `Specs/DeathKnight.lua` | Gauntlet's Grasp (Blood); Killing Machine + Rime altIds (Frost) |
| `Specs/Hunter.lua` | 4 altId corrections (Marksmanship + Survival) |
| `Specs/Mage.lua` | Arcane Barrage altId |
| `Specs/Shaman.lua` | Earthquake altIds; Chain Lightning added to Enhancement rotational |
| `Specs/Warlock.lua` | Incinerate altId |
| `Specs/Evoker.lua` | Breath of Eons altId (Augmentation) |
| `Specs/Druid.lua` | Frantic Frenzy + Maul altIds |
| `Specs/Paladin.lua` | Art of War VERIFY comment closed |
| `UI.lua` | Spec count 39 → 40 |
| `README.md` | Spec count 39 → 40 |
| `AUDIT_DELTA_LOG.md` | 05/04/2026 session entry appended |
| `AUDIT_ID_MANIFEST.md` | Regenerated — 40 specs, 526 IDs |
| `Tools/audit_agent_template.md` | Step 1 updated: agents now read delta log before fetching |

---

## Commits

```
feat(specs): Warrior — Rallying Cry all 3 specs, Enraged Regen (Fury), Shockwave (Prot)

feat(specs): Priest Discipline — Void Shield + Shadow Word: Pain added to rotational

feat(specs): Blood DK — Gauntlet's Grasp as talentGated CD (Rider hero talent)

feat(specs): Frost DK — Killing Machine + Rime procBuff altIds added

feat(specs): alt ID corrections across Hunter, Mage, Shaman, Warlock, Evoker, Druid

fix(ui): spec count corrected 39 → 40 (Devourer confirmed as 3rd DH spec)

chore(audit): delta log agent template requires reading delta log before fetch

chore: version bump 1.6.1 → 1.6.2
```
