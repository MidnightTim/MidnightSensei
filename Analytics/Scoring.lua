--------------------------------------------------------------------------------
-- Midnight Sensei: Analytics/Scoring.lua
-- Score calculation functions.  Each returns 0–100 (or nil to exclude).
-- Called by Engine.lua via Scoring.Calculate(state, duration).
--
-- State snapshot passed by Engine (built fresh each fight end):
--   state.spec               — Core.ActiveSpec
--   state.cdTracking         — [spellID] = { useCount, lastUsed, ... }
--   state.overcapEvents      — distinct overcap entries this fight
--   state.totalGCDs          — total GCDs cast
--   state.activeGCDs         — non-idle GCDs cast
--   state.CL                 — MS.CombatLog module reference
--------------------------------------------------------------------------------

MidnightSensei                   = MidnightSensei                   or {}
MidnightSensei.Analytics         = MidnightSensei.Analytics         or {}
MidnightSensei.Analytics.Scoring = MidnightSensei.Analytics.Scoring or {}

local MS      = MidnightSensei
local Core    = MS.Core
local Scoring = MS.Analytics.Scoring

local function Clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

--------------------------------------------------------------------------------
-- 1. Cooldown Usage Score
--    Only scores CDs confirmed known at fight start (IsPlayerSpell / IsTalentActive).
--    Short fights (< 60s) get a gentle penalty floor so a single missed CD on a
--    20s trash pull doesn't tank the score.
--------------------------------------------------------------------------------
local function ScoreCooldownUsage(state, duration)
    local spec       = state.spec
    local cdTracking = state.cdTracking
    if not spec or not spec.majorCooldowns or #spec.majorCooldowns == 0 then return 75 end
    if not next(cdTracking) then return 75 end

    local totalWeight  = 0
    local earnedWeight = 0

    for _, cd in ipairs(spec.majorCooldowns) do
        local data = cdTracking[cd.id]
        if data then
            local w = 1.0
            totalWeight = totalWeight + w

            if data.useCount > 0 then
                -- Base 70% credit for at least one use
                earnedWeight = earnedWeight + w * 0.70
                -- Bonus: expect 1 use per 120s, prorated for fight length
                local expectedUses = math.max(1, math.floor(duration / 120))
                local useRatio     = math.min(data.useCount / expectedUses, 1)
                earnedWeight = earnedWeight + w * 0.30 * useRatio
            end
        end
    end

    if totalWeight == 0 then return 75 end
    local raw = (earnedWeight / totalWeight) * 100
    if duration < 60 then raw = math.max(raw, 50) end
    return raw
end

--------------------------------------------------------------------------------
-- 2. Buff / Debuff Uptime Score
--    Only scores self-buffs on the player.  Enemy debuff tracking is blocked by
--    Midnight 12.0 secret values.  Specs with only debuffs get a neutral 75.
--------------------------------------------------------------------------------
local function ScoreDebuffUptime(state, duration)
    local spec = state.spec
    local CL   = state.CL
    if not CL or not CL.GetAllUptimes then return 75 end
    if not spec or not spec.uptimeBuffs or #spec.uptimeBuffs == 0 then return 75 end

    local uptimeData = CL.GetAllUptimes(duration)
    local totalScore = 0
    local count      = 0

    for _, buff in ipairs(spec.uptimeBuffs) do
        local data = uptimeData[buff.id]
        if data and data.targetUptime and data.targetUptime > 0
        and data.appCount and data.appCount > 0 then
            local ratio = Clamp(data.actualPct / data.targetUptime, 0, 1)
            totalScore  = totalScore + (math.sqrt(ratio) * 100)
            count       = count + 1
        end
    end

    if count == 0 then return 75 end
    return totalScore / count
end

--------------------------------------------------------------------------------
-- 3. Proc Usage Score
--    Penalises holding procs longer than their maxStackTime.
--------------------------------------------------------------------------------
local function ScoreProcUsage(state)
    local spec = state.spec
    local CL   = state.CL
    if not CL or not CL.GetAllProcs then return 75 end
    if not spec or not spec.procBuffs or #spec.procBuffs == 0 then return 75 end

    local procData = CL.GetAllProcs()
    if not next(procData) then return 75 end

    local totalScore = 0
    local count      = 0

    for _, proc in ipairs(spec.procBuffs) do
        local data = procData[proc.id]
        if data and data.gained and data.gained > 0 then
            local maxTime   = proc.maxStackTime or 10
            local avgHeld   = data.totalActiveTime / data.gained
            -- Perfect = avgHeld <= 25% of window; Poor = avgHeld >= 100%
            local holdRatio = Clamp(avgHeld / maxTime, 0, 1)
            totalScore = totalScore + (1 - holdRatio) * 100
            count      = count + 1
        end
    end

    if count == 0 then return 75 end
    return totalScore / count
end

--------------------------------------------------------------------------------
-- 4. Activity Score  (cast density)
--    Target: ~40 GCDs/min for DPS, 30 for tanks, 25 for healers.
--------------------------------------------------------------------------------
local function ScoreActivity(state, duration)
    local spec       = state.spec
    local totalGCDs  = state.totalGCDs
    local activeGCDs = state.activeGCDs
    if totalGCDs == 0 then return 50 end

    local targetGPM = 40
    if spec then
        if spec.role == Core.ROLE.HEALER then targetGPM = 25
        elseif spec.role == Core.ROLE.TANK then targetGPM = 30 end
    end
    local targetTotal = (duration / 60) * targetGPM
    return Clamp((activeGCDs / math.max(1, targetTotal)) * 100, 0, 100)
end

--------------------------------------------------------------------------------
-- 5. Resource Management Score  (overcap penalty)
--    Edge-triggered: each distinct entry into overcap is one event.
--    Tolerance: 1 event per fight-minute.  Max 50% penalty.
--------------------------------------------------------------------------------
local function ScoreResourceMgmt(state, duration)
    local overcapEvents   = state.overcapEvents
    local toleratedEvents = math.max(1, math.floor(duration / 60) * 1)
    if overcapEvents == 0 then return 100 end
    local penalty = Clamp(overcapEvents / toleratedEvents, 0, 1)
    return (1 - penalty * 0.5) * 100
end

--------------------------------------------------------------------------------
-- 6. Healer Efficiency Score
--    Uses CL.GetHealingData().  Returns nil if healer data unavailable so
--    BuildWeightedScore excludes it rather than dragging with a neutral 75.
--------------------------------------------------------------------------------
local function ScoreHealerEfficiency(state)
    local spec = state.spec
    local CL   = state.CL
    if not spec or spec.role ~= Core.ROLE.HEALER then return nil end
    if not CL or not CL.GetHealingData then return nil end

    local hd = CL.GetHealingData()
    if hd.done == 0 then return nil end  -- CLEU tracking unavailable this build

    local overhealPct = (hd.overheal / (hd.done + hd.overheal)) * 100
    local targetOH    = (spec.healerMetrics and spec.healerMetrics.targetOverheal) or 30

    if overhealPct <= targetOH then return 100 end
    local excess = overhealPct - targetOH
    return Clamp(100 - excess * 2, 40, 100)
end

--------------------------------------------------------------------------------
-- 7. Mitigation Score  (tanks: uptime of active mitigation buff)
--    Delegates to ScoreDebuffUptime — same logic, same data.
--------------------------------------------------------------------------------
local function ScoreMitigation(state, duration)
    local spec = state.spec
    if not spec or spec.role ~= Core.ROLE.TANK then return nil end
    if not spec.uptimeBuffs or #spec.uptimeBuffs == 0 then return 75 end
    return ScoreDebuffUptime(state, duration)
end

--------------------------------------------------------------------------------
-- Weighted aggregate
--------------------------------------------------------------------------------
local function BuildWeightedScore(scores, weights)
    local total  = 0
    local earned = 0
    for key, weight in pairs(weights) do
        local s = scores[key]
        if s then
            total  = total  + weight
            earned = earned + weight * Clamp(s, 0, 100)
        end
    end
    if total == 0 then return 0 end
    return earned / total
end

--------------------------------------------------------------------------------
-- Public entry point: Scoring.Calculate(state, duration)
-- Returns: scores (table), finalScore (number), weights (table)
-- Engine.lua calls this from CalculateGrade().
--------------------------------------------------------------------------------
function Scoring.Calculate(state, duration)
    local spec    = state.spec
    local weights = spec.scoreWeights or { cooldownUsage = 30, activity = 40, resourceMgmt = 30 }

    local scores = {
        cooldownUsage = ScoreCooldownUsage(state, duration),
        activity      = ScoreActivity(state, duration),
        resourceMgmt  = ScoreResourceMgmt(state, duration),
    }

    if weights.debuffUptime then
        scores.debuffUptime = ScoreDebuffUptime(state, duration)
    end
    if weights.procUsage then
        scores.procUsage = ScoreProcUsage(state)
    end
    if spec.role == Core.ROLE.HEALER then
        scores.efficiency = ScoreHealerEfficiency(state)
        -- responsiveness = 75 was a hardcoded placeholder that dragged healer
        -- scores down by ~5 points, making A+ unreachable in practice.
        -- Excluded until it can be measured from real events.
    end
    if spec.role == Core.ROLE.TANK then
        scores.mitigationUptime = ScoreMitigation(state, duration)
    end

    local finalScore = math.floor(BuildWeightedScore(scores, weights))
    return scores, finalScore, weights
end
