## [Bug] Uptime tracking broken by Midnight 12.0 aura.spellId taint — Shield Block, SotR, all tank mitigation buffs

**Affects:** All specs with non-empty `uptimeBuffs` — Protection Warrior (Shield Block), Protection Paladin (Shield of the Righteous), Guardian Druid (Ironfur), Vengeance Demon Hunter (Demon Spikes), Augmentation Evoker (Ebon Might), Fury Warrior (Enrage)

**Symptom:** All tank mitigation uptime reports 0% / "was never activated" regardless of actual usage. Appeared as a regression after v1.5.3 (which fixed the pre-pull appCount gap); the aura scan was silently failing throughout.

---

### Root Cause

In Midnight 12.0, `GetAuraDataByIndex` returns an aura table where `aura.spellId` is a "secret number value." Any equality comparison on this field when addon code is tainted throws:

```
attempt to compare field 'spellId' (a secret number value, while execution tainted by 'MidnightSensei')
```

This fired on every `UNIT_AURA` event plus every 0.5s ticker poll — 119 times in a single short fight.

Three fix attempts in v1.5.4 all failed at the same wall:
1. `GetAuraDataByIndex` index scan in place of `GetPlayerAuraBySpellID` — `aura.spellId == spellID` still throws
2. `pcall` around the comparison — catches error silently; comparison always returns false
3. 0.5s `C_Timer.NewTicker` polling fallback — still calls the same broken comparison

The restriction is a blanket block. There is no fix within any WoW aura API.

Additionally: `GetPlayerAuraBySpellID` returns nil for buff aura ID 132404 (Shield Block) even when the buff is physically active — a separate Midnight 12.0 API inconsistency that was discovered first but also moot given the taint restriction.

---

### Fix (v1.5.5)

`Combat/AuraTracker.lua` completely rewritten to use cast-event-based uptime windows:

- Listens for `ABILITY_USED` events (fired from `UNIT_SPELLCAST_SUCCEEDED`)
- Each `uptimeBuff` entry declares `castSpellId` (single trigger) or `castSpellIds` (list) plus `buffDuration`
- On cast: opens a time window or max-extends expiry on refresh — no close/reopen gap
- 0.25s expiry-checker ticker closes windows when `buffDuration` lapses
- `COMBAT_END` closes open windows, capping at `currentExpiry` if the buff already lapsed

No contact with `aura.spellId` anywhere. Not affected by taint.

**Specs updated:**

| Spec | Buff | castSpellId / castSpellIds | buffDuration |
|---|---|---|---|
| Protection Warrior | Shield Block (132404) | 2565 | 6s |
| Protection Paladin | Shield of the Righteous (132403) | 53600 | 4.5s |
| Guardian Druid | Ironfur (192081) | 192081 | 7s |
| Vengeance DH | Demon Spikes (203720) | 203720 | 6s |
| Augmentation Evoker | Ebon Might (395152) | 395152 | 10s |
| Fury Warrior | Enrage (184362) | {23881, 184367} | 8s |

Fury Warrior Enrage uses `castSpellIds` (multi-trigger): both Bloodthirst (23881) and Rampage (184367) apply/extend Enrage in current retail.

**GitHub issue:** #132 (created and closed in v1.5.5)
