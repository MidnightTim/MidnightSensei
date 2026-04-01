--------------------------------------------------------------------------------
-- Midnight Sensei: Analytics.lua
-- All scoring logic.  Raw data comes from CombatLog.lua (CL module).
-- This module owns: per-fight tracking, score calculation, feedback generation,
-- grade assignment, and encounter saving to SavedVariables.
--
-- Overcap fix: edge-triggered state machine (fires once on entry, not every tick)
-- CLEU integration: ScoreDebuffUptime uses CL.GetAllUptimes()
--                   ScoreProcUsage   uses CL.GetAllProcs()
--                   ScoreHealerEfficiency uses CL.GetHealingData()
--------------------------------------------------------------------------------

MidnightSensei           = MidnightSensei           or {}
MidnightSensei.Analytics = MidnightSensei.Analytics or {}

local MS        = MidnightSensei
local Analytics = MS.Analytics
local Core      = MS.Core
local CL        = MS.CombatLog   -- populated by CombatLog.lua
local Utils     = MS.Utils

local function SafeCall(mod, fn, ...)
    local f = mod and mod[fn]
    if type(f) == "function" then return f(...) end
end
local fightActive    = false
local fightStartTime = 0
local fightEndTime   = 0

-- Cooldown tracking: [spellID] = { lastUsed, useCount, expectedUses }
local cdTracking     = {}

-- Overcap tracking  (edge-triggered — only fires once per overcap entry)
local overcapState   = false   -- true while currently overcapped
local overcapEvents  = 0       -- count of distinct overcap entries

-- Activity tracking (non-idle GCDs)
local totalGCDs       = 0
local activeGCDs      = 0

-- Real-time feedback queue (displayed in UI ticker)
local feedbackQueue   = {}

-- Expose last completed result, falling back to the most recent DB entry on login
function Analytics.GetLastEncounter()
    if Analytics.LastResult then return Analytics.LastResult end
    local db = MidnightSenseiDB
    if db and db.encounters and #db.encounters > 0 then
        return db.encounters[#db.encounters]
    end
    return nil
end

-- Boss encounter snapshot captured at fight start
local currentBossContext    = nil
-- Instance context snapshot (difficulty, M+ key, delve tier)
local currentInstanceContext = nil

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function Now()     return GetTime()     end
local function FightDur() return math.max(1, (fightEndTime > 0 and fightEndTime or Now()) - fightStartTime) end

local function QueueFeedback(msg, priority)
    table.insert(feedbackQueue, { msg = msg, priority = priority or 1, time = Now() })
end

local function FlushFeedback()
    feedbackQueue = {}
end

local function Clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function Lerp(a, b, t)    return a + (b - a) * Clamp(t, 0, 1)  end

--------------------------------------------------------------------------------
-- Combat start / end hooks
--------------------------------------------------------------------------------
local function OnCombatStart()
    fightActive    = true
    fightStartTime = Now()
    fightEndTime   = 0

    cdTracking    = {}
    overcapState  = false
    overcapEvents = 0
    totalGCDs     = 0
    activeGCDs    = 0
    FlushFeedback()

    -- Snapshot boss encounter context
    currentBossContext = Core.CurrentEncounter and Core.CurrentEncounter.isBoss
        and { name = Core.CurrentEncounter.name, id = Core.CurrentEncounter.id,
              difficultyID = Core.CurrentEncounter.difficultyID }
        or nil

    -- Snapshot instance context for difficulty labelling
    -- LB module provides the full context (M+ key level, delve tier, etc.)
    currentInstanceContext = nil
    if MS.Leaderboard and MS.Leaderboard.GetInstanceContext then
        currentInstanceContext = MS.Leaderboard.GetInstanceContext()
    else
        -- Fallback: derive from Core snapshot
        local ic = Core.CombatInstanceContext
        if ic then
            local iType = ic.instanceType or "none"
            local encType = "normal"
            if iType == "raid"     then encType = "raid"
            elseif iType == "party" then encType = "dungeon"
            elseif iType == "scenario" then encType = "delve" end
            currentInstanceContext = {
                encType   = encType,
                diffLabel = ic.difficultyName or "",
                keystoneLevel = nil,
            }
        end
    end

    -- Pre-populate CD tracking — only spells the player currently has
    local spec = Core.ActiveSpec
    if spec and spec.majorCooldowns then
        for _, cd in ipairs(spec.majorCooldowns) do
            local known = IsPlayerSpell and IsPlayerSpell(cd.id)
            if known then
                cdTracking[cd.id] = {
                    lastUsed     = 0,
                    useCount     = 0,
                    expectedUses = cd.expectedUses,
                    label        = cd.label,
                }
            end
        end
    end

    SafeCall(MS.UI, "OnCombatStart")
end

local function OnCombatEnd(duration)
    fightActive  = false
    fightEndTime = Now()

    -- Minimum fight threshold
    local minFight = Core.GetSetting("minimumFight") or 15
    if (fightEndTime - fightStartTime) < minFight then
        SafeCall(MS.UI, "OnCombatEnd", nil)
        return
    end

    local result = Analytics.CalculateGrade()
    Analytics.LastResult = result

    if result then
        -- Save to history
        local db = MidnightSenseiDB
        if db and db.encounters then
            table.insert(db.encounters, result)
            -- Keep last 100 encounters
            while #db.encounters > 100 do
                table.remove(db.encounters, 1)
            end
        end

        Core.Emit(Core.EVENTS.GRADE_CALCULATED, result)
    end

    SafeCall(MS.UI, "OnCombatEnd", result)
end

Core.On(Core.EVENTS.COMBAT_START, OnCombatStart)
Core.On(Core.EVENTS.COMBAT_END,   OnCombatEnd)

--------------------------------------------------------------------------------
-- Ability Used hook — CD tracking + activity
--------------------------------------------------------------------------------
Core.On(Core.EVENTS.ABILITY_USED, function(spellID, timestamp)
    if not fightActive then return end

    totalGCDs   = totalGCDs + 1
    activeGCDs  = activeGCDs + 1   -- every logged cast counts as active

    local cd = cdTracking[spellID]
    if cd then
        cd.lastUsed = timestamp
        cd.useCount = cd.useCount + 1
    end
end)

--------------------------------------------------------------------------------
-- Resource tick — EDGE-TRIGGERED overcap detection
-- Registered once on SESSION_READY; only increments overcapEvents when the
-- player transitions from not-overcapped → overcapped (not every tick).
--------------------------------------------------------------------------------
Core.On(Core.EVENTS.SESSION_READY, function()
    Core.RegisterTick("overcapCheck", 0.5, function()
        if not fightActive then return end
        local spec = Core.ActiveSpec
        if not spec or not spec.overcapAt then return end
        if not spec.resourceType then return end

        local cur = UnitPower("player", spec.resourceType)
        local cap = spec.overcapAt

        local isNowOvercapped = (cur >= cap)

        -- Edge trigger: only count when we ENTER overcap state
        if isNowOvercapped and not overcapState then
            overcapEvents = overcapEvents + 1
            overcapState  = true
            QueueFeedback("Watch your " .. (spec.resourceLabel or "resource") ..
                          " — you're overcapping! (" .. cur .. "/" .. cap .. ")", 2)
        elseif not isNowOvercapped and overcapState then
            overcapState = false   -- reset for next entry
        end
    end)
end)

--------------------------------------------------------------------------------
-- SCORING FUNCTIONS
-- Each returns 0–100.  Weights are in spec.scoreWeights.
--------------------------------------------------------------------------------

-- 1. Cooldown Usage Score
--    Only tracks CDs confirmed known via IsPlayerSpell at fight start.
--    Short fights (< 60s) are given a gentle penalty cap so a single missed
--    CD on a 20s trash pull doesn't tank the score.
local function ScoreCooldownUsage(duration)
    local spec = Core.ActiveSpec
    if not spec or not spec.majorCooldowns or #spec.majorCooldowns == 0 then return 75 end
    if not next(cdTracking) then return 75 end  -- no known CDs tracked

    local totalWeight  = 0
    local earnedWeight = 0

    for _, cd in ipairs(spec.majorCooldowns) do
        local data = cdTracking[cd.id]
        if data then  -- only score CDs that were tracked (i.e. player has them)
            local w = 1.0
            totalWeight = totalWeight + w

            if data.useCount > 0 then
                -- Base 70% credit for at least one use
                earnedWeight = earnedWeight + w * 0.70

                -- Bonus: expect 1 use per 120s, prorated for fight length
                local expectedUses = math.max(1, math.floor(duration / 120))
                local useRatio = math.min(data.useCount / expectedUses, 1)
                earnedWeight = earnedWeight + w * 0.30 * useRatio
            end
        end
    end

    if totalWeight == 0 then return 75 end
    local raw = (earnedWeight / totalWeight) * 100

    -- For very short fights (< 60s), apply a softer floor so one missed CD
    -- doesn't dominate. A 20s trash pull genuinely may not warrant a CD.
    if duration < 60 then
        raw = math.max(raw, 50)
    end

    return raw
end

-- 2. Buff Uptime Score
-- Only scores self-buffs on the player. Enemy debuff tracking is blocked by
-- Midnight 12.0 secret values. Specs with only debuffs get a neutral 75.
local function ScoreDebuffUptime(duration)
    local spec = Core.ActiveSpec
    if not CL or not CL.GetAllUptimes then return 75 end
    if not spec or not spec.uptimeBuffs or #spec.uptimeBuffs == 0 then return 75 end

    local uptimeData = CL.GetAllUptimes(duration)

    local totalScore = 0
    local count      = 0

    for _, buff in ipairs(spec.uptimeBuffs) do
        local data = uptimeData[buff.id]
        -- Only score buffs that actually had any data recorded (i.e. self-buffs)
        if data and data.targetUptime and data.targetUptime > 0
        and data.appCount and data.appCount > 0 then
            local ratio = Clamp(data.actualPct / data.targetUptime, 0, 1)
            totalScore = totalScore + (math.sqrt(ratio) * 100)
            count = count + 1
        end
    end

    -- No self-buff data recorded → neutral score (enemy debuffs not trackable)
    if count == 0 then return 75 end
    return totalScore / count
end

-- 3. Proc Usage Score  (uses CL module)
--    Penalises holding procs longer than their maxStackTime.
local function ScoreProcUsage()
    local spec = Core.ActiveSpec
    if not CL or not CL.GetAllProcs then return 75 end
    if not spec or not spec.procBuffs or #spec.procBuffs == 0 then return 75 end

    local procData    = CL.GetAllProcs()
    if not next(procData) then return 75 end

    local totalScore = 0
    local count      = 0

    for _, proc in ipairs(spec.procBuffs) do
        local data = procData[proc.id]
        if data and data.gained and data.gained > 0 then
            local maxTime   = proc.maxStackTime or 10
            local avgHeld   = data.totalActiveTime / data.gained
            -- Score = how quickly we consumed it vs. the max window
            -- Perfect = avgHeld <= 25% of window; Poor = avgHeld >= 100%
            local holdRatio = Clamp(avgHeld / maxTime, 0, 1)
            local procScore = (1 - holdRatio) * 100
            totalScore = totalScore + procScore
            count = count + 1
        end
    end

    if count == 0 then return 75 end
    return totalScore / count
end

-- 4. Activity Score  (cast density)
local function ScoreActivity(duration)
    if totalGCDs == 0 then return 50 end
    -- Target: ~40 GCDs per minute for most melee/caster DPS; healers lower
    local spec        = Core.ActiveSpec
    local targetGPM   = 40
    if spec then
        if spec.role == Core.ROLE.HEALER then targetGPM = 25
        elseif spec.role == Core.ROLE.TANK then targetGPM = 30 end
    end
    local targetTotal = (duration / 60) * targetGPM
    return Clamp((activeGCDs / math.max(1, targetTotal)) * 100, 0, 100)
end

-- 5. Resource Management Score  (overcap penalty + waste)
local function ScoreResourceMgmt(duration)
    -- Each overcap event is a waste.  Tolerate 0, penalise scaling with fight length.
    local toleratedEvents = math.max(1, math.floor(duration / 60) * 1)
    if overcapEvents == 0 then return 100 end
    local penalty = Clamp(overcapEvents / toleratedEvents, 0, 1)
    return (1 - penalty * 0.5) * 100  -- max 50% penalty from overcapping alone
end

-- 6. Healer Efficiency Score  (uses CL module)
local function ScoreHealerEfficiency()
    local spec = Core.ActiveSpec
    if not spec or spec.role ~= Core.ROLE.HEALER then return nil end
    if not CL or not CL.GetHealingData then return 75 end

    local hd = CL.GetHealingData()
    if hd.done == 0 then return 75 end

    local overhealPct  = (hd.overheal / (hd.done + hd.overheal)) * 100
    local targetOH     = (spec.healerMetrics and spec.healerMetrics.targetOverheal) or 30

    -- Score degrades smoothly above target overheal
    if overhealPct <= targetOH then
        return 100
    else
        local excess = overhealPct - targetOH
        -- Lose 2 points per 1% overheal above target, capped at 60-pt loss
        return Clamp(100 - excess * 2, 40, 100)
    end
end

-- 7. Mitigation Score  (tanks: uptime of active mitigation)
local function ScoreMitigation(duration)
    local spec = Core.ActiveSpec
    if not spec or spec.role ~= Core.ROLE.TANK then return nil end
    if not spec.uptimeBuffs or #spec.uptimeBuffs == 0 then return 75 end
    -- Re-use debuff uptime logic on the main mitigation buff
    return ScoreDebuffUptime(duration)
end

--------------------------------------------------------------------------------
-- Weighted aggregate score
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
-- Main Grade Calculator
--------------------------------------------------------------------------------
function Analytics.CalculateGrade()
    local spec = Core.ActiveSpec
    if not spec then return nil end

    local duration = FightDur()
    local weights  = spec.scoreWeights or { cooldownUsage = 30, activity = 40, resourceMgmt = 30 }

    -- Calculate all component scores
    local scores = {
        cooldownUsage = ScoreCooldownUsage(duration),
        activity      = ScoreActivity(duration),
        resourceMgmt  = ScoreResourceMgmt(duration),
    }

    if weights.debuffUptime then
        scores.debuffUptime = ScoreDebuffUptime(duration)
    end
    if weights.procUsage then
        scores.procUsage = ScoreProcUsage()
    end
    if spec.role == Core.ROLE.HEALER then
        scores.efficiency = ScoreHealerEfficiency()
        scores.responsiveness = 75  -- placeholder until responsive-healing event tracking
    end
    if spec.role == Core.ROLE.TANK then
        scores.mitigationUptime = ScoreMitigation(duration)
    end

    local finalScore = math.floor(BuildWeightedScore(scores, weights))
    local grade, gradeColor, gradeLabel = Core.GetGrade(finalScore)

    local feedback = Analytics.GenerateFeedback(scores, duration)

    local result = {
        -- Identity
        className    = spec.className,
        specName     = spec.name,
        role         = spec.role,
        charName     = UnitName("player") or "?",
        realmName    = GetRealmName() or "?",
        -- Encounter type
        isBoss       = (currentBossContext ~= nil),
        bossName     = currentBossContext and currentBossContext.name or nil,
        bossID       = currentBossContext and currentBossContext.id   or nil,
        -- Instance context
        encType       = currentInstanceContext and currentInstanceContext.encType   or "normal",
        diffLabel     = currentInstanceContext and currentInstanceContext.diffLabel or "",
        keystoneLevel = currentInstanceContext and currentInstanceContext.keystoneLevel or nil,
        -- Time
        timestamp    = time(),
        startTime    = fightStartTime,
        endTime      = fightEndTime,
        duration     = duration,
        -- Scores
        componentScores = scores,
        finalScore   = finalScore,
        finalGrade   = grade,
        gradeColor   = gradeColor,
        gradeLabel   = gradeLabel,
        grade        = grade,   -- shorthand alias for leaderboard
        -- Feedback
        feedback     = feedback,
        -- Raw counters
        totalGCDs    = totalGCDs,
        activeGCDs   = activeGCDs,
        overcapEvents = overcapEvents,
    }

    return result
end

--------------------------------------------------------------------------------
-- Feedback Generator
-- Returns a list of coaching strings prioritised by impact.
--------------------------------------------------------------------------------
function Analytics.GenerateFeedback(scores, duration)
    local feedback = {}
    local spec     = Core.ActiveSpec
    if not spec then return feedback end

    local function Add(msg) table.insert(feedback, msg) end

    -- Cooldown usage
    local cdScore = scores.cooldownUsage or 100
    if cdScore < 70 then
        local missedCDs = {}
        for spellID, data in pairs(cdTracking) do
            -- Only include spells that were actually tracked (player has them)
            if data.useCount == 0 then
                table.insert(missedCDs, data.label or ("Spell " .. spellID))
            end
        end
        if #missedCDs > 0 then
            -- Sort for consistent output
            table.sort(missedCDs)
            Add("Unused cooldowns: " .. table.concat(missedCDs, ", ") ..
                " — use these on cooldown for maximum impact.")
        else
            Add("Cooldown timing needs work — use your major abilities as soon as they're ready.")
        end
    elseif cdScore >= 90 then
        Add("Excellent cooldown usage — making the most of every big button.")
    end

    -- Boss context note
    if currentBossContext and currentBossContext.name then
        Add("Boss encounter: " .. currentBossContext.name ..
            " — cooldowns should be saved for specific damage windows if known.")
    end

    -- Debuff uptime
    local uptimeScore = scores.debuffUptime
    if uptimeScore then
        if not CL or not CL.GetAllUptimes then
            -- No CLEU data
        else
            local uptimeData = CL.GetAllUptimes(duration)
            for _, buff in ipairs(spec.uptimeBuffs or {}) do
                local data = uptimeData[buff.id]
                if data and data.targetUptime and data.targetUptime > 0 then
                    if data.actualPct < data.targetUptime * 0.8 then
                        Add(buff.label .. " uptime: " .. math.floor(data.actualPct) ..
                            "% (target: " .. data.targetUptime .. "%) — keep it rolling!")
                    elseif data.actualPct >= data.targetUptime * 0.95 then
                        Add(buff.label .. " uptime: " .. math.floor(data.actualPct) ..
                            "% — great DoT/buff maintenance.")
                    end
                end
            end
        end
    end

    -- Proc usage
    local procScore = scores.procUsage
    if procScore and procScore < 70 then
        if CL and CL.GetAllProcs then
            local procData = CL.GetAllProcs()
            for _, proc in ipairs(spec.procBuffs or {}) do
                local data = procData[proc.id]
                if data and data.gained and data.gained > 0 then
                    local avgHeld = data.totalActiveTime / data.gained
                    if avgHeld > (proc.maxStackTime or 10) * 0.5 then
                        Add(proc.label .. " procs held for " ..
                            string.format("%.1f", avgHeld) .. "s on average — spend them faster.")
                    end
                end
            end
        end
    elseif procScore and procScore >= 90 then
        Add("Great proc usage — you're spending procs quickly.")
    end

    -- Activity
    local actScore = scores.activity or 100
    if actScore < 65 then
        Add("Low activity detected — avoid long gaps between casts.")
    elseif actScore >= 90 then
        Add("High activity — you're keeping busy out there.")
    end

    -- Resource management
    local rmScore = scores.resourceMgmt or 100
    if rmScore < 70 then
        local resourceLabel = spec.resourceLabel or "resource"
        Add("Overcapped " .. resourceLabel .. " " .. overcapEvents ..
            " time(s) — spend before you hit max to avoid wasted generation.")
    elseif rmScore == 100 then
        Add("Perfect resource management — not a drop wasted.")
    end

    -- Healer efficiency
    if spec.role == Core.ROLE.HEALER and CL and CL.GetHealingData then
        local hd = CL.GetHealingData()
        if hd.done > 0 then
            local overpct = (hd.overheal / (hd.done + hd.overheal)) * 100
            local target  = (spec.healerMetrics and spec.healerMetrics.targetOverheal) or 30
            if overpct > target + 15 then
                Add(string.format("Overheal: %.1f%% (target < %d%%) — heal slightly earlier or use more reactive heals.",
                    overpct, target))
            elseif overpct <= target then
                Add(string.format("Overheal: %.1f%% — excellent healing efficiency.", overpct))
            end
        end
    end

    -- Generic encouragement if nothing major to flag
    if #feedback == 0 then
        Add("Clean performance — keep building on this foundation!")
    end

    -- Cap at 5 messages to avoid overwhelming the player
    while #feedback > 5 do table.remove(feedback) end

    return feedback
end

--------------------------------------------------------------------------------
-- Real-time feedback API (used by UI ticker)
--------------------------------------------------------------------------------
function Analytics.PopFeedback()
    if #feedbackQueue == 0 then return nil end
    return table.remove(feedbackQueue, 1)
end

function Analytics.GetComponentScores()
    if not Analytics.LastResult then return {} end
    return Analytics.LastResult.componentScores or {}
end

function Analytics.IsInFight()
    return fightActive
end

function Analytics.GetFightTime()
    if not fightActive then return 0 end
    return Now() - fightStartTime
end
