# Commit — Midnight Sensei v1.3.10

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Branch:** main
**Tag:** v1.3.10

---

## Summary

HUD title strip buttons, Boss Board clickable rows with permanent feedback storage, three toggle bugs fixed, window stacking resolved, Clear History safety gate, Demonology spec pass against live Midnight 12.0 export, sub-80 login warning.

---

## Changed Files

- `Core.lua` — version, changelog, level gate login warning, /ms debug bossboard repair command
- `UI.lua` — HUD gear/X buttons, Review Fight repositioned and toggled, Boss Board button, Fight Complete strata/position, window positions, Clear History removed from History panel, Clear History added to Debug Tools with confirmation dialog
- `Analytics.lua` — bossBests schema expanded with bestFeedback, bestComponents, bestDuration, bestGradeLabel
- `BossBoard.lua` — description text, clickable rows, RepairIdentity(), ingest feedback backfill, identity fallback fixes, toggle fix
- `Leaderboard.lua` — LB.Toggle() double-call fix

---

## Commits

### feat(ui): HUD gear icon and X button in title strip
`Interface\\Buttons\\UI-OptionsButton` texture used for gear icon (12x12px). Plain X button. Both sit in title strip right side. Gear opens context menu replacing right-click handler. X hides frame. Fight timer shifted left. `OnMouseDown` right-click handler removed.

### feat(ui): HUD button layout overhaul
Review Fight moved to centre zone above separator — 90px wide, centred, appears only after fight completes. Boss Board button added to permanent bottom-left. Bottom row: Boss Board (left) | Leaderboard (right).

### feat(bossboard): clickable rows open Encounter Detail feedback popup
`OnMouseUp` handler added to each row. Builds synthetic enc table from bossBests entry and calls `UI.ShowEncounterDetail`. Tooltip shows "Click to view feedback" in accent cyan when bestFeedback is populated.

### feat(bossboard): permanent feedback storage in bossBests
`bestFeedback`, `bestComponents`, `bestDuration`, `bestGradeLabel` added to bossBests schema in Analytics.lua. Written at fight end on both create and score-update paths. Never subject to the 200-encounter rolling cap. Ingest backfills these fields from encounter history on both added and updated paths.

### feat(bossboard): description text
One-line description below title bar: "Your all-time highest score per boss in Midnight — click any row to review your best performance feedback". Frame height 520 → 540. Tab/sort/scroll all shifted down 16px.

### fix(bossboard): BB.Toggle() required two clicks to open
Added explicit `f:Hide()` after `CreateBossBoardFrame` frame creation. Rewrote `BB.Toggle()` to reference `bbFrame` directly rather than routing through `BB.Show()`. Eliminates fragile double-call path.

### fix(leaderboard): LB.Toggle() same double-call pattern
`LB.Toggle()` and `LB.Show()` rewritten to reference `lbFrame` directly. Same fix as Boss Board.

### fix(ui): Review Fight toggle — permanently nil upvalue
`reviewBtn` closure captured `resultFrame` upvalue at line ~860 but `resultFrame` was declared at line ~989. Lua captures the slot at compile time — upvalue was permanently nil. Fixed with `_G["MidnightSenseiResult"]` lookup at click time.

### fix(ui): window stacking and overlap
Fight Complete strata raised `HIGH` → `DIALOG`. Fight Complete anchors `TOPLEFT` to HUD `TOPRIGHT` on first open. Default positions spread: History CENTER -340, BossBoard CENTER +80, Leaderboard CENTER +380. History/Leaderboard buttons inside Fight Complete now close it before opening.

### feat(ui): Clear History moved to Debug Tools with confirmation
Removed from Grade History panel. Added under Recovery Tools in Debug Tools with red-tinted row styling. Clicking opens blocking `DIALOG` confirmation: "This will permanently delete all fight history. This action cannot be undone." Confirms to clear `CharDB.encounters` and `Analytics.LastResult`.

### fix(bossboard): identity repair — updated path did not apply fallback
`updated` path previously used `if enc.charName then` guard — nil fields on legacy encounters skipped the patch silently. Changed to `enc.charName or fallbackChar or existing.charName` on all three paths.

### feat(bossboard): BB.RepairIdentity() — /ms debug bossboard repair
New function and slash command. Bypasses score comparison entirely. Calls `Core.DetectSpec()` first. Stamps current character/spec onto every bossBests entry showing `?`. Prints `patched: N entries`.

### fix(bossboard): Core.DetectSpec() called at ingest start
Ensures `Core.ActiveSpec` is populated before fallback identity resolution. Prints yellow warning if spec still unresolved after detection.

### fix(spec-db/demonology): Midnight 12.0 pass against live export
Malevolence 458355 → 442726. Summon Vilefiend and Power Siphon removed. Added majorCooldowns: Summon Doomguard (1276672), Grimoire: Fel Ravager (1276467), Diabolic Ritual (428514). Added rotationalSpells: Hand of Gul'dan (172), Demonbolt (264178), Doom (460551 talentGated), Dark Harvest (1257052 talentGated).

### feat(core): sub-level 80 login warning
2-second deferred `UnitLevel("player")` check after `PLAYER_LOGIN`. Prints orange warning if level > 0 and < 80. No output for level 80+ characters.

### chore(core): version bump to 1.3.10, changelog added
