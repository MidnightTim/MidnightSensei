[Bug] Devourer: False "Never Used" Feedback — Void Metamorphosis and Reap

**Labels:** `bug` `spec-db` `demon-hunter` `devourer` `fixed-in-1.4.3`
**Fixed in:** v1.4.3 (partial — Void Metamorphosis resolved, Reap pending VERIFY)

## Observed Behaviour

Every Devourer fight produced feedback:
> "Rotational spell(s) never used: Reap, Void Metamorphosis — these are core to your damage output."

Both spells were visibly cast and appearing in damage meter data. `/ms debug rotational` confirmed both IDs were in `rotationalTracking` at fight start with `useCount = 0`.

## Root Cause — Void Metamorphosis `191427`

Metamorphosis is a **shapeshifting spell**. It fires `UPDATE_SHAPESHIFT_FORM` on activation, not `UNIT_SPELLCAST_SUCCEEDED` or `UNIT_SPELLCAST_CHANNEL_START`. The addon tracks casts exclusively via these two events — no listener exists for shapeshift events.

`useCount` was permanently 0 regardless of how many times the player entered Void Metamorphosis.

**Fix:** `191427` removed from `rotationalSpells`. Cannot be tracked via cast events with the current architecture.

## Root Cause — Reap `344862`

`344862` is present in `rotationalTracking` at fight start (confirmed via `/ms debug rotational`). Damage meter confirms the spell was cast and dealt 163K damage. `useCount` stays 0.

**Suspected cause:** The game fires a different spell ID for the Devourer-specific Reap at runtime than the ID captured in the spell snapshot. This is the same spec-variant issue previously found with:
- Festering Strike: `85092` → `316239` (Unholy DK)
- Kill Command: `34026` → `259489` (Survival Hunter)
- Envenom: `32645` → `196819` (Assassination Rogue)

**Status:** Flagged VERIFY. Requires `/ms verify` in-game on a Devourer character during combat to capture the actual cast ID from `UNIT_SPELLCAST_SUCCEEDED`.
