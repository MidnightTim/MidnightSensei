# MidnightSensei v1.4.12 Release Notes

---

## Overview

1.4.12 is a Resto Shaman correctness pass, a verify system improvement, and a bug fix to a feedback string that referenced Discipline Priest mechanics on all healer specs.

---

## Resto Shaman: Healing Rain Alt-ID Fix

When the **Totem hero talent path** is active, casting Healing Rain fires spell ID `456366` instead of the baseline `73920`. Previously the tracker saw `456366` as an unknown spell and reported Healing Rain as never used — generating incorrect feedback even when the player was casting it every 30 seconds.

A new `altIds` field on the Healing Rain rotational entry maps `456366 → 73920` at combat start. Casts of either ID now credit the same tracking slot. The verify report reflects this: `456366` no longer appears in OTHER SPELLS, and Healing Rain shows PASS with a `(via alt id=456366)` note when the Surging Totem path is active.

---

## Resto Shaman: Wind Shear and Purify Spirit

**Wind Shear** (id=57994) added as a tracked interrupt — `isInterrupt = true`, no penalty for not using it, reminder note at fight end.

**Purify Spirit** (id=77130) added as a tracked utility — `isUtility = true`, no penalty, reminder note at fight end.

---

## Verify System: Alt-ID Awareness

The verify PASS/FAIL display now understands `altIds`. When a spell's primary ID was never cast directly but an alt ID was seen, the spell shows PASS with an annotation rather than FAIL. Alt IDs are also excluded from the OTHER SPELLS section so they don't create noise.

This infrastructure is available for any future spec entry where the game fires a different spell ID for the same ability under a talent or hero path.

---

## Feedback: Atonement Language Removed

The generic healer low-activity note read: *"When the group is stable, fill downtime with damage spells to maintain throughput and Atonement value."*

"Atonement value" is a Discipline Priest mechanic. The note fires for all healer specs when activity score is below 70 — Resto Shamans, Holy Paladins, and others were receiving Disc-specific coaching. Removed.

---

## Debug: `/ms debug auras`

New command that dumps all active player buff IDs and names to chat. Use it while a proc or buff is active to find its spell ID for spec DB additions. Identified the Tidal Waves aura (id=53390) during this release cycle.
