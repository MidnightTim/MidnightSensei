# Commit — Midnight Sensei v1.4.1

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Branch:** main
**Tag:** v1.4.1

---

## Summary

Spec database audit for Warrior (3 specs), Hunter (3 specs), and Priest (3 specs). All nine specs verified against live Midnight 12.0 spell snapshots and full talent tree exports with the PASSIVE column. Recurring findings: wrong spec-variant IDs, removed abilities left in the DB, missing core rotational spells.

---

## Changed Files

- `Core.lua` — version 1.4.1, changelog, Warrior/Hunter/Priest spec DB changes

---

## Commits

### chore: bump version to 1.4.1, add changelog entry

### fix(spec-db/warrior/arms): Bladestorm/Warbreaker removed, Ravager/Demolish/Colossus Smash/Overpower/Rend added
- Bladestorm `227847` removed — Fury-only; not in Arms talent tree
- Warbreaker `262161` removed — not in Arms talent tree or spell list
- Ravager `228920` added talentGated CD — nodeID 90441
- Demolish `436358` added talentGated CD — nodeID 94818
- Colossus Smash `167105` added rotational — nodeID 90290
- Overpower `7384` added rotational — nodeID 90271
- Rend `772` added rotational — nodeID 109391

### fix(spec-db/warrior/fury): Onslaught removed, Avatar/Odyn's Fury/Demolish/Raging Blow/Berserker Stance added
- Onslaught `315720` removed — not in Fury talent tree or spell list
- Avatar `107574` added CD — nodeID 90415
- Odyn's Fury `385059` added talentGated CD — nodeID 110203
- Demolish `436358` added talentGated CD — nodeID 94818
- Raging Blow `85288` added rotational — nodeID 90396
- Berserker Stance `386196` added rotational — nodeID 90325
- Enrage `184362` retained with VERIFY flag

### fix(spec-db/warrior/protection): Last Stand removed, Demoralizing Shout/Demolish/Disrupting Shout/Revenge added
- Last Stand `12975` removed — confirmed PASSIVE nodeID 107575
- Demoralizing Shout `1160` added CD — nodeID 90305
- Demolish `436358` added talentGated CD — nodeID 94818
- Disrupting Shout `386071` added isInterrupt — nodeID 107579
- Revenge `6572` added rotational — nodeID 90298

### fix(spec-db/hunter/bm): Call of the Wild/Thrill of the Hunt removed, Counter Shot/Cobra Shot/Black Arrow/Wild Thrash added
- Call of the Wild `359844` removed — not in BM talent tree or spell list
- Thrill of the Hunt `246152` removed from procBuffs — not in talent tree or spell list
- Counter Shot `147362` added isInterrupt — nodeID 102292
- Cobra Shot `193455` added rotational — nodeID 102354; Focus dump was missing entirely
- Black Arrow `466930` added talentGated rotational — nodeID 109961
- Wild Thrash `1264359` added talentGated rotational — nodeID 102363

### fix(spec-db/hunter/mm): Precise Shots removed, Counter Shot/Arcane Shot added
- Precise Shots `342776` removed from procBuffs — not in MM talent tree or spell list
- Counter Shot `147362` added isInterrupt — nodeID 102402
- Arcane Shot `185358` added rotational — baseline spell list; primary Focus spender was missing entirely

### fix(spec-db/hunter/survival): Coordinated Assault removed, Kill Command corrected, Mongoose Bite removed, Muzzle/Raptor Strike/Takedown/Boomstick added
- Coordinated Assault `360952` removed — not in Survival talent tree or spell list
- Kill Command `34026` → `259489` — was BM spec-variant; `259489` is nodeID 102255 Survival spec-variant
- Mongoose Bite `259387` removed — not in Survival talent tree or spell list
- Muzzle `187707` added isInterrupt — nodeID 79837
- Raptor Strike `186270` added rotational — nodeID 102262
- Takedown `1250646` added talentGated rotational — nodeID 109323
- Boomstick `1261193` added talentGated rotational — nodeID 109324

### fix(spec-db/priest/discipline): Multiple wrong/removed IDs cleaned, rotational spells added
- Power Word: Barrier `62618` removed — not in Discipline talent tree or spell list
- Evangelism `246287` → `472433` — nodeID 82577
- Rapture `47536` removed — not in talent tree or spell list
- Schism `204263` removed — not in talent tree or spell list
- Atonement `194384` removed from uptimeBuffs — applied to others, not self
- Power Infusion `10060` added CD — nodeID 82556
- Penance `47540` added rotational — baseline; primary cast was missing entirely
- Power Word: Radiance `194509` added rotational — nodeID 82593
- Mind Blast `8092` added rotational — nodeID 82713
- Shadow Word: Death `32379` added rotational — nodeID 82712

### fix(spec-db/priest/holy): Prayer of Mending corrected, Guardian Spirit/Power Infusion added, Holy Words/Holy Fire/Halo added to rotational
- Prayer of Mending `33076` → `17` — `33076` is Disc spec-variant; `17` confirmed Holy spell list
- Power Infusion `10060` added CD — nodeID 82556
- Guardian Spirit `47788` added CD — nodeID 82637; was missing entirely
- Holy Word: Serenity `2050` added rotational — nodeID 82638
- Holy Word: Sanctify `34861` added rotational — nodeID 82631
- Holy Fire `14914` added rotational — nodeID 108730; Holy Word CDR mechanic
- Halo `120517` added talentGated rotational — nodeID 108724

### fix(spec-db/priest/shadow): PASSIVE audit — no changes required
All IDs confirmed non-PASSIVE or baseline against 114-node Shadow talent snapshot. Source note updated.
