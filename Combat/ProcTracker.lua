--------------------------------------------------------------------------------
-- Midnight Sensei: Combat/ProcTracker.lua
-- Tracks proc buff gain and consumption cycles for the player using UNIT_AURA.
--
-- For each spec.procBuffs entry, detects when the buff appears (proc gained) and
-- disappears (proc consumed or expired), accumulating total time held per proc.
-- Analytics uses this to penalise holding procs longer than their maxStackTime.
--
-- Exposes on MS.CombatLog:
--   GetAllProcs() →
--     [spellID] = { gained, totalActiveTime }
--
-- Internal:
--   CL._auraProcHandler(unit)  — assigned here; dispatched by CombatLog.lua
--------------------------------------------------------------------------------

MidnightSensei        = MidnightSensei        or {}
MidnightSensei.Combat = MidnightSensei.Combat or {}

local MS   = MidnightSensei
local Core = MS.Core
local CL   = MS.CombatLog

-- ── Private state ────────────────────────────────────────────────────────────
-- [spellID] = { gained, totalActiveTime, lastGained, isActive }
local procData    = {}
local fightActive = false

-- ── GetAllProcs ───────────────────────────────────────────────────────────────
-- Returns the current proc data table.  Called by Engine.lua's BuildState after
-- COMBAT_END has closed any still-active proc windows.
function CL.GetAllProcs()
    return procData
end

-- ── UNIT_AURA handler ─────────────────────────────────────────────────────────
-- Registered as CL._auraProcHandler — dispatched by CombatLog.ProcessUnitAura.
-- Scans spec.procBuffs on every player aura change, recording gain/lose events.
CL._auraProcHandler = function(unit)
    if not fightActive or unit ~= "player" then return end
    local spec = Core.ActiveSpec
    if not spec or not spec.procBuffs then return end

    local now = GetTime()
    for _, proc in ipairs(spec.procBuffs) do
        local data = procData[proc.id]
        if data then
            local aura = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
                         and C_UnitAuras.GetPlayerAuraBySpellID(proc.id)
            local isActive = (aura ~= nil)

            if isActive and not data.isActive then
                -- Proc gained
                data.isActive   = true
                data.lastGained = now
                data.gained     = data.gained + 1
            elseif not isActive and data.isActive then
                -- Proc consumed or expired
                data.isActive        = false
                data.totalActiveTime = data.totalActiveTime + (now - data.lastGained)
            end
        end
    end
end

-- ── Combat start — reset and pre-populate ────────────────────────────────────
Core.On(Core.EVENTS.COMBAT_START, function()
    fightActive = true
    procData    = {}

    local spec = Core.ActiveSpec
    if not spec or not spec.procBuffs then return end
    for _, proc in ipairs(spec.procBuffs) do
        procData[proc.id] = {
            gained          = 0,
            totalActiveTime = 0,
            lastGained      = 0,
            isActive        = false,
        }
    end
end)

-- ── Combat end — close any still-active proc windows ─────────────────────────
-- Runs before Engine.lua's COMBAT_END handler.  Closes open windows so
-- GetAllProcs returns accurate totals when CalculateGrade reads them.
Core.On(Core.EVENTS.COMBAT_END, function()
    fightActive = false
    local now   = GetTime()
    for _, data in pairs(procData) do
        if data.isActive and data.lastGained > 0 then
            data.totalActiveTime = data.totalActiveTime + (now - data.lastGained)
            data.isActive        = false
        end
    end
end)
