--------------------------------------------------------------------------------
-- Midnight Sensei: Analytics/Engine.lua
-- Combat lifecycle, fight state, and public Analytics API.
-- Orchestrates Scoring.lua, Feedback.lua, EncounterStore.lua, and the
-- Combat/* tracker modules.
--
-- Combat data is now owned by the Combat/* trackers and read at fight end
-- via MS.CombatLog getter functions:
--   MS.CombatLog.GetCdTracking()         → Combat/CastTracker.lua
--   MS.CombatLog.GetRotationalTracking() → Combat/CastTracker.lua
--   MS.CombatLog.GetTotalGCDs()          → Combat/CastTracker.lua
--   MS.CombatLog.GetActiveGCDs()         → Combat/CastTracker.lua
--   MS.CombatLog.GetOvercapEvents()      → Combat/ResourceTracker.lua
--   MS.CombatLog.GetAllUptimes(d)        → Combat/AuraTracker.lua
--   MS.CombatLog.GetAllProcs()           → Combat/ProcTracker.lua
--   MS.CombatLog.GetHealingData()        → Combat/HealingTracker.lua
--
-- Submodule load order (TOC):
--   Combat/CombatLog.lua      → MS.CombatLog namespace + dispatcher
--   Combat/CastTracker.lua    }
--   Combat/AuraTracker.lua    }  populate MS.CombatLog.Get*() functions
--   Combat/ProcTracker.lua    }
--   Combat/ResourceTracker.lua}
--   Combat/HealingTracker.lua }
--   Analytics/EncounterStore.lua
--   Analytics/Scoring.lua
--   Analytics/Feedback.lua
--   Analytics/Engine.lua      ← this file (loads last; defines public API)
--
-- All public functions remain on MS.Analytics for full backwards compatibility.
--------------------------------------------------------------------------------

MidnightSensei           = MidnightSensei           or {}
MidnightSensei.Analytics = MidnightSensei.Analytics or {}

local MS        = MidnightSensei
local Analytics = MS.Analytics
local Core      = MS.Core or MidnightSensei.Core or {}
local Utils     = MS.Utils

local function SafeCall(mod, fn, ...)
    local f = mod and mod[fn]
    if type(f) == "function" then return f(...) end
end

--------------------------------------------------------------------------------
-- Fight state — only what Engine.lua still owns after the Combat/* split
--------------------------------------------------------------------------------
local fightActive      = false
local fightStartTime   = 0
local fightEndTime     = 0
local bossKillSuccess  = false  -- set true by BOSS_END with success=1; false if boss wipe

-- Real-time feedback queue (displayed in UI ticker)
local feedbackQueue = {}

-- Boss and instance context snapshots — captured at fight start, updated on BOSS_START
local currentBossContext     = nil
local currentInstanceContext = nil

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function Now()      return GetTime() end
local function FightDur() return math.max(1, (fightEndTime > 0 and fightEndTime or Now()) - fightStartTime) end

local function QueueFeedback(msg, priority)
    table.insert(feedbackQueue, { msg = msg, priority = priority or 1, time = Now() })
end

local function FlushFeedback()
    feedbackQueue = {}
end

--------------------------------------------------------------------------------
-- State snapshot — built for Scoring and Feedback at fight end.
-- Reads combat counters from tracker getters (MS.CombatLog.Get*).
--------------------------------------------------------------------------------
local function BuildState()
    local CT = MS.CombatLog
    return {
        spec               = Core.ActiveSpec,
        cdTracking         = CT and CT.GetCdTracking         and CT.GetCdTracking()         or {},
        rotationalTracking = CT and CT.GetRotationalTracking and CT.GetRotationalTracking() or {},
        overcapEvents      = CT and CT.GetOvercapEvents      and CT.GetOvercapEvents()      or 0,
        totalGCDs          = CT and CT.GetTotalGCDs          and CT.GetTotalGCDs()          or 0,
        activeGCDs         = CT and CT.GetActiveGCDs         and CT.GetActiveGCDs()         or 0,
        currentBossContext = currentBossContext,
        -- fightSuccess: true for non-boss content (survived = success); for boss
        -- encounters, reflects whether BOSS_END fired with success=1 before fight end.
        fightSuccess       = (currentBossContext == nil) or bossKillSuccess,
        CL                 = MS.CombatLog,
    }
end

--------------------------------------------------------------------------------
-- Lightweight debug log — ring buffer stored in SavedVariables
-- Survives reloads.  Read with /ms debuglog.  Max 50 entries.
--------------------------------------------------------------------------------
local function DebugLog(msg)
    if not Core.GetSetting("debugMode") then return end
    if not MidnightSenseiDB then return end
    MidnightSenseiDB.debugLog = MidnightSenseiDB.debugLog or {}
    local buf   = MidnightSenseiDB.debugLog
    local entry = date("%H:%M:%S") .. " " .. msg
    table.insert(buf, entry)
    while #buf > 50 do table.remove(buf, 1) end
end
Analytics.DebugLog = DebugLog

--------------------------------------------------------------------------------
-- Expose last completed result, falling back to the most recent DB entry on login
--------------------------------------------------------------------------------
function Analytics.GetLastEncounter()
    if Analytics.LastResult then return Analytics.LastResult end
    local db = MidnightSenseiCharDB
    if db and db.encounters and #db.encounters > 0 then
        return db.encounters[#db.encounters]
    end
    return nil
end

--------------------------------------------------------------------------------
-- Combat start hook
-- Combat data reset is now handled by the Combat/* trackers (earlier in TOC).
-- Engine.lua only resets fight timing and context snapshots here.
--------------------------------------------------------------------------------
local function OnCombatStart()
    fightActive      = true
    fightStartTime   = Now()
    fightEndTime     = 0
    bossKillSuccess  = false
    FlushFeedback()

    -- Snapshot boss context (will be overwritten by BOSS_START if one fires)
    currentBossContext = Core.CurrentEncounter and Core.CurrentEncounter.isBoss
        and { name = Core.CurrentEncounter.name, id = Core.CurrentEncounter.id,
              difficultyID = Core.CurrentEncounter.difficultyID }
        or nil

    -- Snapshot instance context for difficulty labelling
    currentInstanceContext = nil
    if MS.Leaderboard and MS.Leaderboard.GetInstanceContext then
        currentInstanceContext = MS.Leaderboard.GetInstanceContext()
    else
        local ic = Core.CombatInstanceContext
        if ic then
            local iType   = ic.instanceType or "none"
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

    SafeCall(MS.UI, "OnCombatStart")
end

--------------------------------------------------------------------------------
-- Combat end hook
--------------------------------------------------------------------------------
local function OnCombatEnd(duration)
    fightActive  = false
    -- Use fightStartTime + duration rather than Now() — COMBAT_END may fire up to
    -- COMBAT_END_GRACE seconds after the actual end due to the debounce in Core.lua.
    -- Duration was captured at PLAYER_REGEN_ENABLED time so this is the real end.
    fightEndTime = fightStartTime + (duration or 0)

    -- Minimum fight threshold
    local minFight = Core.GetSetting("minimumFight") or 15
    if (fightEndTime - fightStartTime) < minFight then
        SafeCall(MS.UI, "OnCombatEnd", nil)
        return
    end

    -- Level gate: only score Midnight content (level 80+)
    local playerLevel = UnitLevel("player") or 0
    if playerLevel < 80 then
        SafeCall(MS.UI, "OnCombatEnd", nil)
        return
    end

    local result = Analytics.CalculateGrade()
    Analytics.LastResult = result

    if result then
        local EncounterStore = MS.Analytics.EncounterStore
        if EncounterStore and EncounterStore.SaveEncounter then
            EncounterStore.SaveEncounter(result)
        end
    end

    SafeCall(MS.UI, "OnCombatEnd", result)
end

Core.On(Core.EVENTS.COMBAT_START, OnCombatStart)
Core.On(Core.EVENTS.COMBAT_END,   OnCombatEnd)

-- BOSS_START fires after PLAYER_REGEN_DISABLED, so update currentBossContext here.
Core.On(Core.EVENTS.BOSS_START, function(encID, encName, diffID)
    if fightActive then
        currentBossContext = { name = encName, id = encID, difficultyID = diffID }
    end
end)

-- Keep boss context live until fight ends so CalculateGrade can read it.
-- OnCombatEnd fires after ENCOUNTER_END; context is cleared by the next OnCombatStart.
-- Capture success here so healerConditional scoring knows if the boss was killed.
Core.On(Core.EVENTS.BOSS_END, function(encID, encName, diffID, success)
    bossKillSuccess = (success == 1 or success == true)
end)

-- ResourceTracker emits MS_OVERCAP_DETECTED when the player enters overcap.
-- Queue the real-time warning here, keeping feedbackQueue private to Engine.lua.
Core.On("MS_OVERCAP_DETECTED", function(label, cur, cap)
    if fightActive then
        QueueFeedback("Watch your " .. label ..
                      " — you're overcapping! (" .. cur .. "/" .. cap .. ")", 2)
    end
end)

--------------------------------------------------------------------------------
-- Main Grade Calculator
-- Reads combat data from MS.CombatLog getters (populated by Combat/* trackers).
-- Delegates score math to Scoring.lua and feedback to Feedback.lua.
--------------------------------------------------------------------------------
function Analytics.CalculateGrade()
    local spec = Core.ActiveSpec
    if not spec then return nil end

    local duration = FightDur()
    local state    = BuildState()
    state.spec     = spec  -- ensure spec is set in state

    -- Delegate to Scoring submodule
    local Scoring = MS.Analytics.Scoring
    local scores, finalScore, weights = Scoring.Calculate(state, duration)

    -- Debug log: component scores and weight coverage
    if Core.GetSetting("debugMode") then
        local parts        = {}
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
    DebugLog("[Grade] weighted=" .. finalScore)

    -- Behavior-based inference — affects feedback tone only, never the score.
    -- Three soft signals that suggest simplified/macro-assisted patterns.
    local inferSimplified = false
    do
        local CT          = MS.CombatLog
        local cdTrack     = CT and CT.GetCdTracking and CT.GetCdTracking() or {}
        local ovEvents    = CT and CT.GetOvercapEvents and CT.GetOvercapEvents() or 0
        local actScore    = scores.activity or 0
        local highActivity = actScore >= 85
        local noProcs      = (not scores.procUsage) or scores.procUsage >= 90
        local neverOvercap = ovEvents == 0
        local cdUsed       = true
        for _, data in pairs(cdTrack) do
            if data.useCount == 0 then cdUsed = false ; break end
        end
        local signals = 0
        if highActivity and neverOvercap then signals = signals + 1 end
        if cdUsed and (scores.cooldownUsage or 0) >= 90 then signals = signals + 1 end
        if noProcs then signals = signals + 1 end
        inferSimplified = (signals >= 2) and (FightDur() >= 45)
    end
    DebugLog("[Grade] inferred=" .. (inferSimplified and "simplified" or "manual-leaning"))

    local grade, gradeColor, gradeLabel = Core.GetGrade(finalScore)
    DebugLog("[Grade] final=" .. finalScore .. " grade=" .. grade)

    scores._final = finalScore  -- passed to Feedback for tier-aware fallback

    -- Delegate to Feedback submodule
    local FeedbackMod = MS.Analytics.Feedback
    local feedback    = FeedbackMod.Generate(scores, duration, inferSimplified, state)

    local CT = MS.CombatLog
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
        encType       = currentInstanceContext and currentInstanceContext.encType       or "normal",
        diffLabel     = currentInstanceContext and currentInstanceContext.diffLabel     or "",
        instanceName  = currentInstanceContext and currentInstanceContext.instanceName  or "",
        keystoneLevel = currentInstanceContext and currentInstanceContext.keystoneLevel or nil,
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
        grade        = grade,       -- shorthand alias used by leaderboard
        -- Feedback
        feedback     = feedback,
        addonVersion = Core.VERSION or "?",
        -- Raw counters (sourced from tracker getters)
        totalGCDs     = CT and CT.GetTotalGCDs    and CT.GetTotalGCDs()    or 0,
        activeGCDs    = CT and CT.GetActiveGCDs   and CT.GetActiveGCDs()   or 0,
        overcapEvents = CT and CT.GetOvercapEvents and CT.GetOvercapEvents() or 0,
    }

    return result
end

--------------------------------------------------------------------------------
-- Compatibility re-export: callers that call MS.Analytics.GenerateFeedback()
-- directly still work.
--------------------------------------------------------------------------------
function Analytics.GenerateFeedback(scores, duration, inferSimplified)
    local state = BuildState()
    return MS.Analytics.Feedback.Generate(scores, duration, inferSimplified, state)
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

function Analytics.GetRotationalTracking()
    local CT = MS.CombatLog
    if CT and CT.GetRotationalTracking then
        return CT.GetRotationalTracking()
    end
    return {}
end
