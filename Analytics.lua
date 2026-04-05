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
local cdTracking         = {}

-- Rotational spell tracking: [spellID] = { useCount, label, minFightSeconds }
-- For rotationally important spells that are NOT true cooldowns (no CD, no fixed window).
-- Only generates feedback if the fight was long enough and the spell was clearly unused.
local rotationalTracking = {}

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

    cdTracking          = {}
    rotationalTracking  = {}
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

    -- Pre-populate CD tracking — spec cooldowns the player currently has
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

    -- Add racial cooldowns — IsPlayerSpell filters to the player's actual race
    if Core.GetRacialCooldowns then
        for _, cd in ipairs(Core.GetRacialCooldowns()) do
            if IsPlayerSpell and IsPlayerSpell(cd.id) then
                cdTracking[cd.id] = {
                    lastUsed     = 0,
                    useCount     = 0,
                    expectedUses = cd.expectedUses,
                    label        = cd.label,
                }
            end
        end
    end

    -- Populate rotational spell tracking.
    -- No IsPlayerSpell gate by default — presence feedback is the safety net.
    -- Exception: entries marked talentGated=true are gated by IsPlayerSpell
    -- so players without those talents don't get false "never used" feedback.
    if spec and spec.rotationalSpells then
        for _, rs in ipairs(spec.rotationalSpells) do
            local include = true
            if rs.talentGated and IsPlayerSpell then
                include = IsPlayerSpell(rs.id)
            end
            if include then
                rotationalTracking[rs.id] = {
                    useCount        = 0,
                    label           = rs.label,
                    minFightSeconds = rs.minFightSeconds or 60,
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
        -- Save every encounter to history (for history panel / trending)
        local db = MidnightSenseiDB
        if db and db.encounters then
            table.insert(db.encounters, result)
            while #db.encounters > 100 do
                table.remove(db.encounters, 1)
            end
        end

        -- Only broadcast to leaderboard if this is a meaningful encounter:
        -- boss fights in any content, or any dungeon/raid/delve fight.
        -- Suppress open-world trash pulls and target dummy sessions.
        local isLeaderboardEligible = result.isBoss
            or result.encType == "dungeon"
            or result.encType == "raid"
            or result.encType == "delve"

        if isLeaderboardEligible then
            Core.Emit(Core.EVENTS.GRADE_CALCULATED, result)
        end
    end

    SafeCall(MS.UI, "OnCombatEnd", result)
end

Core.On(Core.EVENTS.COMBAT_START, OnCombatStart)
Core.On(Core.EVENTS.COMBAT_END,   OnCombatEnd)

-- BOSS_START fires after PLAYER_REGEN_DISABLED (COMBAT_START), so we update
-- currentBossContext here rather than trying to snapshot it in OnCombatStart.
Core.On(Core.EVENTS.BOSS_START, function(encID, encName, diffID)
    if fightActive then
        currentBossContext = { name = encName, id = encID, difficultyID = diffID }
    end
end)

-- Clear boss context on BOSS_END (wipe / end without kill)
Core.On(Core.EVENTS.BOSS_END, function(encID, encName, diffID, success)
    -- Keep context until fight ends so CalculateGrade can read it.
    -- OnCombatEnd fires after ENCOUNTER_END, so currentBossContext will still
    -- be set when we need it. Clear it in OnCombatStart for the next fight.
end)

--------------------------------------------------------------------------------
-- Ability Used hook — CD tracking + activity
--------------------------------------------------------------------------------
Core.On(Core.EVENTS.ABILITY_USED, function(spellID, timestamp)
    if not fightActive then return end

    totalGCDs   = totalGCDs + 1
    activeGCDs  = activeGCDs + 1

    local cd = cdTracking[spellID]
    if cd then
        cd.lastUsed = timestamp
        cd.useCount = cd.useCount + 1
    end

    local rs = rotationalTracking[spellID]
    if rs then
        rs.useCount = rs.useCount + 1
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
    if not CL or not CL.GetHealingData then return nil end  -- exclude if unavailable

    local hd = CL.GetHealingData()
    -- done == 0 means CLEU healing tracking is not available in this build.
    -- Return nil so BuildWeightedScore excludes it rather than dragging with 75.
    if hd.done == 0 then return nil end

    local overhealPct  = (hd.overheal / (hd.done + hd.overheal)) * 100
    local targetOH     = (spec.healerMetrics and spec.healerMetrics.targetOverheal) or 30

    if overhealPct <= targetOH then
        return 100
    else
        local excess = overhealPct - targetOH
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
-- Lightweight debug log — ring buffer stored in SavedVariables
-- Survives reloads. Read with /ms debuglog. Max 50 entries.
--------------------------------------------------------------------------------
local function DebugLog(msg)
    if not Core.GetSetting("debugMode") then return end
    if not MidnightSenseiDB then return end
    MidnightSenseiDB.debugLog = MidnightSenseiDB.debugLog or {}
    local buf = MidnightSenseiDB.debugLog
    local entry = date("%H:%M:%S") .. " " .. msg
    table.insert(buf, entry)
    while #buf > 50 do table.remove(buf, 1) end
end
Analytics.DebugLog = DebugLog

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
        -- responsiveness = 75 was a hardcoded placeholder that dragged healer
        -- scores down by ~5 points maximum, making A+ unreachable in practice.
        -- Excluded from scoring until it can be measured from real events.
        -- scores.responsiveness = 75  -- REMOVED: was suppressing healer grades
    end
    if spec.role == Core.ROLE.TANK then
        scores.mitigationUptime = ScoreMitigation(duration)
    end

    -- Debug log: individual component scores and weight coverage
    if Core.GetSetting("debugMode") then
        local parts = {}
        local activeWeight = 0
        local totalWeight  = 0
        for k, w in pairs(weights) do
            totalWeight = totalWeight + w
            local s = scores[k]
            if s then
                activeWeight = activeWeight + w
                parts[#parts+1] = k .. "=" .. math.floor(s)
            else
                parts[#parts+1] = k .. "=EXCLUDED"
            end
        end
        DebugLog("[Grade] dur=" .. math.floor(duration) ..
                 "s weight=" .. activeWeight .. "/" .. totalWeight ..
                 " " .. table.concat(parts, " "))
    end

    local finalScore = math.floor(BuildWeightedScore(scores, weights))
    DebugLog("[Grade] weighted=" .. finalScore)

    -- Behavior-based inference (Part 2) — used only for feedback tone.
    -- Never modifies the score. Derived from combat data only.
    -- Three soft signals that suggest simplified/macro-assisted patterns:
    --   1. Very high activity but zero proc usage detected (even cadence, no snap)
    --   2. All tracked CDs used at least once but never underused (uniform press)
    --   3. Zero overcap events with high activity (unusually clean for manual play)
    local inferSimplified = false
    do
        local actScore = scores.activity or 0
        local highActivity  = actScore >= 85
        local noProcs       = (not scores.procUsage) or scores.procUsage >= 90
        local neverOvercap  = overcapEvents == 0
        local cdUsed = true
        for _, data in pairs(cdTracking) do
            if data.useCount == 0 then cdUsed = false ; break end
        end
        -- Need at least two signals to infer simplified
        local signals = 0
        if highActivity and neverOvercap then signals = signals + 1 end
        if cdUsed and (scores.cooldownUsage or 0) >= 90 then signals = signals + 1 end
        if noProcs then signals = signals + 1 end
        inferSimplified = (signals >= 2) and (FightDur() >= 45)
    end
    DebugLog("[Grade] inferred=" .. (inferSimplified and "simplified" or "manual-leaning"))

    local grade, gradeColor, gradeLabel = Core.GetGrade(finalScore)
    DebugLog("[Grade] final=" .. finalScore .. " grade=" .. grade)

    local feedback = Analytics.GenerateFeedback(scores, duration, inferSimplified)

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
        encType       = currentInstanceContext and currentInstanceContext.encType        or "normal",
        diffLabel     = currentInstanceContext and currentInstanceContext.diffLabel      or "",
        instanceName  = currentInstanceContext and currentInstanceContext.instanceName   or "",
        keystoneLevel = currentInstanceContext and currentInstanceContext.keystoneLevel  or nil,
        -- Time
        timestamp    = time(),
        startTime    = fightStartTime,
        endTime      = fightEndTime,
        duration     = duration,
        weekKey      = (MS.Leaderboard and MS.Leaderboard.GetWeekKey and MS.Leaderboard.GetWeekKey()) or "",
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
-- inferSimplified: soft behavioral inference — only affects tone, never score.
-- Returns a list of coaching strings, with "Biggest Gain" prepended.
--------------------------------------------------------------------------------
function Analytics.GenerateFeedback(scores, duration, inferSimplified)
    local feedback = {}
    local spec     = Core.ActiveSpec
    if not spec then return feedback end

    local function Add(msg) table.insert(feedback, msg) end
    local bossName     = currentBossContext and currentBossContext.name
    local isHealer     = spec.role == Core.ROLE.HEALER
    local isTank       = spec.role == Core.ROLE.TANK
    local expectedMult = math.max(1, math.floor(duration / 120))
    local actScore     = scores.activity or 100

    -- Track highest-impact issue for "Biggest Gain" line.
    -- AddGain adds the message normally AND tracks it. At the end the winning
    -- message is removed from its original position and re-inserted at the top
    -- with the "Biggest Gain:" label — so it appears exactly once.
    local topGainImpact = 0
    local topGainMsg    = nil
    local function AddGain(impact, msg)
        Add(msg)
        if impact > topGainImpact then
            topGainImpact = impact
            topGainMsg    = msg
        end
    end

    -- ── Cooldown Usage ──────────────────────────────────────────────────────
    local neverUsed = {}
    local underused = {}

    if next(cdTracking) then
        for _, cd in ipairs(spec.majorCooldowns or {}) do
            local data = cdTracking[cd.id]
            if data then
                local label = data.label or cd.label or ("Spell "..cd.id)
                if data.useCount == 0 then
                    table.insert(neverUsed, label)
                elseif data.useCount < expectedMult then
                    table.insert(underused,
                        label .. " (" .. data.useCount .. "/" .. expectedMult .. ")")
                end
            end
        end
    else
        -- cdTracking empty — IsPlayerSpell returned nothing. Only list spells as
        -- never-used if the fight was long enough to reasonably expect one press.
        if duration >= 30 then
            for _, cd in ipairs(spec.majorCooldowns or {}) do
                if cd.label then table.insert(neverUsed, cd.label) end
            end
        end
    end

    if #neverUsed > 0 and duration >= 30 then
        table.sort(neverUsed)
        local ctx = bossName and (" during " .. bossName) or ""
        if inferSimplified then
            AddGain(40, "You lost value from unused cooldowns" .. ctx .. ": " ..
                table.concat(neverUsed, ", ") .. ". Even consistent pressing helps.")
        else
            AddGain(40, "Never pressed" .. ctx .. ": " ..
                table.concat(neverUsed, ", ") .. " — align these with burst windows.")
        end
    end

    -- ── Activity / Downtime ──────────────────────────────────────────────────
    if actScore < 80 and totalGCDs > 0 then
        local targetGPM   = isHealer and 25 or isTank and 30 or 40
        local targetTotal = math.floor((duration / 60) * targetGPM)
        local pct         = math.floor((activeGCDs / math.max(1, targetTotal)) * 100)
        if inferSimplified then
            AddGain(30, "Your rotation is consistent, but gaps between casts (" ..
                pct .. "% activity) are the next thing to tighten up.")
        else
            AddGain(30, "Activity: " .. activeGCDs .. "/" .. targetTotal ..
                " GCDs (" .. pct .. "%) — you are losing casts to downtime.")
        end
    end

    -- ── Underused CDs ───────────────────────────────────────────────────────
    if #underused > 0 and duration >= 90 then
        table.sort(underused)
        AddGain(20, "You could squeeze more uses from: " ..
            table.concat(underused, ", ") .. " — one use per 2 min of fight time.")
    end

    -- ── Rotational Spells — important non-cooldown abilities ─────────────────
    -- Only flags spells that were never used in a fight long enough to warrant them.
    -- Avoids false positives: short fights and talent-absent spells are pre-filtered.
    if next(rotationalTracking) then
        local unused = {}
        for _, rs in pairs(rotationalTracking) do
            if rs.useCount == 0 and duration >= rs.minFightSeconds then
                table.insert(unused, rs.label)
            end
        end
        if #unused > 0 then
            table.sort(unused)
            AddGain(25, "Rotational spell(s) never used: " ..
                table.concat(unused, ", ") ..
                " — these are important for your spec's damage output.")
        end
    end

    -- ── DPS / Tank: Procs, Resources, Buffs ─────────────────────────────────
    if not isHealer then
        if scores.procUsage and CL and CL.GetAllProcs then
            local procData = CL.GetAllProcs()
            for _, proc in ipairs(spec.procBuffs or {}) do
                local data = procData[proc.id]
                if data and data.gained and data.gained > 0 then
                    local maxTime = proc.maxStackTime or 10
                    local avgHeld = data.totalActiveTime / data.gained
                    if avgHeld > maxTime * 0.5 then
                        AddGain(15, "You are losing value from delayed " ..
                            (proc.label or "proc") .. " usage (" ..
                            string.format("%.1f", avgHeld) ..
                            "s avg held, budget " .. maxTime .. "s).")
                    end
                end
            end
        end

        local rmScore = scores.resourceMgmt or 100
        if rmScore < 80 then
            AddGain(15, "Overcapped " .. (spec.resourceLabel or "resource") ..
                " " .. overcapEvents ..
                " time(s). Spend before hitting the cap to avoid wasted generation.")
        end

        if scores.debuffUptime and CL and CL.GetAllUptimes then
            local uptimeData = CL.GetAllUptimes(duration)
            for _, buff in ipairs(spec.uptimeBuffs or {}) do
                local data = uptimeData[buff.id]
                if data and data.targetUptime and data.targetUptime > 0
                and data.appCount and data.appCount > 0 then
                    if data.actualPct < data.targetUptime * 0.8 then
                        AddGain(20, (buff.label or "Buff") .. " uptime: " ..
                            math.floor(data.actualPct) .. "% vs " ..
                            data.targetUptime .. "% target — reapply sooner.")
                    end
                end
            end
        end
    end

    -- ── Healer: decision-quality focus ──────────────────────────────────────
    if isHealer then
        if CL and CL.GetHealingData then
            local hd = CL.GetHealingData()
            if hd.done > 0 then
                local overpct = (hd.overheal / (hd.done + hd.overheal)) * 100
                local target  = (spec.healerMetrics and spec.healerMetrics.targetOverheal) or 30
                if overpct > target + 20 then
                    AddGain(25, string.format(
                        "Overheal at %.1f%% — mana is being spent on targets that " ..
                        "do not need it. Cast slightly later or use more reactive heals.",
                        overpct))
                elseif overpct > target + 10 then
                    Add(string.format("Overheal: %.1f%%. Slightly elevated — " ..
                        "consider holding casts on targets above 70%% health.", overpct))
                end
            end
        end
        if actScore < 70 and totalGCDs > 0 then
            Add("When the raid is stable, contribute with damage spells to " ..
                "maintain throughput and Atonement value.")
        end
    end

    -- ── Behavior tone — only when nothing actionable remains ─────────────────
    if inferSimplified and #feedback == 0 then
        Add("Your rotation appears consistent and well-paced. " ..
            "Tightening burst window timing is the next performance step.")
    end

    -- ── Positive if nothing flagged ──────────────────────────────────────────
    if #feedback == 0 then
        if actScore >= 90 and (scores.cooldownUsage or 0) >= 90 then
            Add("Strong execution — cooldowns and activity both on point.")
        else
            Add("Clean performance — keep building on this foundation.")
        end
    end

    -- ── Biggest Performance Gain — label the highest-impact item in-place ────
    -- Rather than removing and re-inserting (which wastes a slot), find the
    -- message in its current position and prefix it with the Biggest Gain label.
    if topGainMsg then
        for i = 1, #feedback do
            if feedback[i] == topGainMsg then
                feedback[i] = "|cffFFD700Biggest Gain:|r " .. topGainMsg
                -- Move it to position 1 if it isn't already
                if i > 1 then
                    local tmp = table.remove(feedback, i)
                    table.insert(feedback, 1, tmp)
                end
                break
            end
        end
    end

    -- Cap at 8 — enough room for Biggest Gain + all meaningful coaching points
    while #feedback > 8 do table.remove(feedback) end

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
