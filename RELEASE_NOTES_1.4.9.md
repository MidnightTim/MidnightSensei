# Release Notes — v1.4.9

## Overview

v1.4.9 fixes a Spell List display bug where wrong-hero-tree spells appeared for Mage players on the Spellslinger hero talent path, adds utility feedback for all three Mage specs, introduces two new spec-definition flags (`isUtility`, `infoOnly`) for ungraded coaching, and fills four missing rotational spells in the Shadow Priest spec.

---

## Fix: Spell List Showing Wrong-Hero-Tree Spells (UI.lua)

**What broke:** The "My Spell List" window displayed `talentGated` spells from the wrong hero talent path. A Frost Mage on Spellslinger saw Frostfire Bolt listed as a tracked spell even though they hadn't chosen the Frostfire hero tree.

**Why:** The Spell List's `isActive()` function used `UiTalentCheck(entry.id)` alone to gate `talentGated` entries. `UiTalentCheck` is a strict C_Traits node walk — and certain passive prereq nodes in hero talent paths have `activeRank > 0` in C_Traits even when the player chose the OTHER hero tree (they share tree structure). This is the same root cause fixed in CastTracker in v1.4.8.

**Fix:** Added `AND IsPlayerSpell(entry.id)` to the `talentGated` check in `UI.lua`'s `isActive()` function, mirroring the fix already applied to CastTracker. A spell must now pass both C_Traits AND spellbook gates to appear in the list.

**Files changed:** `UI.lua`

---

## Feature: Mage Utility Feedback (All 3 Specs)

**What was added:** All three Mage specs (Arcane, Fire, Frost) now receive informational post-fight notes for three class utility spells. These are never graded or penalised — coaching reminders only.

**Counterspell (2139):** Added as `isInterrupt = true` to all three specs. If unused during a fight ≥ 20 seconds, feedback appends: *"Note: Counterspell — this is your interrupt. Not used this fight — no penalty."*

**Spellsteal (30449):** Added as `isUtility = true` to all three specs. If unused during a fight ≥ 20 seconds, feedback appends: *"Note: Spellsteal — not used or detected this fight. No penalty."*

**Arcane Intellect (1459):** Added as an `infoOnly = true` uptimeBuff to all three specs. If the buff is not detected during the fight (uptime < 5%), feedback appends: *"Note: Arcane Intellect (group buff — ensure it's active before combat) — not used or detected this fight. No penalty."* Does not affect score.

**Files changed:** `Specs/Mage.lua`

---

## Infrastructure: isUtility Flag (Feedback.lua, UI.lua)

**New flag:** `isUtility = true` on a `majorCooldowns` entry behaves identically to `isInterrupt = true` but with separate messaging. Utility spells appear under "Interrupt & Utility" in My Spell List, are excluded from the "Cooldown Spells" section, and generate a utility note at fight end rather than an interrupt note. The `else` branch in Feedback.lua (empty cdTracking) also skips `isUtility` entries.

**Files changed:** `Analytics/Feedback.lua`, `UI.lua`

---

## Infrastructure: infoOnly uptimeBuff + AuraTracker Initial Scan

**New flag:** `infoOnly = true` on an `uptimeBuffs` entry means the buff is tracked for presence but excluded from the uptime score. The scored uptime path in both `Scoring.lua` and `Feedback.lua` already gates on `appCount > 0` — pre-combat buffs like Arcane Intellect have `appCount = 0` (never applied during combat) so the score is naturally unaffected.

**AuraTracker initial scan:** At `COMBAT_START`, after initializing `auraData`, `AuraTracker.lua` now scans `C_UnitAuras.GetPlayerAuraBySpellID` for each uptimeBuff. If the buff is already active at pull, `isActive = true` and `lastApplied = combatStartTime` so uptime accumulates from the start of the fight. `appCount` is intentionally NOT incremented for pre-existing buffs.

**Files changed:** `Combat/AuraTracker.lua`, `Analytics/Feedback.lua`

---

## Fix: Shadow Priest Missing Rotational Spells (Specs/Priest.lua)

**What broke:** Four spells cast regularly by Shadow Priests were not tracked, appearing only in the "Other Spells" section of `/ms verify report` with no PASS/FAIL status.

| Spell | ID | Notes |
|---|---|---|
| Mind Flay | 15407 | Baseline filler — used outside of Voidform |
| Shadow Word: Death | 32379 | Class talent — execute and damage on CD |
| Void Blast | 450983 | Voidweaver hero talent — empowered Mind Blast during Voidform |
| Void Volley | 1242173 | Voidweaver hero talent — AoE damage |

**Fix:** Added all four to Shadow's `rotationalSpells`. Mind Flay is baseline (no `talentGated`). The three others are `talentGated = true` — Shadow Word: Death is a class talent; Void Blast and Void Volley are Voidweaver-only. Priority notes updated to reflect filler usage and Voidweaver rotation context.

**Files changed:** `Specs/Priest.lua`

---

## VERIFY Carry-Forward

| Spell | ID | Spec | Status |
|---|---|---|---|
| id=228597 "Frostbolt" | 228597 | Frost Mage | Fires 1:1 with id=116 — passive talent companion cast, source unknown. No tracking bug (id=116 PASS). Isolate by disabling Frost talents one at a time. |
| Ascendance | 114050 | Elemental Shaman | May be shapeshift |
| Ascendance | 114052 | Resto Shaman | May be shapeshift |
| Voidform | 228260 | Shadow Priest | Likely fires SUCCEEDED |
| Enrage aura | 184362 | Fury Warrior | Spell list shows 184361 |
| Hot Streak | 48108 | Fire Mage | Spell list shows 195283 |
