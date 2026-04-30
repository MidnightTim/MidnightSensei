# Midnight Sensei v1.5.8 — Release Notes

This release corrects Protection Paladin rotational tracking: Holy Shock was never pressed and has been removed, Blessed Hammer gains an alt ID fix so its casts are detected, and three missing rotational spells (Judgment, Hammer of Wrath, Word of Glory) are now tracked. Two Templar Hero Spec abilities are added as informational entries.

---

## Protection Paladin: Holy Shock removed

Holy Shock (20473) was added to the Protection rotation list during the April 2026 spell tree audit — it appears in the Protection spellbook — but it is never pressed in combat. The verify report showed `FAIL  Holy Shock  NOT SEEN  [ROT]` on every fight, generating false coaching feedback. Removed from `rotationalSpells`. No longer tracked or scored.

---

## Protection Paladin: Blessed Hammer alt ID 204019

**What broke:** Blessed Hammer showed `FAIL — NOT SEEN` in the Verify Report on every fight. Session log confirmed x61 casts all fired as spell ID **204019**, while the spec tracked spellbook ID 35395. Zero casts were ever credited.

**Fix:** Added `altIds = {204019}` to the Blessed Hammer entry. The cast tracker now routes all 204019 events to the 35395 tracking entry. Verify shows `PASS (via alt id=204019)`.

---

## Protection Paladin: Judgment, Hammer of Wrath, Word of Glory added

Three rotational spells were missing from Protection Paladin tracking entirely:

- **Judgment (275779)** — primary Holy Power generator. Session log x33 in a 3:42 fight. Added with `minFightSeconds = 15`.
- **Hammer of Wrath (1241413)** — available during execute phase (target below 20%) or during Avenging Wrath. Talent-gated. Session log x19. Added with `talentGated = true, minFightSeconds = 30`.
- **Word of Glory (85673)** — Holy Power spender heal used for emergency self-healing. Talent-gated. Session log x2. Added with `talentGated = true, minFightSeconds = 30`.

---

## Protection Paladin: Templar Hero Spec tracking

Two Templar Hero Spec abilities are now tracked as informational entries (`isUtility = true, talentGated = true`). They will appear in verify reports for Templar-specced players and are never scored against.

**Hammer of Light (427453)** — Light's Guidance talent (node 95180) causes Divine Toll to be replaced by Hammer of Light for 20 seconds after cast. Player-pressed, costs 5 Holy Power. Session log x6 per fight.

**Divine Hammer (198137)** — Divine Hammer talent (node 109747) causes Divine Toll to passively summon spinning hammers for 8 seconds. Not player-pressed. Session log x20 per fight.
