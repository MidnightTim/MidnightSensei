# Feature: Full Localization Pass — German + French + Complete UI String Pass

**Version:** 1.6.5
**Date:** May 10, 2026
**Type:** Feature / Localization

## Summary

All hardcoded English strings in `UI.lua` have been replaced with `L["KEY"]` references.
Two new locale files have been added: `deDE` (German) and `frFR` (French), joining the
existing `enUS` (baseline) and `esES` (Spanish) files.

## Architecture

- `Locales/enUS.lua` — always loads; provides all defaults for every key
- `Locales/esES.lua`, `deDE.lua`, `frFR.lua` — each early-returns if locale doesn't match, then overrides only its own keys; missing keys silently fall back to English
- TOC load order: enUS → esES → deDE → frFR (before Core.lua and all other modules)
- Each module accessing localization starts with `local L = MidnightSensei.L`

## Sections Localized in UI.lua

- Grade display and letter grades
- Score panel headers and labels
- Feedback message templates
- Rotation Tracker (subtitle, column headers, fight info, flag descriptions, status badges, legend, not-tracked footer)
- FAQ (all headers, body paragraphs, command references)
- Credits (title, body, close button)
- Update popup (title, message, close button)
- HUD events (in-combat label, fight-too-short label)
- WoW Settings panel (category name, version header, all 5 button pairs)
- Legacy settings panel (panel name, title, subtitle)
- Minimap tooltip (title, left-click line, right-click line, drag line)

## Special Handling

- `DESTRUCT_CONFIRM_PROMPT`: display text is translated; the literal word `Confirm` that the user must type remains English in all locales (matches the hardcoded `if eb:GetText() == "Confirm"` check)
- Format strings (`%s`, `%d`, `%.1f`, `%%`) preserved exactly in all locale files
- WoW color codes (`|cffFFFFFF...|r`) preserved in all locale files
- Special characters use UTF-8 escape sequences (e.g., `\xC3\xB6` for ö)

## Files Changed

- `UI.lua` — all hardcoded strings replaced with L["KEY"] references
- `Locales/enUS.lua` — baseline; no changes (was already complete from prior pass)
- `Locales/esES.lua` — no changes (was already complete)
- `Locales/deDE.lua` — NEW: ~350 keys, German translation
- `Locales/frFR.lua` — NEW: ~350 keys, French translation
- `MidnightSensei.toc` — added deDE and frFR to load order
