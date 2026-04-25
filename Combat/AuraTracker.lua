--------------------------------------------------------------------------------
-- Midnight Sensei: Combat/AuraTracker.lua
-- Tracks player self-buff uptime using cast events (ABILITY_USED) rather than
-- aura scanning.  In Midnight 12.0, aura.spellId is a "secret number value"
-- that cannot be used in equality comparisons when addon code is tainted —
-- all aura-scanning approaches were blocked by that restriction.
--
-- Cast-based approach: every uptimeBuff entry that declares castSpellId (or
-- castSpellIds) opens a time window when the player casts that spell, extends
-- it by buffDuration seconds on each refresh cast (max-extend, no close/reopen),
-- and a 0.25s expiry-checker ticker closes the window when time runs out.
--
-- uptimeBuff fields used here:
--   id           — unique identifier for this buff's tracking slot
--   castSpellId  — single cast spell ID that applies/refreshes this buff
--   castSpellIds — list of cast spell IDs that apply/refresh this buff
--   buffDuration — how long each cast keeps the buff active (seconds)
--
-- Exposes on MS.CombatLog:
--   GetAllUptimes(duration) →
--     [buffId] = { actualPct, targetUptime, appCount }
--
-- Internal:
--   CL._auraUptimeHandler(unit)  — no-op; kept so CombatLog.lua dispatch is safe
--------------------------------------------------------------------------------

MidnightSensei        = MidnightSensei        or {}
MidnightSensei.Combat = MidnightSensei.Combat or {}

local MS   = MidnightSensei
local Core = MS.Core
local CL   = MS.CombatLog

-- ── Private state ────────────────────────────────────────────────────────────
-- [buffId] = { isActive, lastApplied, currentExpiry, totalActive, appCount, targetUptime }
local auraData     = {}
local castMap      = {}  -- [castSpellId] = buffId
local durMap       = {}  -- [castSpellId] = buffDuration
local fightActive  = false
local expiryTicker = nil

-- ── GetAllUptimes ─────────────────────────────────────────────────────────────
-- Called by Engine.lua's BuildState at fight end, after COMBAT_END has already
-- closed any open windows.  Safe to call mid-fight too — caps against currentExpiry
-- so expired-but-not-yet-ticked windows don't overcount.
function CL.GetAllUptimes(duration)
    local result = {}
    local now    = GetTime()
    for buffId, data in pairs(auraData) do
        local total = data.totalActive
        if data.isActive and data.lastApplied > 0 then
            local effectiveNow = (data.currentExpiry > 0 and data.currentExpiry < now)
                                 and data.currentExpiry or now
            total = total + (effectiveNow - data.lastApplied)
        end
        result[buffId] = {
            actualPct    = (total / math.max(1, duration)) * 100,
            targetUptime = data.targetUptime,
            appCount     = data.appCount,
        }
    end
    return result
end

-- ── ABILITY_USED listener ─────────────────────────────────────────────────────
-- Registered at module load (not COMBAT_START) so registration survives wipes.
-- When a cast spell matches castMap, opens or extends the corresponding buff window.
Core.On(Core.EVENTS.ABILITY_USED, function(spellID, timestamp)
    if not fightActive then return end
    local buffId = castMap[spellID]
    if not buffId then return end
    local data = auraData[buffId]
    if not data then return end

    local now = timestamp or GetTime()
    local dur = durMap[spellID] or 6

    if not data.isActive then
        data.isActive    = true
        data.lastApplied = now
        data.appCount    = data.appCount + 1
    end
    -- Extend expiry on refresh — no close/reopen during continuous uptime
    data.currentExpiry = math.max(data.currentExpiry, now + dur)
end)

-- ── _auraUptimeHandler ────────────────────────────────────────────────────────
-- No-op: CombatLog.lua's ProcessUnitAura calls this slot; keep it assigned so
-- the nil-guard in ProcessUnitAura does not need changing.
CL._auraUptimeHandler = function(_unit) end

-- ── Combat start — build maps, start expiry ticker ───────────────────────────
Core.On(Core.EVENTS.COMBAT_START, function()
    fightActive = true
    auraData    = {}
    castMap     = {}
    durMap      = {}

    local spec = Core.ActiveSpec
    if not spec or not spec.uptimeBuffs then return end

    for _, buff in ipairs(spec.uptimeBuffs) do
        auraData[buff.id] = {
            isActive      = false,
            lastApplied   = 0,
            currentExpiry = 0,
            totalActive   = 0,
            appCount      = 0,
            targetUptime  = buff.targetUptime or 80,
        }
        local castIds = buff.castSpellIds or (buff.castSpellId and {buff.castSpellId}) or {}
        for _, cid in ipairs(castIds) do
            castMap[cid] = buff.id
            durMap[cid]  = buff.buffDuration or 6
        end
    end

    -- 0.25s ticker closes windows that have reached their expiry time
    if expiryTicker then expiryTicker:Cancel() end
    expiryTicker = C_Timer.NewTicker(0.25, function()
        if not fightActive then return end
        local now = GetTime()
        for _, data in pairs(auraData) do
            if data.isActive and data.currentExpiry > 0 and now >= data.currentExpiry then
                data.totalActive = data.totalActive + (data.currentExpiry - data.lastApplied)
                data.isActive    = false
                data.lastApplied = 0
            end
        end
    end)
end)

-- ── Combat end — close any open windows ──────────────────────────────────────
-- Runs before Engine.lua's COMBAT_END handler (earlier TOC position = earlier
-- registration).  All windows are closed so GetAllUptimes returns stable values.
Core.On(Core.EVENTS.COMBAT_END, function()
    if expiryTicker then
        expiryTicker:Cancel()
        expiryTicker = nil
    end
    fightActive = false
    local now   = GetTime()
    for _, data in pairs(auraData) do
        if data.isActive and data.lastApplied > 0 then
            -- If buff expired before combat ended (ticker missed it), credit only to expiry
            local closeAt = (data.currentExpiry > 0 and data.currentExpiry < now)
                            and data.currentExpiry or now
            data.totalActive = data.totalActive + (closeAt - data.lastApplied)
            data.isActive    = false
        end
    end
end)
