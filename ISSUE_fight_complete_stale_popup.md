## [Bug] Fight Complete window doesn't refresh when left open across fights

**Description:** Reported by users: if the Fight Complete popup is left open and another fight finishes, the popup keeps showing the old fight's results - it doesn't update to reflect the new fight, even though the small main HUD updates correctly.

**Context:** `UI.OnCombatEnd(result)` runs after every fight and updates the small main HUD frame, but it never touched the separate Fight Complete popup window at all. If that popup was already open from an earlier fight, nothing ever told it to refresh.

**Fix:** `UI.OnCombatEnd` now checks whether the Fight Complete popup is currently open, and if so, repopulates it with the new fight's result. A fight too short to be scored (`result == nil`) deliberately does not refresh or clear the popup, so a quick trash pull right after a boss kill doesn't erase the boss result someone is still reviewing.

**Steps to reproduce (before fix):** Open the Fight Complete window after a fight, don't close it, complete another fight - the window keeps showing the first fight's grade/score/feedback instead of the new one.
