--------------------------------------------------------------------------------
-- Midnight Sensei: Combat/HealingTracker.lua
-- Tracks the player's effective healing and overheal via COMBAT_LOG_EVENT_UNFILTERED.
--
-- Only the player's own heal events are captured (sourceGUID == player GUID).
-- Returns { done = 0, overheal = 0 } when CLEU is unavailable or restricted
-- (e.g. certain PvP scenarios) — callers treat done == 0 as "data unavailable"
-- and exclude healer efficiency from scoring rather than scoring on 0.
--
-- CLEU SPELL_HEAL payload:
--   ...base, spellID, spellName, school, amount, overhealing, absorbed, critical
--   amount      = effective healing applied
--   overhealing = wasted healing (target already full)
--
-- Exposes on MS.CombatLog:
--   GetHealingData() → { done, overheal }
--------------------------------------------------------------------------------

MidnightSensei        = MidnightSensei        or {}
MidnightSensei.Combat = MidnightSensei.Combat or {}

local MS   = MidnightSensei
local Core = MS.Core
local CL   = MS.CombatLog

-- ── Public getter ─────────────────────────────────────────────────────────────
-- Returns done=0 — callers treat this as "data unavailable" (not zero healing).
function CL.GetHealingData()
    return { done = 0, overheal = 0 }
end

-- ── Note: CLEU restricted in Midnight 12.0 ───────────────────────────────────
-- COMBAT_LOG_EVENT_UNFILTERED is a restricted event in this build — registering
-- it triggers ADDON_ACTION_FORBIDDEN.  Healing tracking is therefore unavailable.
-- GetHealingData() returns done=0, which Scoring.ScoreHealerEfficiency treats as
-- "data unavailable" and returns nil — excluding efficiency from the weighted
-- score rather than penalising with a neutral 75.
-- If a future build lifts the restriction, restore CLEU tracking here.
