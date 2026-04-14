# Commit — Midnight Sensei v1.4.5

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Branch:** main
**Tag:** v1.4.5

---

## Summary

Live testing on Balance Druid exposed three classes of bugs: shapeshift spells in tracked CD lists, hero talent choice nodes breaking IsPlayerSpell assumptions, and Analytics gate logic that bypassed talent checks when cdTracking was empty. Full 39-spec shapeshift audit completed. CLEU confirmed blocked in Midnight 12.0. Analytics IsTalentActive rewritten.

---

## Changed Files

- `Core.lua` — version 1.4.5, changelog, Balance spec DB fixes, shapeshift removals, debug rotational enhancements
- `Analytics.lua` — IsTalentActive rewrite, talentGated majorCooldowns IsPlayerSpell gate, else branch gate fix

---

## Commits

### chore: bump version to 1.4.5, update changelog

### fix(spec-db/balance): Incarnation removed, CA suppressed, hero talent builds corrected
- Incarnation: Chosen of Elune (102560) removed from majorCooldowns — shapeshift
- Celestial Alignment (194223, 383410) suppressIfTalent = 102560
- Wrath (5176) suppressIfTalent = 429523 (Lunar Calling / Elune's Chosen)
- Starfire (194153) added as talentGated rotational — Elune's Chosen primary filler
- Starsurge (78674) suppressIfTalent = 1271206 (Star Cascade auto-proc)

### fix(spec-db/guardian): Incarnation: Guardian of Ursoc removed — shapeshift
- 102558 removed from majorCooldowns — "improved Bear Form...freely shapeshift in and out"

### fix(analytics): IsTalentActive rewritten
- IsPlayerSpell fast path added — avoids expensive C_Traits walk for common cases
- C_Traits walk now iterates node.entryIDs not just activeEntry
- Correctly resolves choice nodes where activeEntry and definition spellID diverge

### fix(analytics): talentGated majorCooldowns use IsPlayerSpell only
- Previously fell through to IsTalentActive which returned true for prereq nodes
- CA was being added to cdTracking even when Incarnation replaced it
- talentGated CDs now gated strictly by IsPlayerSpell

### fix(analytics): else branch respects suppressIfTalent and talentGated
- Empty cdTracking path was bypassing all gates, reporting every CD as never used
- Now applies same suppressIfTalent and talentGated checks as setup loop

### fix(core): CLEU fully reverted — protected event in Midnight 12.0
- Both main-chunk and PLAYER_LOGIN RegisterEvent attempts trigger ADDON_ACTION_FORBIDDEN
- Reverted entirely; UNIT_SPELLCAST_SUCCEEDED + CHANNEL_START remain the ceiling

### feat(debug): debug rotational now shows IsPlayerSpell and suppress_IPS per CD
- Surfaces exact IsPlayerSpell state for each majorCooldown entry at runtime
- Critical for diagnosing choice node and shapeshift suppress failures

### chore(spec-db): shapeshift audit complete across all 39 specs
- Elemental Ascendance (114050), Resto Ascendance (114052), Voidform (228260) flagged VERIFY
- Apotheosis (200183), Avatar (107574), Alter Time (342245) confirmed safe
