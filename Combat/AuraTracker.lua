--------------------------------------------------------------------------------
-- Midnight Sensei: Combat/AuraTracker.lua
-- Tracks player self-buff uptime using UNIT_AURA (via ProcessUnitAura).
--
-- Implements the aura uptime half of ProcessUnitAura.  For each spec.uptimeBuffs
-- entry, scans whether the buff is currently active on the player after every
-- UNIT_AURA event and accumulates total active time in open/close windows.
--
-- UNIT_AURA replaces the restricted CLEU API for buff/debuff tracking in
-- Midnight 12.0 — see Core.CHANGELOG.
--
-- Exposes on MS.CombatLog:
--   GetAllUptimes(duration) →
--     [spellID] = { actualPct, targetUptime, appCount }
--
-- Internal:
--   CL._auraUptimeHandler(unit)  — assigned here; dispatched by CombatLog.lua
--------------------------------------------------------------------------------

MidnightSensei        = MidnightSensei        or {}
MidnightSensei.Combat = MidnightSensei.Combat or {}

local MS   = MidnightSensei
local Core = MS.Core
local CL   = MS.CombatLog

-- ── Private state ────────────────────────────────────────────────────────────
-- [spellID] = { isActive, lastApplied, totalActive, appCount, targetUptime }
local auraData    = {}
local fightActive = false

-- ── GetAllUptimes ─────────────────────────────────────────────────────────────
-- Called by Engine.lua's BuildState at fight end, after COMBAT_END has already
-- closed any open windows.  Safe to call mid-fight too — closes windows
-- temporarily against the current timestamp without mutating state.
function CL.GetAllUptimes(duration)
    local result = {}
    local now    = GetTime()
    for spellID, data in pairs(auraData) do
        local total = data.totalActive
        -- If still active (e.g. called mid-fight), include the current open window
        if data.isActive and data.lastApplied > 0 then
            total = total + (now - data.lastApplied)
        end
        result[spellID] = {
            actualPct    = (total / math.max(1, duration)) * 100,
            targetUptime = data.targetUptime,
            appCount     = data.appCount,
        }
    end
    return result
end

-- ── UNIT_AURA handler ─────────────────────────────────────────────────────────
-- Registered as CL._auraUptimeHandler — dispatched by CombatLog.ProcessUnitAura.
-- Scans spec.uptimeBuffs on every player aura change, opening/closing windows.
CL._auraUptimeHandler = function(unit)
    if not fightActive or unit ~= "player" then return end
    local spec = Core.ActiveSpec
    if not spec or not spec.uptimeBuffs then return end

    local now = GetTime()
    for _, buff in ipairs(spec.uptimeBuffs) do
        local data = auraData[buff.id]
        if data then
            local aura = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
                         and C_UnitAuras.GetPlayerAuraBySpellID(buff.id)
            local isActive = (aura ~= nil)

            if isActive and not data.isActive then
                -- Window opened: buff applied
                data.isActive    = true
                data.lastApplied = now
                data.appCount    = data.appCount + 1
            elseif not isActive and data.isActive then
                -- Window closed: buff removed
                data.isActive   = false
                data.totalActive = data.totalActive + (now - data.lastApplied)
            end
        end
    end
end

-- ── Combat start — reset and pre-populate ────────────────────────────────────
Core.On(Core.EVENTS.COMBAT_START, function()
    fightActive = true
    auraData    = {}

    local spec = Core.ActiveSpec
    if not spec or not spec.uptimeBuffs then return end
    for _, buff in ipairs(spec.uptimeBuffs) do
        auraData[buff.id] = {
            isActive     = false,
            lastApplied  = 0,
            totalActive  = 0,
            appCount     = 0,
            targetUptime = buff.targetUptime or 80,
        }
    end

    -- Detect buffs already active at combat start (e.g. Shield Block cast pre-pull,
    -- Arcane Intellect applied by a groupmate).
    -- Non-infoOnly buffs are the player's own spells — credit as 1 application so
    -- Scoring.lua's appCount>0 gate includes them and refreshes through the fight
    -- (which never fire a new APPLY event) don't orphan the uptime.
    -- infoOnly group buffs (Arcane Intellect) stay at appCount=0 — the player
    -- may not have cast it themselves, so Scoring excludes them from the score.
    local now = GetTime()
    for _, buff in ipairs(spec.uptimeBuffs) do
        local aura = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
                     and C_UnitAuras.GetPlayerAuraBySpellID(buff.id)
        if aura and auraData[buff.id] then
            auraData[buff.id].isActive    = true
            auraData[buff.id].lastApplied = now
            if not buff.infoOnly then
                auraData[buff.id].appCount = 1
            end
        end
    end
end)

-- ── Combat end — close any open windows ──────────────────────────────────────
-- Runs before Engine.lua's COMBAT_END handler (earlier TOC position = earlier
-- registration).  All windows are closed so GetAllUptimes returns stable values.
Core.On(Core.EVENTS.COMBAT_END, function()
    fightActive = false
    local now   = GetTime()
    for _, data in pairs(auraData) do
        if data.isActive and data.lastApplied > 0 then
            data.totalActive = data.totalActive + (now - data.lastApplied)
            data.isActive    = false
        end
    end
end)
