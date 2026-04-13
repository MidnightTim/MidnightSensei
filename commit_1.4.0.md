# Commit — Midnight Sensei v1.4.0

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Branch:** main
**Tag:** v1.4.0

---

## Summary

Full spec database audit against live Midnight 12.0 spell and talent snapshots across all 13 classes. PASSIVE column added to talent snapshot tool catches passive talents that silently never fire cast events. Wrong spell IDs corrected, pruned abilities removed, missing core spells added. Interrupt tracking added with no-penalty note at bottom of feedback. Lua brace error in Demon Hunter fixed.

---

## Changed Files

- `Core.lua` — version 1.4.0, changelog, spec DB changes across all 13 classes, level gate warning
- `Analytics.lua` — isInterrupt handling, interrupt note repositioned to always bottom of feedback
- `BossBoard.lua` — RepairIdentity(), ingest feedback fields, identity fallback fixes
- `Leaderboard.lua` — LB.Toggle fix, LFR/LFG guard, QueryAllFriends deferred to Friends tab
- `UI.lua` — HUD gear/X, Review Fight toggle, window positions, Clear History gate

---

## Commits

### chore: bump version to 1.4.0, add changelog entry

### feat(spec-db): PASSIVE column audit — talent snapshot now captures all nodes
`BuildTalentSnapshot` overhauled. Now walks all tree nodes including INACTIVE. Adds `isPassive` field via `C_Spell.IsSpellPassive`. Export header shows ACTIVE/INACTIVE/PASSIVE counts. PASSIVE column shown per entry. Footer note: "PASSIVE = do not add to majorCooldowns or rotationalSpells."

### feat(spec-db): isInterrupt flag — track interrupts without penalising
New `isInterrupt = true` flag on `majorCooldowns` entries. In Analytics, interrupt spells are excluded from `neverUsed`/`underused` scoring entirely. If unused, a zero-weight note is appended at the bottom of feedback after the 8-item cap.

### fix(analytics): interrupt note always at bottom of feedback
Moved interrupt note from mid-feedback insertion point to after `while #feedback > 8` cap. Appends directly to `feedback` table as item 9+, guaranteed last.

### fix(spec-db/warlock/affliction): PASSIVE audit
- Malevolence `458355` → `442726`; Dark Harvest `387166` → `1257052`
- Phantom Singularity, Vile Taint removed (pruned Midnight 12.0)
- Wither `445468` added — confirmed non-PASSIVE nodeID 94840
- Drain Soul `388667` removed — PASSIVE nodeID 72045; `686` baseline retained
- Unstable Affliction, Drain Soul `686`, Seed of Corruption added to rotational
- Nightfall added to procBuffs (VERIFY)

### fix(spec-db/warlock/demonology): PASSIVE audit
- Diabolic Ritual, Summon Vilefiend, Reign of Tyranny, Doom — all confirmed PASSIVE, removed
- Hand of Gul'dan: `172` removed (spec-variant never matching), `105174` retained (talent cast ID)
- Grimoire: Fel Ravager marked `isInterrupt = true`
- Summon Doomguard added to majorCooldowns; Demonbolt, Dark Harvest added to rotational

### fix(spec-db/warlock/destruction): PASSIVE audit
- Malevolence `458355` → `442726`; Havoc removed; Immolate removed; Incinerate `29722` → `686`
- Diabolic Ritual, Devastation — confirmed PASSIVE, removed
- Conflagrate, Shadowburn, Rain of Fire added to rotational

### fix(spec-db/dh/havoc): PASSIVE audit + ID corrections
- Fel Barrage removed (not in Midnight 12.0)
- Chaos Strike `162794` → `344862` (spec-variant)
- Essence Break, Felblade added to rotational (non-PASSIVE ACTIVE)
- Furious Gaze, Unbound Chaos flagged VERIFY

### fix(spec-db/dh/vengeance): ID corrections
- Metamorphosis `187827` → `191427`; Demon Spikes `203819` → `203720`
- Fracture `210152` → `344859`; Soul Cleave `228477` → `344862`
- Soul Barrier removed; Spirit Bomb, Felblade added to rotational
- Sigil of Spite added to majorCooldowns

### fix(spec-db/dh/devourer): PASSIVE audit — 4 majorCooldowns removed
- Impending Apocalypse, Demonsurge, Midnight, Eradicate — confirmed PASSIVE
- Soul Immolation retained as sole majorCooldown
- scoreWeights: cooldownUsage 30→25, activity 35→40

### fix(core/dh): Lua brace error — duplicate stub in Havoc entry
Unclosed `[1] = {` stub (3 lines: name, resourceType, closing comment block) left above the real full Havoc entry from a previous str_replace. Pushed entire Demon Hunter class one depth level too deep, producing `'}' expected` Lua error on load. Removed stub.

### fix(spec-db/shaman/elemental): Tempest removed — PASSIVE
- `454009` confirmed PASSIVE nodeID 94892

### fix(spec-db/shaman/enhancement): PASSIVE audit + ID corrections
- Feral Spirit `51533`/`469314`, Ascendance `114051`, Primordial Wave `375982` removed
- Maelstrom Weapon `344179` → `187880` (spell list confirmed)
- Surging Totem added to majorCooldowns; Crash Lightning, Lava Lash, Voltaic Blaze added to rotational

### fix(spec-db/shaman/restoration): Call of the Ancestors removed — PASSIVE

### fix(spec-db/evoker/devastation): Pyre added, Quell isInterrupt
### fix(spec-db/evoker/preservation): Emerald Communion removed, Tip the Scales corrected 374348→370553, Time Dilation/Temporal Anomaly/Echo added
### fix(spec-db/evoker/augmentation): Eruption corrected 359618→395160, Time Skip/Blistering Scales added, Quell isInterrupt

### fix(spec-db/druid/balance): Starfall demoted, Force of Nature/Fury of Elune/Wrath added
- Starfall moved majorCooldowns → rotational (spender not a burst CD)
- Force of Nature added as talentGated CD; Fury of Elune added to rotational
- Wrath added to rotational — primary AP filler was missing entirely

### fix(spec-db/druid/feral): Shred added, Incarnation removed, Predatory Swiftness removed
- Shred `5221` added — primary CP builder was completely absent
- Convoke the Spirits added as talentGated CD
- Incarnation `102543` removed (not in tree); Predatory Swiftness `69369` removed (unconfirmed)
- Frantic Frenzy, Feral Frenzy added as CDs; Primal Wrath added to rotational

### fix(spec-db/druid/guardian): Moonfire/Maul/Lunar Beam added, Red Moon removed
- Moonfire added to rotational (priority #1 was missing)
- Maul `6807` added to rotational; Lunar Beam added to majorCooldowns
- Survival Instincts removed (not in rotation guide); Red Moon removed (Balance-only confirmed by cross-spec audit)

### fix(spec-db/druid/restoration): Incarnation Tree/Flourish removed, Wild Growth demoted, CDs added
- Incarnation: Tree of Life, Flourish removed (not in talent tree)
- Wild Growth moved majorCooldowns → rotational
- Ironbark, Nature's Swiftness, Innervate added to majorCooldowns
- Convoke added as talentGated CD; Lifebloom added to rotational
