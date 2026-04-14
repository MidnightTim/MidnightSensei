# Midnight Sensei v1.4.5 — Balance Druid Hero Talent Fixes, Shapeshift Audit, Analytics Gate Fixes

## Overview

1.4.5 is a targeted correctness pass driven by live testing on Balance Druid. The session exposed three classes of bugs: hero talent choice nodes that break `IsPlayerSpell` assumptions, shapeshift spells in tracked CD lists, and Analytics gate logic that bypassed all talent checks when `cdTracking` was empty. All three are fixed. A full 39-spec shapeshift audit was also completed using the v1.4.3 description snapshots.

---

## Balance Druid — Hero Talent Fixes

### Incarnation: Chosen of Elune removed from majorCooldowns
Incarnation's tooltip reads **"Talent, Shapeshift"** — it fires `UPDATE_SHAPESHIFT_FORM` not `UNIT_SPELLCAST_SUCCEEDED`. `useCount` would be permanently 0 regardless of usage. Removed from tracking entirely.

### Celestial Alignment false "never pressed" feedback — fixed
When Incarnation is talented, CA is replaced on the bar. However `IsPlayerSpell(194223)` returns `true` in Midnight 12.0 even when Incarnation is the selected choice — Blizzard keeps CA registered internally. The fix required two changes:

1. `suppressIfTalent = 102560` added to both CA entries — `IsPlayerSpell(102560)` confirms Incarnation is in the spellbook
2. `Analytics.lua` talentGated path for `majorCooldowns` now uses `IsPlayerSpell` **only**, not `IsTalentActive` — `IsTalentActive(194223)` was returning true via the C_Traits prerequisite walk even when Incarnation replaced it

### Wrath false "never used" feedback — fixed
Elune's Chosen hero talent takes Lunar Calling (`429523`), which prevents Solar Eclipse entirely. You never cast Wrath in this build. `suppressIfTalent = 429523` added to Wrath's rotational entry.

### Starfire added as talentGated rotational
Starfire `194153` — the primary filler for Elune's Chosen builds — was completely absent from the spec DB. Added as `talentGated = true`.

### Starsurge false "never used" feedback — fixed
Star Cascade (`1271206`) auto-fires Starsurge passively when Wrath or Starfire generate Astral Power. The Starsurge appearing in the damage meter is a proc, not a manual cast. `suppressIfTalent = 1271206` added.

---

## Full 39-Spec Shapeshift Audit

Using the v1.4.3 talent snapshots with description export, every non-PASSIVE ability was scanned for shapeshift and replacement patterns.

### Removed — confirmed shapeshifts
| Spell | Spec | Evidence |
|---|---|---|
| Incarnation: Guardian of Ursoc `102558` | Guardian | "improved Bear Form...freely shapeshift in and out" |
| Incarnation: Chosen of Elune `102560` | Balance | "Talent, Shapeshift" tooltip |

### VERIFY — pending in-game confirmation
| Spell | Spec | Concern |
|---|---|---|
| Ascendance `114050` | Elemental | "Transform into a Flame Ascendant" |
| Ascendance `114052` | Resto Shaman | "transforms into a Water Ascendant" |
| Voidform `228260` | Shadow | Modifies existing Shadowform — likely fires SUCCEEDED |

### Confirmed safe — no action
Avatar `107574` (Warrior), Alter Time `342245` (Mage), Apotheosis `200183` (Holy Priest), Convoke the Spirits `391528` (Druid) — all fire `UNIT_SPELLCAST_SUCCEEDED` correctly.

---

## CLEU Investigation

`COMBAT_LOG_EVENT_UNFILTERED` was investigated as a secondary cast detection path to catch spec-variant ID mismatches (spells that appear in the damage meter but never fire `UNIT_SPELLCAST_SUCCEEDED`). After two attempts — main chunk registration and `PLAYER_LOGIN` registration — both triggered `ADDON_ACTION_FORBIDDEN`. **CLEU is a fully protected event in Midnight 12.0.** Reverted entirely. `UNIT_SPELLCAST_SUCCEEDED` + `UNIT_SPELLCAST_CHANNEL_START` remain the ceiling for cast detection.

---

## Analytics — Gate Logic Fixes

### IsTalentActive rewritten
- **IsPlayerSpell fast path** added at the top — covers most baseline and talent-granted castable spells without a C_Traits tree walk
- **C_Traits walk now iterates `node.entryIDs`** instead of `node.activeEntry` only — correctly resolves choice nodes where the active side differs from the definition spellID

### talentGated majorCooldowns — IsPlayerSpell only
Previously, `talentGated` entries in `majorCooldowns` fell through to `IsTalentActive`, which returned `true` for prerequisite nodes whose button had been replaced. Now `talentGated` CDs use `IsPlayerSpell` exclusively — if the spell isn't on the bar, it isn't tracked.

### Empty cdTracking else branch — gate logic added
When `cdTracking` is empty (all CDs either unlearned or suppressed), the feedback generation path was bypassing all talent gates and reporting every CD in the spec definition as "never pressed". Fixed — the else branch now applies the same `suppressIfTalent` and `talentGated` checks as the setup loop.

---

## Open VERIFY Items (carry forward)

| Item | Spec | Detail |
|---|---|---|
| Vengeance Soul Cleave | Vengeance DH | Correct runtime ID unknown |
| Vengeance Fracture | Vengeance DH | Correct runtime ID unknown |
| Ascendance `114050` | Elemental | Shapeshift? VERIFY via `/ms verify` |
| Ascendance `114052` | Resto Shaman | Shapeshift? VERIFY via `/ms verify` |
| Voidform `228260` | Shadow | VERIFY SUCCEEDED fires |
| Celestial Alignment `383410` | Balance | Orbital Strike variant — VERIFY runtime ID |
| Killing Machine `59052` | Frost DK | Talent shows `51128` |
| Rime `51124` | Frost DK | Spell list shows `59057` |
| Hot Streak `48108` | Fire Mage | Spell list shows `195283` |
| Brain Freeze `190446` | Frost Mage | Talent shows `190447` |
| Fingers of Frost `44544` | Frost Mage | Talent shows `112965` |

---

*Midnight Sensei — Combat performance coaching for all 13 classes*
*Created by Midnight - Thrall (US)*
