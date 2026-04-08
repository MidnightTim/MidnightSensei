--------------------------------------------------------------------------------
-- Midnight Sensei: CombatLog.lua
-- Aura tracking via UNIT_AURA + C_UnitAuras (Midnight 12.0)
--
-- COMBAT_LOG_EVENT_UNFILTERED is fully restricted in this WoW build.
-- We use UNIT_AURA instead: Core.lua dispatches CL.ProcessUnitAura(unit).
--
-- APIs used:
--   C_UnitAuras.GetPlayerAuraBySpellID(spellID)       — player buff/debuff lookup
--   C_UnitAuras.GetAuraDataByIndex(unit, i, filter)   — iterate auras on other units
--------------------------------------------------------------------------------

MidnightSensei           = MidnightSensei           or {}
MidnightSensei.Core      = MidnightSensei.Core      or {}
MidnightSensei.CombatLog = MidnightSensei.CombatLog or {}

local MS   = MidnightSensei
local CL   = MS.CombatLog
local Core = MS.Core or MidnightSensei.Core or {}

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------
local combatActive = false

-- [spellID] = { startTime, totalTime, active, appCount }
local uptimes = {}
-- [spellID] = { startTime, totalTime, active, gainCount }
local procs   = {}

--------------------------------------------------------------------------------
-- Internal helpers
--------------------------------------------------------------------------------
local function EnsureUptime(id)
    if not uptimes[id] then
        uptimes[id] = { startTime = nil, totalTime = 0, active = false, appCount = 0 }
    end
    return uptimes[id]
end

local function EnsureProc(id)
    if not procs[id] then
        procs[id] = { startTime = nil, totalTime = 0, active = false, gainCount = 0 }
    end
    return procs[id]
end

--------------------------------------------------------------------------------
-- Aura query helpers — version-safe
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Aura query helpers — Midnight 12.0 correct APIs
--   Player:      C_UnitAuras.GetPlayerAuraBySpellID(spellID)   → AuraData or nil
--   Other units: C_UnitAuras.GetAuraDataByIndex(unit, i, filter) → iterate by index
--------------------------------------------------------------------------------

-- Check if the player currently has a buff or debuff with the given spellID.
local function PlayerHasAura(spellID)
    return C_UnitAuras.GetPlayerAuraBySpellID(spellID) ~= nil
end

-- NOTE: Enemy unit aura fields (spellId, name, etc.) are all "secret values"
-- in Midnight 12.0 and cannot be read by addons during combat.
-- Only player self-auras via GetPlayerAuraBySpellID are accessible.
-- Enemy debuff uptime tracking is not possible in this WoW build.

-- (Enemy unit enumeration removed — aura fields are secret values in combat)

--------------------------------------------------------------------------------
-- Uptime state machine — called with current isActive state
--------------------------------------------------------------------------------
local function UpdateUptime(id, isActive, now)
    local u = EnsureUptime(id)
    if isActive and not u.active then
        u.startTime = now
        u.active    = true
        u.appCount  = u.appCount + 1
    elseif not isActive and u.active then
        u.totalTime = u.totalTime + (now - u.startTime)
        u.active    = false
        u.startTime = nil
    end
end

local function UpdateProc(id, isActive, now)
    local p = EnsureProc(id)
    if isActive and not p.active then
        p.startTime = now
        p.active    = true
        p.gainCount = p.gainCount + 1
    elseif not isActive and p.active then
        p.totalTime = p.totalTime + (now - p.startTime)
        p.active    = false
        p.startTime = nil
    end
end

--------------------------------------------------------------------------------
-- Combat lifecycle
--------------------------------------------------------------------------------
local function OnCombatStart()
    combatActive = true
    uptimes      = {}
    procs        = {}
end

local function OnCombatEnd()
    combatActive = false
    local now = GetTime()
    for _, u in pairs(uptimes) do
        if u.active and u.startTime then
            u.totalTime = u.totalTime + (now - u.startTime)
            u.active    = false
            u.startTime = nil
        end
    end
    for _, p in pairs(procs) do
        if p.active and p.startTime then
            p.totalTime = p.totalTime + (now - p.startTime)
            p.active    = false
            p.startTime = nil
        end
    end
end

Core.On(Core.EVENTS.COMBAT_START, OnCombatStart)
Core.On(Core.EVENTS.COMBAT_END,   OnCombatEnd)

--------------------------------------------------------------------------------
-- UNIT_AURA dispatcher — called by Core.lua's eventFrame
--------------------------------------------------------------------------------
function CL.ProcessUnitAura(unit)
    if not combatActive then return end
    local spec = Core.ActiveSpec
    if not spec then return end
    local now = GetTime()

    -- Player self-buffs and procs only — enemy debuff tracking is blocked
    -- by Midnight 12.0 secret values. Only "player" unit is checked.
    if unit ~= "player" then return end

    if spec.uptimeBuffs then
        for _, buff in ipairs(spec.uptimeBuffs) do
            UpdateUptime(buff.id, PlayerHasAura(buff.id), now)
        end
    end

    if spec.procBuffs then
        for _, proc in ipairs(spec.procBuffs) do
            UpdateProc(proc.id, PlayerHasAura(proc.id), now)
        end
    end
end

--------------------------------------------------------------------------------
-- Public API  (same signatures as before — Analytics.lua unchanged)
--------------------------------------------------------------------------------

function CL.GetUptimePercent(spellID, duration)
    local u = uptimes[spellID]
    if not u or duration <= 0 then return nil end
    local total = u.totalTime
    if u.active and u.startTime then total = total + (GetTime() - u.startTime) end
    return math.min(100, (total / duration) * 100)
end

function CL.GetAllUptimes(duration)
    local result = {}
    local spec   = Core.ActiveSpec
    if not spec or not spec.uptimeBuffs then return result end
    for _, buff in ipairs(spec.uptimeBuffs) do
        local pct = CL.GetUptimePercent(buff.id, duration) or 0
        result[buff.id] = {
            label        = buff.label,
            actualPct    = pct,
            targetUptime = buff.targetUptime or 0,
            appCount     = uptimes[buff.id] and uptimes[buff.id].appCount or 0,
        }
    end
    return result
end

function CL.GetProcData(spellID)
    local p = procs[spellID]
    if not p then return nil end
    local total = p.totalTime
    if p.active and p.startTime then total = total + (GetTime() - p.startTime) end
    return { gained = p.gainCount, totalActiveTime = total }
end

function CL.GetAllProcs()
    local result = {}
    local spec   = Core.ActiveSpec
    if not spec or not spec.procBuffs then return result end
    for _, proc in ipairs(spec.procBuffs) do
        local data = CL.GetProcData(proc.id)
        result[proc.id] = {
            label           = proc.label,
            gained          = data and data.gained          or 0,
            totalActiveTime = data and data.totalActiveTime or 0,
            maxStackTime    = proc.maxStackTime,
        }
    end
    return result
end

-- Overheal not trackable without CLEU — returns zeroes so Analytics degrades gracefully
function CL.GetHealingData()
    return { done = 0, overheal = 0, events = 0 }
end

function CL.HasData()
    return next(uptimes) ~= nil or next(procs) ~= nil
end
