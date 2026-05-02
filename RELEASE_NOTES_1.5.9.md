# Midnight Sensei v1.5.9 — Release Notes

Starting with this release, **Archon.gg is now the primary source for rotation priorities and talent build verification** across all specs. Archon data is derived from top-ranked live parse data and reflects the actual spell IDs that fire in combat — not just spellbook IDs. Secondary sources (Wowhead, Warcraft Logs, SimulationCraft) remain in use for spell node data and methodology. Archon.gg has been added to the in-game Credits panel (`/ms credits`).

This release applies that pivot directly, correcting multiple wrong spell IDs across Rogue specs (all three primary builders were incorrect) and filling rotation gaps across all three Death Knight specs.

---

## Rogue: Spell ID corrections across all three specs

All three Rogue specs shared the same incorrect ID (1752) for their primary builder. Session log data confirmed the correct combat cast IDs:

| Spec | Spell | Was | Now |
|---|---|---|---|
| Assassination | Mutilate | 1752 | 1329 (+ altIds 5374, 27576 for MH/OH hits) |
| Assassination | Envenom | 196819 | 32645 (+ altId 276245) |
| Assassination | Rupture | 1943 | 199672 (Assassination spec-variant) |
| Outlaw | Sinister Strike | 1752 | 193315 |
| Outlaw | Dispatch | 196819 | 2098 |
| Subtlety | Backstab | 1752 | 53 |

Note: 196819 is the correct ID for Eviscerate (Subtlety only) — it was incorrectly applied to Envenom and Dispatch in prior releases.

---

## Rogue: Missing abilities added

- **Fan of Knives (51723)** — Assassination; baseline AoE builder
- **Ambush (8676)** — Assassination; `isUtility talentGated` — stealth opener, situational, never scored against
- **Secret Technique (280719)** — Subtlety; `majorCooldowns talentGated` (guide showed 280720, session log confirmed 280719)
- **Black Powder (319175)** — Subtlety; baseline AoE finisher, 29% total M+ damage in Archon data

---

## Unholy DK: Rotation corrections

- **Festering Scythe (458128)** moved from `majorCooldowns` to `rotationalSpells` — confirmed rotational, not a CD
- **Epidemic (207317)** added to rotational — baseline AoE Runic Power spender
- **Necrotic Coil (1242174)** added as `talentGated` — Forbidden Knowledge; replaces Death Coil during the 30-second Army of the Dead window
- **Death Strike (49998)** and **Death and Decay (43265)** added as `talentGated` rotational

---

## Frost DK: Missing abilities added

- **Remorseless Winter (196771)** — session log x39; baseline; combat cast ID 196771 (spellbook 196770)
- **Frostbane (1228433)** — hero spec talent; `altIds = {1228436}` (both IDs confirmed in session log)
- **Glacial Advance (194913)** — AoE; `talentGated`

---

## Blood DK: Defensive cooldowns added

- **Icebound Fortitude (48792)** — `healerConditional = true`; reactive personal defensive; no penalty on successful fights
- **Anti-Magic Shell (48707)** — `healerConditional = true`; reactive magic absorb
- **Death and Decay (43265)** — `talentGated` rotational AoE
