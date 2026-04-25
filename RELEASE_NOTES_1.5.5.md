# Midnight Sensei v1.5.5 Release Notes

## Overview

v1.5.5 replaces all aura-scanning uptime tracking with a cast-event-based approach. Three separate attempts in v1.5.4 to work around Midnight 12.0's API restrictions on `aura.spellId` all failed — the restriction is a blanket block on the field when addon code is tainted. The cast-based approach uses `ABILITY_USED` events (fired from `UNIT_SPELLCAST_SUCCEEDED`) and requires no aura access.

---

## Root Cause

In Midnight 12.0, `GetAuraDataByIndex` returns an aura table where `aura.spellId` is a "secret number value." Any equality comparison (`aura.spellId == someId`) throws:

```
attempt to compare field 'spellId' (a secret number value, while execution tainted by 'MidnightSensei')
```

This fires every `UNIT_AURA` event during combat (every 0.5s via ticker, plus event-driven). The error was logged 119 times in one short fight. There is no safe way to use `aura.spellId` for comparisons when tainted — `pcall` catches the error but the comparison always returns false, making it silently non-functional.

---

## Fix: Cast-Based Uptime Windows

Instead of watching for buff auras, the tracker now listens for the **cast spell** that applies the buff:

- Each `uptimeBuff` entry now declares `castSpellId` (single) or `castSpellIds` (list of triggers).
- `buffDuration` specifies how long each cast keeps the buff active.
- On cast: opens a window (or extends it on refresh — no close/reopen gap).
- A 0.25s expiry-checker ticker closes windows when `buffDuration` lapses.
- Combat end closes any open window, capping at `currentExpiry` if the buff already expired.

This approach has no contact with `aura.spellId` and is not affected by taint.

---

## Specs Updated

| Spec | Buff | Cast ID | Duration |
|---|---|---|---|
| Protection Warrior | Shield Block | 2565 | 6s |
| Protection Paladin | Shield of the Righteous | 53600 | 4.5s |
| Guardian Druid | Ironfur | 192081 | 7s |
| Vengeance Demon Hunter | Demon Spikes | 203720 | 6s |
| Augmentation Evoker | Ebon Might | 395152 | 10s |
| Fury Warrior | Enrage | 23881 + 184367 | 8s |

Fury Warrior Enrage uses `castSpellIds` with both Bloodthirst (23881) and Rampage (184367) as triggers — both apply/extend Enrage in current retail.

---

## Verify Report Changes

`/ms verify report` AURA CHECK section now:
- **uptimeBuffs**: shows `SEEN` if the cast spell ID was seen in `VerifySeenSpells`; `FAIL` if not cast; `INFO` if no `castSpellId` defined (e.g. `infoOnly` Arcane Intellect).
- **procBuffs**: shows `FAIL / NOT DETECTED` — aura.spellId scanning removed for the same taint reason. Use `/ms debug auras` to manually confirm proc aura IDs.

---

## Files Changed

- `Combat/AuraTracker.lua` — complete rewrite; all aura scanning removed
- `Specs/Warrior.lua` — Shield Block `castSpellId = 2565, buffDuration = 6`; Enrage `castSpellIds = {23881, 184367}, buffDuration = 8`
- `Specs/Paladin.lua` — SotR `castSpellId = 53600, buffDuration = 4.5`
- `Specs/Druid.lua` — Ironfur `castSpellId = 192081, buffDuration = 7`
- `Specs/DemonHunter.lua` — Demon Spikes `castSpellId = 203720, buffDuration = 6`
- `Specs/Evoker.lua` — Ebon Might `castSpellId = 395152, buffDuration = 10`
- `Core.lua` — verify recorder and AURA CHECK updated; version 1.5.5; CHANGELOG
- `MidnightSensei.toc` — version 1.5.5
