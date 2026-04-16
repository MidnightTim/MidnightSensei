--------------------------------------------------------------------------------
-- Midnight Sensei: Combat/ResourceTracker.lua
-- Edge-triggered overcap detection for the player's primary resource.
--
-- Moved from Analytics/Engine.lua (SESSION_READY tick handler).
-- Polls UnitPower every 0.5 s during combat.  Fires once per overcap entry —
-- not every tick — so that one careless moment counts as one event.
--
-- When overcap is detected, emits "MS_OVERCAP_DETECTED" via Core.Emit so that
-- Engine.lua can queue the real-time warning in the feedback ticker without
-- needing a direct reference to Engine's private feedbackQueue.
--
-- Exposes on MS.CombatLog:
--   GetOvercapEvents() → number  (distinct overcap entries this fight)
--------------------------------------------------------------------------------

MidnightSensei        = MidnightSensei        or {}
MidnightSensei.Combat = MidnightSensei.Combat or {}

local MS   = MidnightSensei
local Core = MS.Core
local CL   = MS.CombatLog

-- ── Private state ────────────────────────────────────────────────────────────
local overcapState  = false   -- true while currently overcapped
local overcapEvents = 0       -- count of distinct overcap entries this fight
local fightActive   = false

-- Event key used to signal overcap to Engine.lua for real-time feedback
local OVERCAP_EVENT = "MS_OVERCAP_DETECTED"

-- ── Public getter ─────────────────────────────────────────────────────────────
function CL.GetOvercapEvents()
    return overcapEvents
end

-- ── Combat start / end resets ────────────────────────────────────────────────
Core.On(Core.EVENTS.COMBAT_START, function()
    fightActive   = true
    overcapState  = false
    overcapEvents = 0
end)

Core.On(Core.EVENTS.COMBAT_END, function()
    fightActive = false
end)

-- ── Overcap tick ─────────────────────────────────────────────────────────────
-- Registered once on SESSION_READY — the tick runs for the entire session.
-- Uses pcall around UnitPower to tolerate taint in Midnight 12.0.
Core.On(Core.EVENTS.SESSION_READY, function()
    Core.RegisterTick("overcapCheck", 0.5, function()
        if not fightActive then return end
        local spec = Core.ActiveSpec
        if not spec or not spec.overcapAt   then return end
        if not spec.resourceType            then return end

        local ok, cur = pcall(UnitPower, "player", spec.resourceType)
        if not ok or type(cur) ~= "number"  then return end

        local cap             = spec.overcapAt
        local isNowOvercapped = (cur >= cap)

        if isNowOvercapped and not overcapState then
            -- Edge: entered overcap
            overcapEvents = overcapEvents + 1
            overcapState  = true
            Core.Emit(OVERCAP_EVENT, spec.resourceLabel or "resource", cur, cap)
        elseif not isNowOvercapped and overcapState then
            -- Edge: left overcap — reset so next entry counts as a new event
            overcapState = false
        end
    end)
end)
