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
local Core      = MS.Core or MidnightSensei.Core or {}
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
    local db = MidnightSenseiCharDB
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

    -- Helper: check if a talent is active using the most reliable API available.
    -- C_Traits is more reliable for passive/class talent nodes (e.g. Power Infusion,
    -- Misery) that aren't always returned by IsPlayerSpell in Midnight 12.0.
    local function IsTalentActive(spellID)
        if C_Traits and C_Traits.GetNodeInfo then
            local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID
                             and C_ClassTalents.GetActiveConfigID()
            if configID then
                local config = C_Traits.GetConfigInfo and C_Traits.GetConfigInfo(configID)
                if config and config.treeIDs then
                    for _, treeID in ipairs(config.treeIDs) do
                        local nodes = C_Traits.GetTreeNodes and C_Traits.GetTreeNodes(treeID)
                        if nodes then
                            for _, nodeID in ipairs(nodes) do
                                local node = C_Traits.GetNodeInfo(configID, nodeID)
                                if node and node.activeRank and node.activeRank > 0 then
                                    local entry = node.activeEntry
                                    if entry then
                                        local def = C_Traits.GetEntryInfo and C_Traits.GetEntryInfo(configID, entry.entryID)
                                        if def and def.definitionID then
                                            local defInfo = C_Traits.GetDefinitionInfo and C_Traits.GetDefinitionInfo(def.definitionID)
                                            if defInfo and defInfo.spellID == spellID then
                                                return true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return IsPlayerSpell and IsPlayerSpell(spellID) or false
    end

    -- Pre-populate CD tracking — spec cooldowns the player currently has.
    -- IsPlayerSpell works for baseline and spellbook spells.
    -- IsTalentActive catches class talent nodes not always returned by IsPlayerSpell.
    local spec = Core.ActiveSpec
    if spec and spec.majorCooldowns then
        for _, cd in ipairs(spec.majorCooldowns) do
            -- If the spec defines a validSpells whitelist, enforce it strictly
            if spec.validSpells and not spec.validSpells[cd.id] then
                -- spell not whitelisted for this spec — skip entirely
            else
                local known = (IsPlayerSpell and IsPlayerSpell(cd.id))
                           or IsTalentActive(cd.id)
                if known then
                    cdTracking[cd.id] = {
                        lastUsed        = 0,
                        useCount        = 0,
                        expectedUses    = cd.expectedUses,
                        label           = cd.label,
                        minFightSeconds = cd.minFightSeconds,
                    }
                end
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

    -- Helper: check if a talent is active using the most reliable API available.
    -- C_ClassTalents / C_Traits is more reliable for passive talents that stay
    -- in the spellbook regardless of whether the talent is chosen (e.g. Misery).
    -- Populate rotational spell tracking.
    -- No IsPlayerSpell gate by default — presence feedback is the safety net.
    -- Exception: entries marked talentGated=true are gated by IsPlayerSpell
    -- so players without those talents don't get false "never used" feedback.
    -- Exception: entries marked suppressIfTalent=id are suppressed when the
    -- player has that talent (e.g. Misery auto-applies SW:Pain via Vampiric Touch).
    if spec and spec.rotationalSpells then
        for _, rs in ipairs(spec.rotationalSpells) do
            -- Enforce validSpells whitelist if present
            if spec.validSpells and not spec.validSpells[rs.id] then
                -- spell not whitelisted for this spec — skip entirely
            else
                local include = true
                if rs.combatGated then
                    -- Transformation-granted spells (e.g. Collapsing Star inside Void Metamorphosis)
                    -- are not in the spellbook at fight start — always include and rely on
                    -- UNIT_SPELLCAST_SUCCEEDED to register casts, minFightSeconds to gate feedback.
                    include = true
                elseif rs.talentGated then
                    include = (IsPlayerSpell and IsPlayerSpell(rs.id))
                           or IsTalentActive(rs.id)
                end
                if include and rs.suppressIfTalent then
                    if IsTalentActive(rs.suppressIfTalent) then
                        include = false
                    end
                end
                if include then
                    rotationalTracking[rs.id] = {
                        useCount        = 0,
                        label           = rs.label,
                        minFightSeconds = rs.minFightSeconds or 60,
                        combatGated     = rs.combatGated or false,
                        cdSec           = rs.cdSec or nil,  -- optional CD duration for cast-count estimates
                    }
                end
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

    -- Level gate: only score Midnight content (level 80+)  [1.3.8]
    -- Prevents leveling kills, old-world farming, and timewalking alts
    -- from polluting history and averages.
    local playerLevel = UnitLevel("player") or 0
    if playerLevel < 80 then
        SafeCall(MS.UI, "OnCombatEnd", nil)
        return
    end

    local result = Analytics.CalculateGrade()
    Analytics.LastResult = result

    if result then
        -- Save every encounter to history (for history panel / trending)
        local db = MidnightSenseiCharDB
        if db and db.encounters then
            table.insert(db.encounters, result)
            while #db.encounters > 200 do
                table.remove(db.encounters, 1)
            end

            -- Update persistent bests — these survive the encounter cap.
            db.bests = db.bests or {
                allTimeBest=0, dungeonBest=0, raidBest=0, delveBest=0,
                weeklyAvg=0, weekKey="", weekScores={},
                weeklyDungeonBest=0, weeklyRaidBest=0, weeklyDelveBest=0,
            }
            local bests = db.bests
            local s  = result.finalScore or 0
            local wk = result.weekKey or ""

            -- Reset all weekly data on new WoW week
            if bests.weekKey ~= wk then
                bests.weekKey           = wk
                bests.weekScores        = {}
                bests.weeklyAvg         = 0
                bests.weeklyDungeonBest = 0
                bests.weeklyRaidBest    = 0
                bests.weeklyDelveBest   = 0
            end

            -- All-time best — every fight, every content type
            if s > (bests.allTimeBest or 0) then bests.allTimeBest = s end

            -- Content-specific all-time AND weekly bests
            if result.encType == "dungeon" then
                if s > (bests.dungeonBest or 0)        then bests.dungeonBest        = s end
                if s > (bests.weeklyDungeonBest or 0)  then bests.weeklyDungeonBest  = s end
            elseif result.encType == "raid" then
                if s > (bests.raidBest or 0)           then bests.raidBest           = s end
                if s > (bests.weeklyRaidBest or 0)     then bests.weeklyRaidBest     = s end
            elseif result.encType == "delve" then
                if s > (bests.delveBest or 0)          then bests.delveBest          = s end
                if s > (bests.weeklyDelveBest or 0)    then bests.weeklyDelveBest    = s end
            end

            -- Boss-level personal best tracking — powers the Boss Board feature.
            -- Keyed by bossID (ENCOUNTER_START encounter ID). Only boss kills recorded.
            -- Structure: bests.bossBests[bossID] = {
            --   bossName, instanceName, encType, diffLabel, keystoneLevel,
            --   charName, specName, className,
            --   bestScore, bestGrade, bestTimestamp, bestWeekKey,
            --   killCount, firstSeen
            -- }
            if result.isBoss and result.bossID then
                bests.bossBests = bests.bossBests or {}
                local bid = tostring(result.bossID)
                local existing = bests.bossBests[bid]
                local s = result.finalScore or 0
                if not existing then
                    bests.bossBests[bid] = {
                        bossName        = result.bossName      or "?",
                        instanceName    = result.instanceName  or "",
                        encType         = result.encType       or "normal",
                        diffLabel       = result.diffLabel     or "",
                        keystoneLevel   = result.keystoneLevel or nil,
                        charName        = result.charName      or (UnitName("player") or "?"),
                        specName        = result.specName      or (Core.ActiveSpec and Core.ActiveSpec.name or "?"),
                        className       = result.className     or (Core.ActiveSpec and Core.ActiveSpec.className or "?"),
                        bestScore       = s,
                        bestGrade       = result.finalGrade    or "--",
                        bestGradeLabel  = result.gradeLabel    or "",
                        bestTimestamp   = result.timestamp,
                        bestWeekKey     = result.weekKey       or "",
                        bestFeedback    = result.feedback      or {},
                        bestComponents  = result.componentScores or {},
                        bestDuration    = result.duration      or 0,
                        killCount       = 1,
                        firstSeen       = result.timestamp,
                    }
                else
                    existing.killCount = (existing.killCount or 0) + 1
                    if s > (existing.bestScore or 0) then
                        existing.bestScore      = s
                        existing.bestGrade      = result.finalGrade   or "--"
                        existing.bestGradeLabel = result.gradeLabel   or ""
                        existing.bestTimestamp  = result.timestamp
                        existing.bestWeekKey    = result.weekKey      or ""
                        existing.bestFeedback   = result.feedback     or {}
                        existing.bestComponents = result.componentScores or {}
                        existing.bestDuration   = result.duration     or 0
                        existing.diffLabel      = result.diffLabel    or existing.diffLabel
                        existing.keystoneLevel  = result.keystoneLevel or existing.keystoneLevel
                        existing.instanceName   = result.instanceName or existing.instanceName
                        existing.charName       = result.charName     or existing.charName
                        existing.specName       = result.specName     or existing.specName
                        existing.className      = result.className    or existing.className
                    end
                end
            end

            -- Overall weekly avg — boss kills across all content (for leaderboard sort)
            if result.isBoss then
                bests.weekScores = bests.weekScores or {}
                table.insert(bests.weekScores, s)
                if #bests.weekScores > 50 then table.remove(bests.weekScores, 1) end
                local sum = 0
                for _, v in ipairs(bests.weekScores) do sum = sum + v end
                bests.weeklyAvg = math.floor(sum / #bests.weekScores)
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

        -- UnitPower can return a tainted value in combat in Midnight 12.0.
        -- Wrap in pcall so a taint error doesn't surface to the user.
        local ok, cur = pcall(UnitPower, "player", spec.resourceType)
        if not ok or type(cur) ~= "number" then return end
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

    scores._final = finalScore  -- available to GenerateFeedback for tier-aware fallback
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

    local interruptNeverUsed = {}  -- informational only, not penalised

    if next(cdTracking) then
        for _, cd in ipairs(spec.majorCooldowns or {}) do
            local data = cdTracking[cd.id]
            if data then
                local minSecs = cd.minFightSeconds or 30
                local label = data.label or cd.label or ("Spell "..cd.id)
                if cd.isInterrupt then
                    -- Interrupts: track but never penalise — collect for informational note only
                    if data.useCount == 0 and duration >= minSecs then
                        table.insert(interruptNeverUsed, label)
                    end
                elseif data.useCount == 0 and duration >= minSecs then
                    table.insert(neverUsed, label)
                elseif data.useCount < expectedMult and duration >= minSecs then
                    table.insert(underused,
                        label .. " (" .. data.useCount .. "/" .. expectedMult .. ")")
                end
            end
        end
    else
        if duration >= 30 then
            for _, cd in ipairs(spec.majorCooldowns or {}) do
                if not cd.isInterrupt and cd.label then
                    table.insert(neverUsed, cd.label)
                end
            end
        end
    end

    if #neverUsed > 0 and duration >= 30 then
        table.sort(neverUsed)
        local ctx = bossName and (" during " .. bossName) or ""
        local action = isTank   and "use on tank busters or high damage windows"
                    or isHealer and "align with high incoming damage windows"
                    or             "align these with burst windows"
        if inferSimplified then
            AddGain(40, "You lost value from unused cooldowns" .. ctx .. ": " ..
                table.concat(neverUsed, ", ") .. ". Even consistent pressing helps.")
        else
            AddGain(40, "Never pressed" .. ctx .. ": " ..
                table.concat(neverUsed, ", ") .. " — " .. action .. ".")
        end
    end

    -- Interrupt note appended at the very bottom after all feedback — see end of function

    -- ── Activity / Downtime ──────────────────────────────────────────────────
    if actScore < 85 and totalGCDs > 0 then
        local targetGPM   = isHealer and 25 or isTank and 30 or 40
        local targetTotal = math.floor((duration / 60) * targetGPM)
        local pct         = math.floor((activeGCDs / math.max(1, targetTotal)) * 100)
        local lost        = targetTotal - activeGCDs
        if inferSimplified then
            AddGain(30, "Your rotation is consistent, but gaps between casts (" ..
                pct .. "% activity) are the next thing to tighten up.")
        elseif actScore >= 80 then
            -- 80-84 range: positive framing, specific number
            AddGain(15, "Activity at " .. pct .. "% — roughly " .. lost ..
                " cast(s) left on the table. Queue your next spell before the current one lands.")
        else
            local severity = pct < 60 and "significant" or "moderate"
            AddGain(30, "Activity: " .. activeGCDs .. "/" .. targetTotal ..
                " GCDs (" .. pct .. "%) — " .. severity .. " downtime, approximately " ..
                lost .. " casts lost. Find your next spell before the current one finishes.")
        end
    end

    -- ── Underused CDs ───────────────────────────────────────────────────────
    if #underused > 0 and duration >= 90 then
        table.sort(underused)
        local fightMins = string.format("%.1f", duration / 60)
        AddGain(20, "Used less than expected in a " .. fightMins .. "min fight: " ..
            table.concat(underused, ", ") ..
            " — target 1 use per 2 minutes of fight time.")
    end

    -- ── Rotational spell cast count ─────────────────────────────────────────
    -- For spells we did track casts on, surface how many more could have fit
    -- in the fight. This fires even at high scores — a player casting Void Ray
    -- 6 times when 9 were possible still has room to improve.
    if next(rotationalTracking) then
        local unused  = {}
        local lowUsed = {}
        for id, rs in pairs(rotationalTracking) do
            if rs.useCount == 0 and duration >= rs.minFightSeconds and not rs.combatGated then
                table.insert(unused, rs.label)
            elseif rs.useCount > 0 and not rs.combatGated then
                -- If the spec defines a cdSec for this rotational spell, estimate
                -- how many casts should have fit in the fight.
                local cdSec = rs.cdSec  -- populated from spec if present
                if cdSec and cdSec > 0 and duration >= rs.minFightSeconds then
                    local potential = math.max(1, math.floor(duration / cdSec))
                    local missed    = potential - rs.useCount
                    if missed >= 2 then
                        table.insert(lowUsed, rs.label ..
                            " (" .. rs.useCount .. "/" .. potential .. ")")
                    end
                end
            end
        end
        if #unused > 0 then
            table.sort(unused)
            local context = isTank   and "survival and threat rotation"
                         or isHealer and "healing throughput"
                         or             "damage output"
            AddGain(25, "Rotational spell(s) never used: " ..
                table.concat(unused, ", ") ..
                " — these are core to your " .. context .. ".")
        end
        if #lowUsed > 0 then
            table.sort(lowUsed)
            AddGain(10, "Could have cast more: " .. table.concat(lowUsed, ", ") ..
                " — press these on every available GCD when your primary spenders are on cooldown.")
        end
    end

    -- ── Non-healer: Procs, Resources, Mitigation, Buffs ─────────────────────
    if not isHealer then

        -- Procs
        if scores.procUsage and CL and CL.GetAllProcs then
            local procData = CL.GetAllProcs()
            for _, proc in ipairs(spec.procBuffs or {}) do
                local data = procData[proc.id]
                if data and data.gained and data.gained > 0 then
                    local maxTime = proc.maxStackTime or 10
                    local avgHeld = data.totalActiveTime / data.gained
                    if avgHeld > maxTime * 0.5 then
                        local heldStr = string.format("%.1f", avgHeld)
                        local severity = avgHeld > maxTime * 0.8 and "critically delayed" or "delayed"
                        AddGain(15, (proc.label or "Proc") .. " consumption is " .. severity ..
                            " — held " .. heldStr .. "s on average (budget: " .. maxTime ..
                            "s). Consume procs immediately when they appear.")
                    end
                end
            end
        end

        -- Resource overcap
        local rmScore = scores.resourceMgmt or 100
        if rmScore < 80 then
            local rate = string.format("%.1f", overcapEvents / math.max(1, duration / 60))
            AddGain(15, "Overcapped " .. (spec.resourceLabel or "resource") .. " " ..
                overcapEvents .. " time(s) (" .. rate .. "/min) — spend " ..
                (spec.resourceLabel or "resource") ..
                " before reaching " .. (spec.overcapAt or 100) ..
                " to avoid wasted generation.")
        end

        -- Tank: mitigation uptime
        if isTank and scores.mitigationUptime and CL and CL.GetAllUptimes then
            local uptimeData = CL.GetAllUptimes(duration)
            for _, buff in ipairs(spec.uptimeBuffs or {}) do
                local data = uptimeData[buff.id]
                if data and data.targetUptime and data.targetUptime > 0 then
                    local actual  = math.floor(data.actualPct)
                    local target  = data.targetUptime
                    local apps    = data.appCount or 0
                    local label   = buff.label or "Mitigation"
                    if apps == 0 then
                        AddGain(35, label .. " was never activated — press it on cooldown " ..
                            "every time it is available to reduce physical damage taken.")
                    elseif actual < target * 0.6 then
                        local gap = target - actual
                        AddGain(30, label .. ": " .. actual .. "% uptime vs " .. target ..
                            "% target (" .. gap .. "pt gap, " .. apps ..
                            " application(s)) — you have large windows of unmitigated " ..
                            "physical damage. Press it the moment it comes off cooldown.")
                    elseif actual < target * 0.8 then
                        local gap = target - actual
                        AddGain(20, label .. ": " .. actual .. "% uptime vs " .. target ..
                            "% target (" .. gap .. "pt gap) — small gaps are adding up. " ..
                            "Use it preemptively on heavy melee sequences, not reactively.")
                    end
                end
            end
        end

        -- DPS: self-buff uptime
        if not isTank and scores.debuffUptime and CL and CL.GetAllUptimes then
            local uptimeData = CL.GetAllUptimes(duration)
            for _, buff in ipairs(spec.uptimeBuffs or {}) do
                local data = uptimeData[buff.id]
                if data and data.targetUptime and data.targetUptime > 0
                and data.appCount and data.appCount > 0 then
                    if data.actualPct < data.targetUptime * 0.8 then
                        local gap = data.targetUptime - math.floor(data.actualPct)
                        AddGain(20, (buff.label or "Buff") .. ": " ..
                            math.floor(data.actualPct) .. "% uptime vs " ..
                            data.targetUptime .. "% target (" .. gap ..
                            "pt gap) — reapply before it expires, not after.")
                    end
                end
            end
        end
    end

    -- ── Healer feedback ──────────────────────────────────────────────────────
    if isHealer then
        if CL and CL.GetHealingData then
            local hd = CL.GetHealingData()
            if hd.done > 0 then
                local overpct = (hd.overheal / (hd.done + hd.overheal)) * 100
                local target  = (spec.healerMetrics and spec.healerMetrics.targetOverheal) or 30
                if overpct > target + 20 then
                    AddGain(25, string.format(
                        "Overheal at %.1f%% (target: <%d%%) — you are spending mana on " ..
                        "targets that do not need healing. Cast slightly later or " ..
                        "switch to reactive spells on targets actively taking damage.",
                        overpct, target))
                elseif overpct > target + 10 then
                    Add(string.format(
                        "Overheal: %.1f%% (target: <%d%%) — slightly elevated. " ..
                        "Hold casts on targets above 70%% health and prioritise " ..
                        "HoTs over direct heals on stable groups.",
                        overpct, target))
                end
            end
        end
        if actScore < 70 and totalGCDs > 0 then
            Add("When the group is stable, fill downtime with damage spells " ..
                "to maintain throughput and Atonement value.")
        end
    end

    -- ── Behavior tone fallback ───────────────────────────────────────────────
    if inferSimplified and #feedback == 0 then
        Add("Your rotation is consistent and well-paced. " ..
            "Tightening burst window timing is the next performance step.")
    end

    -- ── Nothing flagged ──────────────────────────────────────────────────────
    if #feedback == 0 then
        local cdScore  = scores.cooldownUsage    or 100
        local mitScore = scores.mitigationUptime or 100
        local allHigh  = actScore >= 90 and cdScore >= 90
                      and (not isTank or mitScore >= 90)
        local finalScore = scores._final or 0

        if allHigh and finalScore >= 95 then
            -- Near-perfect: give them something to reach for
            local nextSteps = {}
            if isTank then
                table.insert(nextSteps, "pre-position defensives before predictable spike damage")
            elseif isHealer then
                table.insert(nextSteps, "overlap cooldowns with incoming damage casts rather than reacting")
            else
                table.insert(nextSteps, "align burst windows with enemy vulnerability phases")
            end
            table.insert(nextSteps, "reduce time between the GCD ending and your next cast to sub-0.2s")
            Add("Near-perfect execution. The remaining gains are: " ..
                table.concat(nextSteps, "; ") .. ".")
        elseif allHigh then
            -- 90-94: identify the weakest scoring category
            local weakest = nil
            local weakScore = 100
            for cat, val in pairs(scores) do
                if cat ~= "_final" and type(val) == "number" and val < weakScore then
                    weakScore = val
                    weakest   = cat
                end
            end
            local catHint = weakest and weakest:gsub("(%l)(%u)", "%1 %2"):lower() or "cooldown timing"
            Add("Strong execution overall. Your lowest category is " ..
                catHint .. " — that is where the next points come from.")
        elseif cdScore < 80 or mitScore < 80 then
            local hints = {}
            if cdScore < 80 then
                table.insert(hints, isTank
                    and "use defensive cooldowns on tank busters"
                    or  "press major cooldowns more consistently")
            end
            if isTank and mitScore < 80 then
                table.insert(hints, "increase mitigation uptime by pressing Demon Spikes more frequently")
            end
            Add("Good foundation — focus next on: " .. table.concat(hints, "; ") .. ".")
        else
            Add("Solid performance — tighten up cooldown timing to push higher.")
        end
    end

    -- Cap at 8 — enough room for Biggest Gain + all meaningful coaching points
    while #feedback > 8 do table.remove(feedback) end

    -- Interrupt note always appended last — friendly reminder, never penalised, never buried
    if #interruptNeverUsed > 0 then
        table.insert(feedback, "Note: " .. table.concat(interruptNeverUsed, ", ") ..
            " — this is your interrupt. Not used this fight — no penalty.")
    end

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
