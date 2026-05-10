# Midnight Sensei v1.6.4 — Release Notes

**Date:** May 2026 | **Patch:** Midnight 12.0.5

---

## MM Hunter — Dark Ranger Kill Shot Fix

Marksmanship Hunters running the Dark Ranger hero talent were receiving a false "never used Kill Shot" coaching note every fight. The Dark Ranger talent (node 94987) replaces Kill Shot entirely with Black Arrow — the spell is not in the player's spellbook, so the feedback was wrong.

Kill Shot now has `suppressIfTalent = 94987`. Black Arrow (466932) is added as a tracked rotational ability for Dark Ranger players. Kill Shot continues to track normally for non-Dark Ranger MM Hunters.

---

## Assassination Rogue — Thistle Tea Added

Thistle Tea (381623) was absent from the Assassination spec DB despite being a meaningful burst cooldown. It grants 3 charges (1 min recharge each) and is used proactively alongside Kingsbane and Deathmark. Now tracked as a `talentGated` majorCooldown with coaching that communicates all three charges should be spent across a fight.

---

## Paladin Holy — Beacon Choice Node Tracking

Beacon of Faith (156910) and Beacon of Virtue (200025) are now both tracked as `healerConditional talentGated` abilities. They occupy the same choice node (81554) and are mutually exclusive — only the variant the player has taken will appear in feedback.

- **Beacon of Faith**: Setup action tracked as a per-fight application on a second beacon target. No penalty if skipped on fast fights.
- **Beacon of Virtue**: Replaces Beacon of Light with a 15-second AoE healing cooldown. Tracked on cooldown usage; no penalty on short fights.

Mutual `suppressIfTalent` ensures clean detection — if Beacon of Virtue was cast, Beacon of Faith is ignored, and vice versa.

---

## Shaman Restoration — Nature's Swiftness and Ancestral Swiftness

Nature's Swiftness (378081) was missing from Restoration's tracked cooldowns entirely. It is now added as a `talentGated` CD on a 1-minute cooldown.

Ancestral Swiftness (443454, Farseer hero talent) was already tracked for Elemental Shaman but was missing for Restoration. It is now added for Restoration as well.

When a Restoration Shaman is on the Farseer path, Nature's Swiftness is replaced by Ancestral Swiftness. Nature's Swiftness is suppressed via `suppressIfTalent = 443454` so players on Farseer see Ancestral Swiftness tracked and receive no false penalty for the spell they no longer have.
