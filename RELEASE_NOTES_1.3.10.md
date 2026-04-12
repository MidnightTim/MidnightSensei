# Midnight Sensei v1.3.10 — HUD Overhaul, Boss Board Feedback, Demonology Pass & Quality of Life

## Summary

1.3.10 is a broad quality of life release. The HUD gets a proper title strip with a gear menu button and X close button. The Boss Board gains clickable rows with persistent feedback storage. A series of first-click toggle bugs are fixed across Boss Board, Leaderboard, and Review Fight. Windows no longer stack on top of each other. The Demonology spec database is corrected against a live Midnight 12.0 spell and talent export. Clear History is moved behind a confirmation gate.

---

## HUD Title Strip

The HUD now has two small buttons in the title strip, replacing the undiscoverable right-click context menu:

**Gear icon** — uses WoW's native `Interface\\Buttons\\UI-OptionsButton` texture. Neutral grey at rest, turns accent cyan on hover. Tooltip: "Menu". Opens the full context menu.

**X button** — plain text X, turns red on hover. Tooltip: "Hide HUD". Hides the frame.

The right-click handler on the HUD frame has been removed — the gear icon fully replaces it.

---

## HUD Button Layout

| Before | After |
|---|---|
| `>> Review Fight` (bottom-left, always visible) | `Boss Board` (bottom-left, always visible) |
| `Leaderboard` (bottom-right, always visible) | `Leaderboard` (bottom-right, always visible) |
| *(nothing in centre zone)* | `Review Fight` (centre, 90px, appears after fight) |

**Review Fight** now appears in the centre zone above the separator only after a fight completes. It toggles — first click opens Fight Complete, second click closes it.

**Boss Board** replaces Review Fight in the permanent bottom-left position.

---

## Boss Board Improvements

### Description Text
A one-line description now appears below the title bar explaining the board's purpose: *"Your all-time highest score per boss in Midnight — click any row to review your best performance feedback"*

### Clickable Rows with Persistent Feedback
Every row in the Boss Board is now clickable. Left-clicking opens the Encounter Detail popup showing the full feedback and component score breakdown from that best run.

**Feedback is now stored permanently in `bossBests`** — not in `CharDB.encounters`. Previously, feedback only lived in the rolling 200-encounter history. Once a fight aged out of the cap the feedback was gone. Now `bestFeedback`, `bestComponents`, `bestDuration`, and `bestGradeLabel` are written directly to `bossBests` in `CharDB.bests` at fight end — a permanent store that is never trimmed.

The ingest command (`/ms debug bossboard ingest`) also backfills these fields from existing encounter history. Run it once after updating to capture feedback for historical entries while they are still within the 200-entry window.

### Identity Repair Improvements
- `BB.RepairIdentity()` added — `/ms debug bossboard repair` patches `?` identity fields on all existing entries without any score comparison
- `Core.DetectSpec()` now called at ingest start to ensure spec is populated before fallback resolution
- The `updated` path (score is better) now applies identity fallback for nil fields — previously only explicit `enc` values were applied

---

## Toggle Bug Fixes

Three separate toggle bugs fixed:

**Boss Board and Leaderboard — two clicks to open.** `CreateFrame` does not guarantee a hidden initial state. Both `BB.Toggle()` and `LB.Toggle()` routed through `Show()` which called the create function a second time, creating a fragile double-call path. Fixed by adding explicit `f:Hide()` after frame creation and rewriting `Toggle` to reference the module-level frame variable directly.

**Review Fight — did not close on second click.** The `reviewBtn` closure was defined at line ~860 but `resultFrame` was not declared until line ~989. In Lua, a closure captures the upvalue slot at compile time — the closure permanently captured a `nil` reference that never updated. Fixed by using `_G["MidnightSenseiResult"]` to look up the frame by its registered global name at click time.

---

## Window Overlap Fixes

Windows no longer spawn on top of each other.

**Fight Complete strata raised to `DIALOG`** — renders above `HIGH`-strata windows (Grade History, Leaderboard). Fight Complete now always floats on top.

**Fight Complete position** — anchors `TOPLEFT` to the `TOPRIGHT` of the HUD on first open (8px gap). Falls back to `CENTER +160, +60` if the HUD is hidden.

**Default positions spread:**
| Window | Before | After |
|---|---|---|
| Grade History | CENTER -80, 0 | CENTER -340, 0 |
| Fight Complete | CENTER +120, 0 | Anchored to HUD right edge |
| Boss Board | CENTER 0, 0 | CENTER +80, 0 |
| Leaderboard | CENTER +240, 0 | CENTER +380, 0 |

**History and Leaderboard buttons inside Fight Complete** now close Fight Complete before opening the target panel.

---

## Clear History Safety Gate

The Clear History button was accessible directly on the Grade History panel with no confirmation. A misclick permanently deleted all recorded encounter history.

- **Removed** from Grade History panel
- **Added to Debug Tools → Recovery Tools** with red-tinted styling
- Clicking opens a blocking `DIALOG`-strata confirmation: *"This will permanently delete all fight history. This action cannot be undone."*
- Requires explicit **Yes, Delete All** confirmation

---

## Demonology Warlock Spec Pass

Verified against a live Midnight 12.0 spell export and talent snapshot from the new debug tools.

### Corrections
| Change | Detail |
|---|---|
| Malevolence ID `458355` → `442726` | Confirmed in Midnight 12.0 spell list |
| Summon Vilefiend `264119` removed | Not present in Midnight 12.0 |
| Power Siphon `264170` removed | Not present in Midnight 12.0 |

### Added to `majorCooldowns`
| Spell | ID | nodeID |
|---|---|---|
| Summon Doomguard | 1276672 | 101917 |
| Grimoire: Fel Ravager | 1276467 | 110197 |
| Diabolic Ritual | 428514 | 94855 |

### Added to `rotationalSpells`
| Spell | ID | Notes |
|---|---|---|
| Hand of Gul'dan | 172 | Core Soul Shard spender — was missing entirely |
| Demonbolt | 264178 | Primary Demonic Core consumer |
| Doom | 460551 | Talent-gated, nodeID 110200 |
| Dark Harvest | 1257052 | Talent-gated |

---

## Level Gate Notification

Sub-level 80 characters now receive a clear warning on login:

> *"This addon is designed for level 80+ content. Fight tracking and grading are disabled until you reach level 80."*

Printed 2 seconds after login to ensure `UnitLevel()` returns an accurate value. Level 80+ characters see nothing additional.

---

## Open Items (carry to 1.3.11+)

- Tempest (454009) — VERIFY cast ID vs aura ID
- Call of the Ancestors (443450) — VERIFY
- Thrill of the Hunt (246152), Precise Shots (342776), Schism (204263), Predatory Swiftness (69369) — VERIFY C_UnitAuras
- Devastation Evoker resource enum (17) — VERIFY
- iLvl plausibility integrity gate — backlog
- Detail share via REQD_DETAIL whisper — backlog

---

*Midnight Sensei — Combat performance coaching for all 13 classes*
*Created by Midnight - Thrall (US)*
