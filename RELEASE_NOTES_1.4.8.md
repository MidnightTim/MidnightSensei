# Midnight Sensei — Release Notes v1.4.8

**Date:** April 2026  
**Author:** Midnight - Thrall (US)

---

## Overview

Single targeted fix: Feral Druids running Frantic Frenzy hero talent builds were receiving false "never used Feral Frenzy" feedback every fight. This release adds the suppression gate that eliminates the false penalty.

---

## Fixes

### Feral Druid: False "never used Feral Frenzy" on Frantic Frenzy builds

**What broke:** Feral Frenzy (274837) and Frantic Frenzy (1243807) are mutually exclusive replacement talents — Frantic Frenzy's tooltip reads "Replaces Feral Frenzy." Both were tracked as `talentGated = true` with no suppression relationship.

**Why it failed:** Frantic Frenzy is a hero talent that upgrades Feral Frenzy. Taking it requires the Feral Frenzy prerequisite node, so `IsTalentActive` strict walk returns `true` for both spell IDs simultaneously. With Feral Frenzy tracked but never castable (it's been replaced), every Frantic Frenzy build received a false "never used" penalty.

This is the same prerequisite-node pattern that produced false Celestial Alignment feedback before v1.4.7 fixed it with `suppressIfTalent = 102560`.

**Fix:** Added `suppressIfTalent = 1243807` to the Feral Frenzy entry. When Frantic Frenzy is active, Feral Frenzy is excluded from tracking entirely.

---

## Audit Note

A full suppressIfTalent audit was performed across all 13 classes (39 specs) as part of this release. Feral Druid was the only gap found. All other replacement-talent gates are correctly applied.
