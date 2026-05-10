# Midnight Sensei v1.6.5 Release Notes

**Release Date:** May 10, 2026
**Author:** Midnight - Thrall (US)

---

v1.6.5 is a localization release. Every UI string that was previously hardcoded in English is now routed through the addon's localization table, and two new locale files ship alongside the existing English and Spanish translations: **German (deDE)** and **French (frFR)**. This release also corrects a Demon Hunter Devourer interrupt misclassification introduced in v1.6.3.

---

## Feature: Full Localization Pass

All ~350 display strings in the addon are now locale-aware. The baseline (`enUS.lua`) always loads first and provides a complete fallback for every key; each locale file loads after it and overrides only its own language. Players running the game in German or French will now see fully translated coaching text, grade labels, settings panels, the FAQ, the Rotation Tracker, the HUD overlay, and the minimap tooltip.

**Locale files in this release:**
- `Locales/enUS.lua` — English (baseline, pre-existing)
- `Locales/esES.lua` — Spanish (pre-existing, added prior to v1.6.5)
- `Locales/deDE.lua` — German (NEW in v1.6.5)
- `Locales/frFR.lua` — French (NEW in v1.6.5)

**Localized sections:** grade labels, score panel, feedback messages, Rotation Tracker (column headers, flag descriptions, status badges, fight info, legend), FAQ (all headers and body text), Credits, Update Popup, HUD events, WoW Settings panel (all buttons and category name), legacy settings panel, minimap tooltip.

**Note:** The data-destruction confirmation dialog requires the user to type the word `Confirm` — this word is kept in English in all locales to match the hardcoded comparison in the addon's code.

---

## Bug Fix: DH Devourer — Interrupt Corrected

Consume Magic (278326) was incorrectly flagged as `isInterrupt = true` in the Demon Hunter Devourer spec since v1.6.3. Consume Magic is a purge (dispels one beneficial magic effect) — it is not an interrupt and has no lockout.

**Fix:** Disrupt (183752) is restored as the sole tracked interrupt for Devourer. Consume Magic is reclassified to `isUtility = true, talentGated = true` — it continues to be tracked as situational utility and players will receive appropriate coaching if they never use it in keys where purges matter.

---

## Files Changed

| File | Change |
|---|---|
| `UI.lua` | All hardcoded English strings replaced with `L["KEY"]` references |
| `Locales/esES.lua` | Pre-existing Spanish locale (shipped prior to v1.6.5; no changes) |
| `Locales/deDE.lua` | NEW — German locale, ~350 keys |
| `Locales/frFR.lua` | NEW — French locale, ~350 keys |
| `Specs/DemonHunter.lua` | Devourer: Disrupt restored as interrupt; Consume Magic → isUtility |
| `Core.lua` | CHANGELOG entry for v1.6.5; version fallback bumped to 1.6.5 |
| `MidnightSensei.toc` | Version bumped to 1.6.5; deDE + frFR added to load order |
