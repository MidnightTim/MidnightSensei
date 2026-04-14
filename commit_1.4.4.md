# Commit — Midnight Sensei v1.4.4

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Branch:** main
**Tag:** v1.4.4

---

## Summary

Full spec DB audit across all 39 specs using the upgraded `/ms debug talents` tool (v1.4.3) with description capture, PASSIVE column, and `>>>` keyword flagging. Removes wrong IDs, adds missing CDs and rotational spells, fixes spec-variant IDs, and introduces suppressIfTalent for the Subtlety Gloomblade/Backstab choice node. Debug tool upgraded with description export. Analytics suppressIfTalent extended to majorCooldowns. All sourceNotes updated.

---

## Changed Files

- `Core.lua` — version 1.4.4, changelog, all spec DB changes
- `Analytics.lua` — suppressIfTalent extended to majorCooldowns setup loop

---

## Commits

### chore: bump version to 1.4.4, update changelog

### feat(debug): description capture in /ms debug talents
- `C_Spell.GetSpellDescription` called per talent node in `BuildTalentSnapshot`
- Description stored in snapshot, printed below each talent row in `/ms debug talents` export
- Keywords `Replaces/Grants/Transforms/Causes/Activates` flagged with `>>>` prefix
- `FLAGGED: N` added to header summary
- One-file workflow replaces old two-file (spell + talent) audit process

### fix(analytics): suppressIfTalent extended to majorCooldowns
- Previously only checked for `rotationalSpells`; now also checked in `majorCooldowns` setup loop
- Enables `suppressIfTalent` patterns at the CD level (e.g. Soul Immolation / Spontaneous Immolation)

### fix(spec-db/dh/havoc): wrong IDs removed, Chaos Nova and Sigil of Misery added
- `162794`, `188499`, `344862` removed from rotational and validSpells — not in Havoc talent tree
- Chaos Nova `179057` added as talentGated CD
- Sigil of Misery `207684` added as isInterrupt

### fix(spec-db/dh/vengeance): Metamorphosis/Soul Cleave/Fracture removed, interrupts added
- Metamorphosis `191427` removed — shapeshifting, UPDATE_SHAPESHIFT_FORM not SUCCEEDED
- `228477`, `344862`, `344859` removed — wrong IDs confirmed by snapshot
- Sigil of Silence `202137` and Sigil of Misery `207684` added as isInterrupt
- Chaos Nova `179057` added as talentGated CD

### fix(spec-db/dh/devourer): Reap removed, The Hunt added
- Reap `344862` removed — not in Devourer talent tree (v1.4.3 snapshot confirmed)
- The Hunt `1246167` added as talentGated CD — Devourer spec-variant confirmed ACTIVE

### fix(spec-db/warrior): Shockwave/Champion's Spear/Rend added across Arms/Fury/Prot
- Arms: Shockwave `46968` talentGated CD
- Fury: Shockwave `46968` + Champion's Spear `376079` talentGated CDs; Rend `772` talentGated rotational
- Protection: Rend `772` talentGated rotational

### fix(spec-db/rogue/outlaw): Killing Spree added
- Killing Spree `51690` added as talentGated CD — nodeID 94565

### fix(spec-db/rogue/subtlety): Goremaw's Bite added, Gloomblade choice node handled
- Goremaw's Bite `426591` added as talentGated CD — nodeID 94581
- Gloomblade `200758` added as talentGated rotational
- Backstab `1752` gains `suppressIfTalent = 200758` — choice node, only one tracks at a time

### fix(spec-db/mage/arcane): Touch of the Magi corrected, Arcane Orb/Pulse added
- Touch of the Magi `210824` → `321507` (correct Arcane tree ID, nodeID 102468)
- Arcane Orb `153626` added as talentGated CD — nodeID 104113
- Arcane Pulse `1241462` added as talentGated CD — nodeID 102439

### fix(spec-db/mage/fire): Flamestrike added
- Flamestrike `1254851` added as talentGated rotational — Fire spec-variant nodeID 109409

### fix(spec-db/dk/blood): Consumption added
- Consumption `1263824` added as talentGated CD — nodeID 102244

### fix(spec-db/monk/mistweaver): Sheilun's Gift added
- Sheilun's Gift `399491` added as CD — nodeID 101120 non-PASSIVE ACTIVE; was missing entirely

### fix(spec-db/monk/windwalker): Slicing Winds added
- Slicing Winds `1217413` added as talentGated CD — nodeID 102250

### fix(spec-db/warlock/destruction): Wither added
- Wither `445468` added as talentGated CD — shared node with Affliction, was missing from Destruction

### fix(spec-db/priest/shadow): Halo Shadow spec-variant added
- Halo `120644` added as talentGated rotational — Shadow spec-variant; nodeID 94697 (distinct from Holy's `120517`)

### chore(spec-db): update all 39 sourceNotes to v1.4.3 snapshot verification
