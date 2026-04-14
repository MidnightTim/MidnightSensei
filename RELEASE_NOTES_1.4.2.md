# Midnight Sensei v1.4.2 — Class Tuning: Paladin, Death Knight, Mage, Rogue, Monk + UX Polish

## Overview

1.4.2 continues the class tuning pass with five class families — Paladin, Death Knight, Mage, Rogue, and Monk — bringing the total verified spec count to 39/39. All specs are now audited against live Midnight 12.0 spell snapshots and full talent tree exports with the PASSIVE column.

This release also includes the UX polish changes that shipped mid-cycle: the login message now delivers immediate value instead of sending players through a two-step indirection, the `/ms` bare command shows a useful command strip, and the public help output no longer exposes internal debug and reset commands. The `debug guild inject` handler has been deleted entirely.

---

## UX Changes

**Login message**
Was: `Midnight Sensei v1.4.1 loaded. Type /ms for commands.`
Now: `Midnight Sensei v1.4.2 loaded. /ms show to open the HUD · /ms help for commands.`

**`/ms` bare**
Now prints: `show · hide · history · lb · options · help` inline — no redirect.

**`/ms help` and FAQ panel**
Removed: `/ms reset`, all `/ms debug` entries, `/ms verify report`
Added: `/ms versions`, `/ms friend`

**`debug guild inject` removed**
The test score injection tool sent synthetic SCORE payloads to the GUILD addon channel. Deleted entirely from the codebase.

---

## Spec DB Changes

### Paladin

**Holy**
- `resourceType` corrected `0` → `9` — Holy generates and spends Holy Power
- Beacon of Light `53563` removed from uptimeBuffs — applied to target, not self
- Blessing of Sacrifice marked `talentGated` — INACTIVE in this build
- Aura Mastery `31821`, Lay on Hands `633`, Holy Bulwark `432459` added as CDs
- Light of Dawn `85222` added rotational — AoE Holy Power spender

**Protection**
- Avenging Wrath `31884` and Divine Toll `375576` added as CDs — both missing entirely
- Rebuke `96231` added as `isInterrupt`
- `35395` label corrected "Crusader Strike" → "Blessed Hammer" (Prot spec-variant)
- Consecration `26573` and Holy Shock `20473` added rotational
- Shield of the Righteous uptime aura `132403` flagged VERIFY

**Retribution**
- Crusade `231895` removed — `1253598` is PASSIVE modifier, not castable
- Templar's Verdict `85256` → Final Verdict `383328` (Midnight 12.0 rename)
- Divine Toll `375576` added CD; Rebuke `96231` added `isInterrupt`
- Execution Sentence `343527` marked `talentGated`
- Blade of Justice `184575` and Divine Storm `53385` added rotational
- Art of War `406064` added procBuff — VERIFY C_UnitAuras
- Hammer of Light: not in talent tree or spell list — not tracked

---

### Death Knight

**Blood**
- Abomination Limb `383269` and Bonestorm `194844` removed — not in Blood tree/spell list
- Blood Shield `77535` removed from uptimeBuffs — proc absorb, not a persistent aura
- Reaper's Mark `439843` added CD; Mind Freeze `47528` added `isInterrupt`
- Entire rotationalSpells block added — was completely empty: Marrowrend `195182`, Heart Strike `206930`, Blood Boil `50842`, Death Strike `49998`

**Frost**
- Breath of Sindragosa `1249658` added as talentGated CD
- Reaper's Mark `439843` added CD; Mind Freeze `47528` added `isInterrupt`
- Howling Blast `49184` added rotational — primary AoE/Rime consumer was missing
- Frostscythe `207230` added talentGated rotational
- Killing Machine `59052` and Rime `51124` procBuff IDs flagged VERIFY (old aura IDs)

**Unholy**
- Apocalypse `275699` and Unholy Assault `207289` removed — not in Unholy tree/spell list
- Dark Transformation corrected `63560` → `1233448` (Unholy spec-variant)
- Outbreak `77575` and Soul Reaper `343294` added as CDs; Mind Freeze `47528` added `isInterrupt`
- Festering Strike corrected `85092` → `316239` (Unholy spec-variant)
- Putrefy `1247378` added talentGated rotational

---

### Mage

**Arcane**
- Touch of the Magi `210824` and Evocation `12051` removed — not in Arcane tree/spell list
- Arcane Blast corrected `30451` → `116` (Arcane spec-variant)
- Arcane Barrage corrected `44425` → `319836` (Arcane spec-variant)
- Alter Time `342245` added CD; Arcane Missiles `5143` and Arcane Explosion `1449` added rotational
- Clearcasting procBuff corrected `276743` → `79684`

**Fire**
- Phoenix Flames `257541` removed — not in Fire tree/spell list
- Fireball corrected `133` → `116` (Fire spec-variant)
- Supernova `157980` and Frostfire Bolt `431044` added as talentGated CDs
- Pyroblast `11366` and Scorch `2948` added rotational
- Hot Streak `48108` procBuff flagged VERIFY — spell list shows `195283`

**Frost**
- Icy Veins `12472` removed — not in Frost tree/spell list
- Flurry `44614`, Frostfire Bolt `431044`, Ray of Frost `205021`, Dragon's Breath `31661` added as CDs
- Frostbolt `116` added rotational — primary filler was missing entirely
- Brain Freeze `190446` and Fingers of Frost `44544` procBuff IDs flagged VERIFY

---

### Rogue

**Assassination**
- Vendetta `79140` removed — not in Assassination tree/spell list
- Kick `1766` added `isInterrupt`
- Envenom corrected `32645` → `196819` (Assassination spec-variant)
- Mutilate `1752` and Crimson Tempest `1247227` added rotational

**Outlaw**
- Roll the Bones corrected `315508` → `1214909`
- Between the Eyes corrected `199804` → `315341`; Dispatch corrected `2098` → `196819`
- Blade Rush `271877` and Keep It Rolling `381989` added as talentGated CDs
- Kick `1766` added `isInterrupt`
- Sinister Strike `1752` and Pistol Shot `185763` added rotational — both missing entirely

**Subtlety**
- Symbols of Death `212283` removed — not in Subtlety tree/spell list
- Kick `1766` added `isInterrupt`; Nightblade `195452` removed from rotational
- Backstab `1752` and Shuriken Storm `197835` added rotational

---

### Monk

**Brewmaster**
- Celestial Brew `322507` removed — not in Brewmaster tree/spell list
- Ironskin Brew `215479` removed from uptimeBuffs — not in Midnight 12.0
- Exploding Keg `325153` and Celestial Infusion `1241059` added as CDs
- Spear Hand Strike `116705` added `isInterrupt`
- Breath of Fire `115181`, Tiger Palm `100780`, Blackout Kick `100784` added rotational — all missing

**Mistweaver**
- Invoke Yu'lon `322118` removed — not in Mistweaver tree/spell list
- Invoke Chi-Ji `325197` added CD — the correct Mistweaver invoke
- Renewing Mist corrected `119611` → `115151` (wrong ID entirely)
- Life Cocoon `116849` and Celestial Conduit `443028` added as CDs
- Spear Hand Strike `116705` added `isInterrupt`
- Enveloping Mist `124682` added rotational

**Windwalker**
- Storm, Earth and Fire `137639` and Serenity `152173` removed — not in WW tree/spell list
- Zenith `1249625` added CD; Spear Hand Strike `116705` added `isInterrupt`
- Combo Breaker: BoK `116768` removed from procBuffs — not in tree/spell list
- Tiger Palm `100780` and Blackout Kick `100784` added rotational — both missing entirely
- Whirling Dragon Punch `152175` added talentGated rotational

---

## Open VERIFY Items (carry to 1.4.3+)

| Item | Spec | Method |
|---|---|---|
| Enrage aura `184362` vs `184361` | Fury Warrior | In-game confirm which ID is the self-buff |
| Shield of the Righteous aura `132403` | Prot Paladin | In-game confirm aura ID vs cast IDs `53600`/`415091` |
| Art of War `406064` | Retribution | `/ms verify` — C_UnitAuras confirm |
| Killing Machine `59052` | Frost DK | `/ms verify` — talent shows `51128` |
| Rime `51124` | Frost DK | `/ms verify` — spell list shows `59057` |
| Hot Streak `48108` | Fire Mage | `/ms verify` — spell list shows `195283` |
| Brain Freeze `190446` | Frost Mage | `/ms verify` — talent shows `190447` |
| Fingers of Frost `44544` | Frost Mage | `/ms verify` — talent shows `112965` |
| Nightfall `108558` | Affliction Warlock | `/ms verify` — C_UnitAuras confirm |
| Furious Gaze `337567` | Havoc DH | `/ms verify` — C_UnitAuras confirm |
| Unbound Chaos `389860` | Havoc DH | `/ms verify` — C_UnitAuras confirm |

---

*Midnight Sensei — Combat performance coaching for all 13 classes*
*Created by Midnight - Thrall (US)*
