# Midnight Sensei v1.4.1 — Class Tuning: Warrior, Hunter, Priest

## Overview

1.4.1 continues the class tuning and refinement phase begun in 1.4.0. Three class families audited this release: Warrior (all three specs), Hunter (all three specs), and Priest (all three specs). All nine specs verified against live Midnight 12.0 spell snapshots and full talent tree exports with the PASSIVE column.

The recurring theme across all three classes is the same as 1.4.0: **wrong spec-variant IDs** (spells that share a name but have different IDs per spec), **removed abilities** that were not cleaned up when Midnight 12.0 launched, and **missing core rotational spells** that were never tracked at all.

---

## Spec DB Changes by Class

### Warrior

**Arms**
- Bladestorm `227847` removed — present in the Fury spell list, not in the Arms talent tree at all
- Warbreaker `262161` removed — not in the Arms talent tree or spell list
- Ravager `228920` added as talentGated CD — nodeID 90441 non-PASSIVE ACTIVE
- Demolish `436358` added as talentGated CD — nodeID 94818 non-PASSIVE ACTIVE
- Colossus Smash `167105` added to rotational — nodeID 90290 non-PASSIVE ACTIVE; primary debuff window opener
- Overpower `7384` added to rotational — nodeID 90271 non-PASSIVE ACTIVE
- Rend `772` added to rotational — nodeID 109391 non-PASSIVE ACTIVE

**Fury**
- Onslaught `315720` removed — not in Fury talent tree or spell list
- Avatar `107574` added to majorCooldowns — nodeID 90415 non-PASSIVE ACTIVE; was missing entirely
- Odyn's Fury `385059` added as talentGated CD — nodeID 110203 non-PASSIVE ACTIVE
- Demolish `436358` added as talentGated CD — nodeID 94818 non-PASSIVE ACTIVE
- Raging Blow `85288` added to rotational — nodeID 90396 non-PASSIVE ACTIVE; core filler
- Berserker Stance `386196` added to rotational — nodeID 90325 non-PASSIVE ACTIVE
- Enrage uptime `184362` retained with VERIFY flag (spell list shows `184361`; may be the enhanced proc aura)

**Protection**
- Last Stand `12975` removed — confirmed PASSIVE at nodeID 107575 (`1243659` Last Stand is PASSIVE INACTIVE)
- Demoralizing Shout `1160` added to majorCooldowns — nodeID 90305 non-PASSIVE ACTIVE; group damage reduction
- Demolish `436358` added as talentGated CD — nodeID 94818 non-PASSIVE ACTIVE
- Disrupting Shout `386071` added as `isInterrupt` — nodeID 107579 non-PASSIVE ACTIVE
- Revenge `6572` added to rotational — nodeID 90298 non-PASSIVE ACTIVE; core Rage spender was missing

---

### Hunter

**Beast Mastery**
- Call of the Wild `359844` removed — not in BM talent tree or spell list
- Thrill of the Hunt `246152` removed from procBuffs — not in talent tree or spell list (talent `1265051` exists but is PASSIVE INACTIVE)
- Counter Shot `147362` added as `isInterrupt` — nodeID 102292 non-PASSIVE ACTIVE
- Cobra Shot `193455` added to rotational — nodeID 102354 non-PASSIVE ACTIVE; primary Focus dump/filler was missing entirely
- Black Arrow `466930` added as talentGated rotational — nodeID 109961 non-PASSIVE ACTIVE; new Midnight 12.0 ability
- Wild Thrash `1264359` added as talentGated rotational — nodeID 102363 non-PASSIVE ACTIVE

**Marksmanship**
- Precise Shots `342776` removed from procBuffs — not in MM talent tree or spell list
- Counter Shot `147362` added as `isInterrupt` — nodeID 102402 non-PASSIVE ACTIVE
- Arcane Shot `185358` added to rotational — baseline confirmed spell list; the primary Focus spender was missing entirely

**Survival**
- Coordinated Assault `360952` removed — not in Survival talent tree or spell list
- Kill Command corrected `34026` → `259489` — `34026` is the BM spec-variant; `259489` is nodeID 102255 Survival spec-variant
- Mongoose Bite `259387` removed — not in Survival talent tree or spell list
- Muzzle `187707` added as `isInterrupt` — nodeID 79837 non-PASSIVE ACTIVE; confirmed spell list
- Raptor Strike `186270` added to rotational — nodeID 102262 non-PASSIVE ACTIVE
- Takedown `1250646` added as talentGated rotational — nodeID 109323 non-PASSIVE ACTIVE
- Boomstick `1261193` added as talentGated rotational — nodeID 109324 non-PASSIVE ACTIVE

Note: Flamefang Pitch `1251592` (nodeID 102252) is non-PASSIVE but INACTIVE in this build — not tracked. Add when confirmed ACTIVE.

---

### Priest

**Discipline**
- Power Word: Barrier `62618` removed — not in Discipline talent tree or spell list
- Evangelism ID corrected `246287` → `472433` — nodeID 82577 non-PASSIVE ACTIVE
- Rapture `47536` removed — not in Discipline talent tree or spell list
- Schism `204263` removed — not in Discipline talent tree or spell list
- Atonement `194384` removed from uptimeBuffs — applied to party members, not self; not in tree or spell list
- Power Infusion `10060` added to majorCooldowns — nodeID 82556 non-PASSIVE ACTIVE
- Penance `47540` added to rotational — baseline confirmed spell list; primary damage/heal cast was missing
- Power Word: Radiance `194509` added to rotational — nodeID 82593 non-PASSIVE ACTIVE; AoE Atonement applicator
- Mind Blast `8092` added to rotational — nodeID 82713 non-PASSIVE ACTIVE
- Shadow Word: Death `32379` added to rotational — nodeID 82712 non-PASSIVE ACTIVE

**Holy**
- Prayer of Mending corrected `33076` → `17` — `33076` is the Disc spec-variant; `17` is the Holy baseline confirmed in the Holy spell list
- Power Infusion `10060` added to majorCooldowns — nodeID 82556 non-PASSIVE ACTIVE
- Guardian Spirit `47788` added to majorCooldowns — nodeID 82637 non-PASSIVE ACTIVE; was missing entirely
- Holy Word: Serenity `2050` added to rotational — nodeID 82638 non-PASSIVE ACTIVE
- Holy Word: Sanctify `34861` added to rotational — nodeID 82631 non-PASSIVE ACTIVE
- Holy Fire `14914` added to rotational — nodeID 108730 non-PASSIVE ACTIVE; reduces Holy Word cooldowns
- Halo `120517` added as talentGated rotational — nodeID 108724 non-PASSIVE ACTIVE

**Shadow**
- Full PASSIVE audit completed — all IDs confirmed against 114-node snapshot; no changes required

---

## Open VERIFY Items (carry to 1.4.2+)

| Item | Spec | Method |
|---|---|---|
| Enrage aura `184362` vs `184361` | Fury Warrior | In-game — confirm which ID is the self-buff aura |
| Nightfall `108558` | Affliction Warlock | `/ms verify` — C_UnitAuras confirm |
| Furious Gaze `337567` | Havoc DH | `/ms verify` — C_UnitAuras confirm |
| Unbound Chaos `389860` | Havoc DH | `/ms verify` — C_UnitAuras confirm |
| Devastation Evoker resource enum (17) | Devastation | In-game resource enum check |
| Flamefang Pitch `1251592` | Survival Hunter | Confirm ACTIVE in-build before tracking |

---

*Midnight Sensei — Combat performance coaching for all 13 classes*
*Created by Midnight - Thrall (US)*
