# Midnight Sensei v1.4.4 — Full Spec DB Audit: All 39 Specs Verified Against v1.4.3 Snapshots

## Overview

1.4.4 is the completion of the full spec database audit pass using the upgraded `/ms debug talents` tool with description capture. Every spec across all 13 classes has been verified against a live v1.4.3 talent snapshot with the PASSIVE column, description text, and keyword flagging. The result is the most accurate spec DB the addon has ever had.

The new debug tool workflow (descriptions + `>>>` flagging) proved its value immediately: it identified the Spontaneous Immolation / Soul Immolation `suppressIfTalent` pattern in 1.4.3, and in this pass it caught Gloomblade replacing Backstab in Subtlety, Touch of the Magi's corrected ID in Arcane, and a number of missing CDs across multiple specs.

---

## Debug Tool Enhancements

**`/ms debug talents` — Description Capture**
- Spell descriptions now captured via `C_Spell.GetSpellDescription` and stored in the talent snapshot for every node including INACTIVE ones
- Descriptions printed below each talent row in the export
- Keywords `Replaces`, `Grants`, `Transforms`, `Causes`, `Activates` flagged with `>>>` prefix — immediately identifies `suppressIfTalent` and `talentGated` candidates
- `FLAGGED: N` count added to the header summary line
- One file per spec now replaces the old two-file (spell + talent) workflow

**Analytics — `suppressIfTalent` for majorCooldowns**
- `suppressIfTalent` check added to the majorCooldowns tracking setup loop — was previously only applied to `rotationalSpells`
- Enables the Soul Immolation / Spontaneous Immolation pattern to work correctly at the CD level

---

## Spec DB Changes by Class

### Demon Hunter

**Havoc**
- `162794`, `188499`, `344862` removed from rotational and validSpells — not in Havoc talent tree
- Chaos Nova `179057` added as talentGated CD — non-PASSIVE ACTIVE
- Sigil of Misery `207684` added as `isInterrupt` — non-PASSIVE ACTIVE

**Vengeance**
- Metamorphosis `191427` removed from majorCooldowns — shapeshifting spell, fires `UPDATE_SHAPESHIFT_FORM` not `UNIT_SPELLCAST_SUCCEEDED`
- Soul Cleave `228477`, `344862`, Fracture `344859` removed — wrong IDs confirmed by snapshot
- Sigil of Silence `202137` and Sigil of Misery `207684` added as `isInterrupt`
- Chaos Nova `179057` added as talentGated CD
- Soul Cleave and Fracture IDs remain unknown — flagged VERIFY

**Devourer**
- Reap `344862` removed — confirmed not in Devourer talent tree via v1.4.3 snapshot
- The Hunt `1246167` (Devourer spec-variant) added as talentGated CD — non-PASSIVE ACTIVE

---

### Warrior

**Arms**
- Shockwave `46968` added as talentGated CD — shared class node, confirmed non-PASSIVE ACTIVE

**Fury**
- Shockwave `46968` and Champion's Spear `376079` added as talentGated CDs
- Rend `772` added as talentGated rotational — shared class DoT

**Protection**
- Rend `772` added as talentGated rotational

---

### Rogue

**Outlaw**
- Killing Spree `51690` added as talentGated CD — nodeID 94565 INACTIVE this build

**Subtlety**
- Goremaw's Bite `426591` added as talentGated CD — nodeID 94581 INACTIVE this build
- Gloomblade `200758` added as talentGated rotational
- Backstab `1752` gains `suppressIfTalent = 200758` — Gloomblade is a choice node that replaces Backstab as the primary builder; only one should track at a time

---

### Mage

**Arcane**
- Touch of the Magi corrected `210824` → `321507` — `210824` was wrong; `321507` is the correct Arcane tree ID at nodeID 102468
- Arcane Orb `153626` added as talentGated CD — nodeID 104113
- Arcane Pulse `1241462` added as talentGated CD — nodeID 102439

**Fire**
- Flamestrike `1254851` added as talentGated rotational — Fire spec-variant; nodeID 109409 non-PASSIVE ACTIVE

**Frost**
- No changes — snapshot confirmed clean

---

### Death Knight

**Blood**
- Consumption `1263824` added as talentGated CD — nodeID 102244; damage + instant Blood Plague burst

**Frost / Unholy**
- Both confirmed clean against v1.4.3 snapshots

---

### Monk

**Mistweaver**
- Sheilun's Gift `399491` added as CD — nodeID 101120 non-PASSIVE ACTIVE; draws in nearby mist clouds for burst healing; was missing entirely

**Windwalker**
- Slicing Winds `1217413` added as talentGated CD — nodeID 102250 INACTIVE this build

**Brewmaster**
- Confirmed clean against v1.4.3 snapshot

---

### Warlock

**Destruction**
- Wither `445468` added as talentGated CD — non-PASSIVE ACTIVE; shared node with Affliction, was missing from Destruction spec DB

**Affliction / Demonology**
- Both confirmed clean

---

### Priest

**Shadow**
- Halo `120644` added as talentGated rotational — Shadow spec-variant (distinct from Holy's `120517`); nodeID 94697 non-PASSIVE ACTIVE

**Discipline / Holy**
- Both confirmed clean

---

### All Other Classes

**Hunter (BM, MM, Survival), Shaman (all three), Death Knight (Frost/Unholy), Druid (all four), Paladin (all three), Evoker (all three)** — all confirmed clean against v1.4.3 snapshots. sourceNotes updated with node counts.

---

## Open VERIFY Items (carry forward)

| Item | Spec | Detail |
|---|---|---|
| Vengeance Soul Cleave | Vengeance DH | Correct runtime ID unknown — `344862` wrong |
| Vengeance Fracture | Vengeance DH | Correct runtime ID unknown — `344859` wrong |
| Havoc Chaos Strike | Havoc DH | Correct runtime ID unknown — removed `344862` |
| Enrage aura `184362` | Fury Warrior | Spell list shows `184361`; 184362 may be enhanced version |
| Shield of the Righteous aura `132403` | Prot Paladin | VERIFY C_UnitAuras |
| Art of War `406064` | Retribution | VERIFY C_UnitAuras |
| Killing Machine `59052` | Frost DK | Talent shows `51128` |
| Rime `51124` | Frost DK | Spell list shows `59057` |
| Hot Streak `48108` | Fire Mage | Spell list shows `195283` |
| Brain Freeze `190446` | Frost Mage | Talent shows `190447` |
| Fingers of Frost `44544` | Frost Mage | Talent shows `112965` |
| Nightfall `108558` | Affliction | VERIFY C_UnitAuras |
| Furious Gaze `337567` | Havoc DH | VERIFY C_UnitAuras |
| Unbound Chaos `389860` | Havoc DH | VERIFY C_UnitAuras |

---

*Midnight Sensei — Combat performance coaching for all 13 classes*
*Created by Midnight - Thrall (US)*
