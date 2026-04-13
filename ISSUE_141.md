# Issues — Midnight Sensei v1.4.1

---

## ISSUE_warrior_spec_db_141.md

**Title:** [Bug] Warrior Spec DB Out of Sync with Midnight 12.0 — All Three Specs
**Labels:** `bug` `spec-db` `warrior` `midnight-12.0` `fixed-in-1.4.1`
**Fixed in:** v1.4.1

### Summary
All three Warrior specs contained wrong spell IDs, removed abilities, and missing core spells. Verified against live Midnight 12.0 spell snapshots and full talent tree exports with the PASSIVE column.

### Arms

| Change | Detail |
|---|---|
| Bladestorm `227847` removed | Present in Fury spell list — not in Arms talent tree |
| Warbreaker `262161` removed | Not in Arms talent tree or spell list |
| Ravager `228920` added talentGated CD | nodeID 90441 non-PASSIVE ACTIVE |
| Demolish `436358` added talentGated CD | nodeID 94818 non-PASSIVE ACTIVE |
| Colossus Smash `167105` added rotational | nodeID 90290 non-PASSIVE ACTIVE |
| Overpower `7384` added rotational | nodeID 90271 non-PASSIVE ACTIVE |
| Rend `772` added rotational | nodeID 109391 non-PASSIVE ACTIVE |

### Fury

| Change | Detail |
|---|---|
| Onslaught `315720` removed | Not in Fury talent tree or spell list |
| Avatar `107574` added CD | nodeID 90415 non-PASSIVE ACTIVE — was missing entirely |
| Odyn's Fury `385059` added talentGated CD | nodeID 110203 non-PASSIVE ACTIVE |
| Demolish `436358` added talentGated CD | nodeID 94818 non-PASSIVE ACTIVE |
| Raging Blow `85288` added rotational | nodeID 90396 non-PASSIVE ACTIVE |
| Berserker Stance `386196` added rotational | nodeID 90325 non-PASSIVE ACTIVE |
| Enrage `184362` VERIFY flag retained | Spell list shows `184361`; confirm which ID is the self-buff aura |

### Protection

| Change | Detail |
|---|---|
| Last Stand `12975` removed | Confirmed PASSIVE nodeID 107575 |
| Demoralizing Shout `1160` added CD | nodeID 90305 non-PASSIVE ACTIVE |
| Demolish `436358` added talentGated CD | nodeID 94818 non-PASSIVE ACTIVE |
| Disrupting Shout `386071` added isInterrupt | nodeID 107579 non-PASSIVE ACTIVE |
| Revenge `6572` added rotational | nodeID 90298 non-PASSIVE ACTIVE — core Rage spender was missing |

---

## ISSUE_hunter_spec_db_141.md

**Title:** [Bug] Hunter Spec DB Out of Sync with Midnight 12.0 — All Three Specs
**Labels:** `bug` `spec-db` `hunter` `midnight-12.0` `fixed-in-1.4.1`
**Fixed in:** v1.4.1

### Summary
All three Hunter specs contained removed abilities, wrong spec-variant IDs, unconfirmed proc buffs, and missing core spells.

### Beast Mastery

| Change | Detail |
|---|---|
| Call of the Wild `359844` removed | Not in BM talent tree or spell list |
| Thrill of the Hunt `246152` removed procBuff | Not in talent tree or spell list; talent `1265051` is PASSIVE INACTIVE |
| Counter Shot `147362` added isInterrupt | nodeID 102292 non-PASSIVE ACTIVE |
| Cobra Shot `193455` added rotational | nodeID 102354 non-PASSIVE ACTIVE — Focus dump/filler missing entirely |
| Black Arrow `466930` added talentGated rotational | nodeID 109961 non-PASSIVE ACTIVE; new Midnight 12.0 ability |
| Wild Thrash `1264359` added talentGated rotational | nodeID 102363 non-PASSIVE ACTIVE |

### Marksmanship

| Change | Detail |
|---|---|
| Precise Shots `342776` removed procBuff | Not in MM talent tree or spell list |
| Counter Shot `147362` added isInterrupt | nodeID 102402 non-PASSIVE ACTIVE |
| Arcane Shot `185358` added rotational | Baseline confirmed spell list — primary Focus spender missing entirely |

### Survival

| Change | Detail |
|---|---|
| Coordinated Assault `360952` removed | Not in Survival talent tree or spell list |
| Kill Command `34026` → `259489` | `34026` is BM spec-variant; `259489` nodeID 102255 is Survival spec-variant |
| Mongoose Bite `259387` removed | Not in Survival talent tree or spell list |
| Muzzle `187707` added isInterrupt | nodeID 79837 non-PASSIVE ACTIVE |
| Raptor Strike `186270` added rotational | nodeID 102262 non-PASSIVE ACTIVE |
| Takedown `1250646` added talentGated rotational | nodeID 109323 non-PASSIVE ACTIVE |
| Boomstick `1261193` added talentGated rotational | nodeID 109324 non-PASSIVE ACTIVE |

---

## ISSUE_priest_spec_db_141.md

**Title:** [Bug] Priest Spec DB Out of Sync with Midnight 12.0 — Discipline and Holy
**Labels:** `bug` `spec-db` `priest` `midnight-12.0` `fixed-in-1.4.1`
**Fixed in:** v1.4.1

### Summary
Discipline and Holy contained multiple wrong IDs, removed abilities, and missing core rotational spells. Shadow was clean — all IDs confirmed against the 114-node snapshot with no changes required.

### Discipline

| Change | Detail |
|---|---|
| Power Word: Barrier `62618` removed | Not in Discipline talent tree or spell list |
| Evangelism `246287` → `472433` | nodeID 82577 non-PASSIVE ACTIVE |
| Rapture `47536` removed | Not in Discipline talent tree or spell list |
| Schism `204263` removed | Not in Discipline talent tree or spell list |
| Atonement `194384` removed uptimeBuffs | Applied to party members not self — not trackable as player aura |
| Power Infusion `10060` added CD | nodeID 82556 non-PASSIVE ACTIVE |
| Penance `47540` added rotational | Baseline confirmed spell list — primary cast was missing |
| Power Word: Radiance `194509` added rotational | nodeID 82593 non-PASSIVE ACTIVE |
| Mind Blast `8092` added rotational | nodeID 82713 non-PASSIVE ACTIVE |
| Shadow Word: Death `32379` added rotational | nodeID 82712 non-PASSIVE ACTIVE |

### Holy

| Change | Detail |
|---|---|
| Prayer of Mending `33076` → `17` | `33076` is the Discipline spec-variant; `17` confirmed in Holy spell list |
| Power Infusion `10060` added CD | nodeID 82556 non-PASSIVE ACTIVE |
| Guardian Spirit `47788` added CD | nodeID 82637 non-PASSIVE ACTIVE — was missing entirely |
| Holy Word: Serenity `2050` added rotational | nodeID 82638 non-PASSIVE ACTIVE |
| Holy Word: Sanctify `34861` added rotational | nodeID 82631 non-PASSIVE ACTIVE |
| Holy Fire `14914` added rotational | nodeID 108730 non-PASSIVE ACTIVE; reduces Holy Word CDs |
| Halo `120517` added talentGated rotational | nodeID 108724 non-PASSIVE ACTIVE |

### Shadow
No changes — full PASSIVE audit confirmed all IDs against 114-node snapshot.
