# Midnight Sensei v1.4.0 — Class Tuning & Refinement

## Overview

1.4.0 is the first dedicated class tuning release. The entire spec database has been audited against live Midnight 12.0 spell snapshots and full talent tree exports captured using the debug tools added in 1.3.8/1.3.9. Every spec entry across all 13 classes has been verified, with wrong spell IDs corrected, pruned abilities removed, and missing core spells added.

The most significant structural improvement is the **PASSIVE column audit**. The talent snapshot tool now captures all nodes including untalented ones, and flags every passive talent with a `PASSIVE` column. This caught a large number of incorrectly tracked spells — passive talents that grant stat buffs or proc effects rather than castable abilities, which were silently never registering hits via `UNIT_SPELLCAST_SUCCEEDED`. These have all been removed.

---

## Methodology Change — Full Talent Tree Snapshots

The debug talent export (`/ms debug talents`) now captures:
- **All nodes** in the talent tree — ACTIVE (taken) and INACTIVE (not taken)
- **PASSIVE column** — flags every passive talent that should never appear in `majorCooldowns` or `rotationalSpells`
- **entryID** — raw C_Traits entry ID for accurate node identification
- **rank/maxRank** — immediately shows partially-ranked nodes (`1/2`) vs fully-ranked (`2/2`) vs untaken (`0/1`)
- **Summary counts** — header shows `Total: N | ACTIVE: N | INACTIVE: N | PASSIVE: N`

This is the primary tool for future spec DB passes. The workflow is: export on the spec, paste here, diff against spec DB, remove anything with PASSIVE, add anything non-PASSIVE that should be tracked.

---

## New Mechanic — Interrupt Tracking (`isInterrupt`)

Interrupt abilities (e.g. Grimoire: Fel Ravager, Quell) are now tracked but **never penalised**. If an interrupt wasn't used in a fight:

- It does **not** count toward `neverUsed` — no score impact
- A friendly reminder note is appended at the **very bottom** of feedback after all scored items
- The note reads: *"Note: [spell] — this is your interrupt. Not used this fight — no penalty."*

This applies to all specs where an interrupt ability is in `majorCooldowns` with `isInterrupt = true`.

---

## Spec DB Changes by Class

### Warlock

**Affliction**
- Malevolence ID corrected `458355` → `442726` (nodeID 94842)
- Dark Harvest ID corrected `387166` → `1257052` (nodeID 109860)
- Phantom Singularity `205179` and Vile Taint `278350` removed — pruned from Midnight 12.0
- Wither `445468` added as talentGated CD — nodeID 94840 confirmed non-PASSIVE in Affliction tree
- Unstable Affliction `1259790`, Drain Soul `686`, Seed of Corruption `27243` added to rotational
- Drain Soul `388667` removed — confirmed PASSIVE at nodeID 72045; `686` baseline covers tracking
- Nightfall `108558` added to procBuffs (VERIFY C_UnitAuras pending)

**Demonology**
- Diabolic Ritual `428514` removed — confirmed PASSIVE (tooltip and talent snapshot)
- Summon Vilefiend `1251778` removed — confirmed PASSIVE
- Reign of Tyranny `1276748` removed — confirmed PASSIVE
- Doom `460551` removed — confirmed PASSIVE; appears as damage tick, no cast event
- Hand of Gul'dan corrected: `172` (spec-variant baseline that never matched) removed, `105174` (talent cast ID, nodeID 101891) kept
- Grimoire: Fel Ravager marked `isInterrupt = true` — DPS summon + interrupt, not penalised
- Demonbolt `264178` and Dark Harvest `1257052` added to rotational
- Summon Doomguard `1276672` added to majorCooldowns

**Destruction**
- Malevolence corrected `458355` → `442726`
- Havoc `80240` removed — not in Destruction talent tree
- Immolate `348` removed — not in Destruction spell list
- Incinerate corrected `29722` → `686` (spec-variant baseline)
- Diabolic Ritual `428514` removed — confirmed PASSIVE
- Devastation `454735` removed — confirmed PASSIVE
- Conflagrate `17962`, Shadowburn `17877`, Rain of Fire `5740` added to rotational

---

### Demon Hunter

**Havoc**
- Fel Barrage `258925` removed — not in Midnight 12.0
- Chaos Strike corrected `162794` → `344862` (spec-variant confirmed in spell snapshot)
- The Hunt: dual tracking `370965` + `1246167` (both confirmed in spell list)
- Essence Break `258860` and Felblade `232893` added to rotational (non-PASSIVE ACTIVE)
- Furious Gaze `337567` and Unbound Chaos `389860` procBuffs flagged VERIFY

**Vengeance**
- Metamorphosis corrected `187827` → `191427` (confirmed in both spell snapshots)
- Demon Spikes corrected `203819` → `203720` (spell list confirmed)
- Fracture corrected `210152` → `344859` (spec-variant)
- Soul Cleave corrected `228477` → `344862` (spec-variant)
- Soul Barrier `263648` removed — not in Midnight 12.0
- Spirit Bomb `247454` and Felblade `232893` added to rotational
- Sigil of Spite `390163` added to majorCooldowns (non-PASSIVE ACTIVE)

**Devourer**
- PASSIVE audit removed 4 majorCooldowns: Impending Apocalypse `1227707`, Demonsurge `452402`, Midnight `1250094`, Eradicate `1226033`
- Soul Immolation `1241937` retained as the **only majorCooldown** — sole confirmed non-PASSIVE trackable CD
- `471306` and `1221167` (passive talent nodes) removed from validSpells
- Eradicate removed from rotational (PASSIVE)
- scoreWeights adjusted: cooldownUsage 30→25, activity 35→40

**Bug fix**
- Duplicate unclosed stub `[1] = {` in Havoc entry caused the entire Demon Hunter class to be one brace depth too deep, producing a Lua syntax error on load. Corrected.

---

### Shaman

**Elemental**
- Tempest `454009` removed from rotational — confirmed PASSIVE (nodeID 94892)

**Enhancement**
- Feral Spirit `51533`/`469314` removed — confirmed PASSIVE in talent tree
- Ascendance `114051` removed — not in Enhancement talent tree
- Primordial Wave `375982` removed — not in Midnight 12.0
- Maelstrom Weapon procBuff corrected `344179` → `187880` (spell list confirmed)
- Surging Totem `444995` added to majorCooldowns (non-PASSIVE ACTIVE nodeID 94877)
- Crash Lightning `187874`, Lava Lash `60103`, Voltaic Blaze `470057` added to rotational

**Restoration**
- Call of the Ancestors `443450` removed — confirmed PASSIVE (nodeID 94888)

---

### Evoker

**Devastation**
- Pyre `357211` added to rotational — non-PASSIVE ACTIVE nodeID 93334
- Quell `351338` added as `isInterrupt`

**Preservation**
- Emerald Communion `370960` removed — not in Preservation talent tree or spell list
- Tip the Scales corrected `374348` → `370553` (`374348` is Renewing Blaze — wrong spell)
- Time Dilation `357170` added to majorCooldowns
- Temporal Anomaly `373861` and Echo `364343` added to rotational

**Augmentation**
- Eruption corrected `359618` → `395160` (nodeID 93200 confirmed non-PASSIVE)
- Time Skip `404977` and Blistering Scales `360827` added to majorCooldowns
- Quell `351338` added as `isInterrupt`

---

### Druid

**Balance**
- Starfall moved from majorCooldowns → rotational (it's a spender, not a burst CD)
- Force of Nature `205636` added as talentGated CD — central to both hero talent priority lists
- Fury of Elune `202770` added as talentGated rotational — priority #3 in both build paths
- Wrath `5176` added to rotational — primary AP generator filler was completely missing

**Feral**
- Shred `5221` added to rotational — primary combo point builder was missing entirely
- Convoke the Spirits `391528` added as talentGated CD
- Incarnation: Avatar of Ashamane `102543` removed — not in Feral talent tree
- Predatory Swiftness `69369` removed from procBuffs — never confirmed in any snapshot
- Frantic Frenzy `1243807` and Feral Frenzy `274837` added as talentGated CDs
- Primal Wrath `285381` added as talentGated rotational (AoE finisher)

**Guardian**
- Moonfire `8921` added to rotational — rotation priority #1, was missing
- Maul `6807` added to rotational — primary Rage spender
- Lunar Beam `204066` added to majorCooldowns — non-PASSIVE ACTIVE nodeID 92587
- Survival Instincts removed — not in rotation guide priority list
- Red Moon `1252871` removed — cross-spec audit confirmed this is Balance-only

**Restoration**
- Incarnation: Tree of Life `33891` removed — not in Restoration talent tree
- Flourish `197721` removed — not in Restoration talent tree or spell list
- Wild Growth moved from majorCooldowns → rotational (maintenance HoT, not a burst CD)
- Ironbark `102342`, Nature's Swiftness `132158`, Innervate `29166` added to majorCooldowns
- Convoke the Spirits `391528` added as talentGated CD
- Lifebloom `33763` added to rotational

---

## Feedback Changes

- **Interrupt note repositioned** — now appended after the 8-item feedback cap, always the last item in the list. Previously it could appear mid-list and compete with scored feedback items.

---

## Open VERIFY Items (carry to 1.4.1+)

| Item | Spec | Method |
|---|---|---|
| Nightfall `108558` | Affliction Warlock | `/ms verify` — C_UnitAuras confirm |
| Furious Gaze `337567` | Havoc DH | `/ms verify` — C_UnitAuras confirm |
| Unbound Chaos `389860` | Havoc DH | `/ms verify` — C_UnitAuras confirm |
| Devastation Evoker resource enum (17) | Devastation | In-game resource enum check |
| Affliction talent tree upload | Affliction | Already completed this session ✅ |

---

*Midnight Sensei — Combat performance coaching for all 13 classes*
*Created by Midnight - Thrall (US)*
