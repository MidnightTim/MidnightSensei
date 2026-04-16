--------------------------------------------------------------------------------
-- Midnight Sensei: Combat/CombatLog.lua
-- Namespace initialisation and UNIT_AURA dispatcher.
--
-- This file loads first in the Combat/ group.  It creates the MS.CombatLog
-- public namespace and defines ProcessUnitAura — the single entry point that
-- Core.lua calls on every UNIT_AURA event.  Each tracker submodule that needs
-- aura events registers its handler by assigning to the _auraUptimeHandler /
-- _auraProcHandler slots below, which ProcessUnitAura dispatches to at runtime.
--
-- Public namespace (backwards-compatible — Analytics callers unchanged):
--   MS.CombatLog.ProcessUnitAura(unit)
--   MS.CombatLog.GetCdTracking()          → Combat/CastTracker.lua
--   MS.CombatLog.GetRotationalTracking()  → Combat/CastTracker.lua
--   MS.CombatLog.GetTotalGCDs()           → Combat/CastTracker.lua
--   MS.CombatLog.GetActiveGCDs()          → Combat/CastTracker.lua
--   MS.CombatLog.GetOvercapEvents()       → Combat/ResourceTracker.lua
--   MS.CombatLog.GetAllUptimes(duration)  → Combat/AuraTracker.lua
--   MS.CombatLog.GetAllProcs()            → Combat/ProcTracker.lua
--   MS.CombatLog.GetHealingData()         → Combat/HealingTracker.lua
--------------------------------------------------------------------------------

MidnightSensei        = MidnightSensei        or {}
MidnightSensei.Combat = MidnightSensei.Combat or {}

local MS = MidnightSensei

-- MS.CombatLog is the shared public namespace.  Core.lua pre-creates it as {}.
-- We re-declare it here so this file is self-contained if load order shifts.
MS.CombatLog = MS.CombatLog or {}

local CL = MS.CombatLog

--------------------------------------------------------------------------------
-- ProcessUnitAura — called by Core.lua for every UNIT_AURA WoW event.
-- Dispatches to AuraTracker (uptime) and ProcTracker (proc cycles).
-- Both handlers are assigned at file-load time by their respective modules,
-- which load after this file in the TOC — safe because ProcessUnitAura is
-- only ever CALLED at runtime, long after all files have loaded.
--------------------------------------------------------------------------------
function CL.ProcessUnitAura(unit)
    if CL._auraUptimeHandler then CL._auraUptimeHandler(unit) end
    if CL._auraProcHandler   then CL._auraProcHandler(unit)   end
end
