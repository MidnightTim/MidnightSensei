# Midnight Sensei v1.7.0 — Release Notes
**Date:** June 2, 2026

## Overview

Version 1.7.0 introduces Hard Mode — a scoring toggle for players who have mastered their rotation and want a greater challenge. This release also fixes a HUD text overflow bug, adds Sigil of Flame tracking for Vengeance Demon Hunters, and removes a dead options toggle that served no purpose.

---

## Hard Mode Scoring Toggle

Players have been reporting consistently high scores (90–100) after learning their rotations — which is the intended outcome. For those who want to push further, Hard Mode tightens scoring across all components, making top scores harder to achieve.

**How to access:** Click the cog icon on the HUD to open the context menu. The Hard Mode slider sits near the top. Click it to toggle — the menu stays open so you can flip it without reopening. When active, the title bar turns red as a persistent visual reminder.

The setting persists per character.

---

## HUD: Boss Name Overflow Fixed

On boss fights with long encounter names, the label line combining the boss name and grade label overflowed the right edge of the HUD frame. The text was rendering outside the frame boundary into the game world.

**Fix:** Boss name and grade label are now on separate lines. A width constraint prevents any future overflow regardless of name length.

---

## Vengeance DH: Sigil of Flame Now Tracked

Sigil of Flame (204596) was absent from Vengeance Demon Hunter rotation tracking despite being a baseline ability on a 30-second cooldown. Players were not receiving feedback or scoring credit for its use.

**Fix:** Added to Vengeance rotational spells. The Rotation Tracker window will now show CAST/MISSED/SHORT status for Sigil of Flame.

---

## Options: Removed Non-Functional Toggle

The "Encounter condition adjustment" checkbox in the Options panel had no implementation — it saved a setting that nothing ever read. Removed to reduce clutter.
