--------------------------------------------------------------------------------
-- Midnight Sensei: Analytics/EncounterStore.lua
-- Saves completed fight results to SavedVariables and updates bests.
-- Called by Engine.lua's OnCombatEnd after CalculateGrade() completes.
-- Owns: db.encounters append, db.bests (all-time, content, weekly, bossBests).
--------------------------------------------------------------------------------

MidnightSensei                          = MidnightSensei                          or {}
MidnightSensei.Analytics                = MidnightSensei.Analytics                or {}
MidnightSensei.Analytics.EncounterStore = MidnightSensei.Analytics.EncounterStore or {}

local MS             = MidnightSensei
local Core           = MS.Core
local EncounterStore = MS.Analytics.EncounterStore

--------------------------------------------------------------------------------
-- SaveEncounter
-- Receives the completed result table from Engine.CalculateGrade() and
-- persists it to MidnightSenseiCharDB.  Also emits GRADE_CALCULATED for
-- leaderboard-eligible fights.
--------------------------------------------------------------------------------
function EncounterStore.SaveEncounter(result)
    local db = MidnightSenseiCharDB
    if not db or not db.encounters then return end

    -- Append to encounter history, cap at 200
    table.insert(db.encounters, result)
    while #db.encounters > 200 do
        table.remove(db.encounters, 1)
    end

    -- Ensure bests structure exists
    db.bests = db.bests or {
        allTimeBest=0, dungeonBest=0, raidBest=0, delveBest=0,
        weeklyAvg=0, weekKey="", weekScores={},
        weeklyDungeonBest=0, weeklyRaidBest=0, weeklyDelveBest=0,
    }
    local bests = db.bests
    local s  = result.finalScore or 0
    local wk = result.weekKey or ""

    -- Reset all weekly data on a new WoW week
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
        if s > (bests.dungeonBest or 0)       then bests.dungeonBest       = s end
        if s > (bests.weeklyDungeonBest or 0) then bests.weeklyDungeonBest = s end
    elseif result.encType == "raid" then
        if s > (bests.raidBest or 0)          then bests.raidBest          = s end
        if s > (bests.weeklyRaidBest or 0)    then bests.weeklyRaidBest    = s end
    elseif result.encType == "delve" then
        if s > (bests.delveBest or 0)         then bests.delveBest         = s end
        if s > (bests.weeklyDelveBest or 0)   then bests.weeklyDelveBest   = s end
    end

    -- Boss-level personal best tracking — powers the Boss Board feature.
    -- Keyed by bossID (ENCOUNTER_START encounter ID). Only boss kills recorded.
    -- Structure: bests.bossBests[bossID] = {
    --   bossName, instanceName, encType, diffLabel, keystoneLevel,
    --   charName, specName, className,
    --   bestScore, bestGrade, bestGradeLabel, bestTimestamp, bestWeekKey,
    --   bestFeedback, bestComponents, bestDuration,
    --   killCount, firstSeen
    -- }
    if result.isBoss and result.bossID then
        bests.bossBests = bests.bossBests or {}
        local bid      = tostring(result.bossID)
        local existing = bests.bossBests[bid]
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

    -- Broadcast to leaderboard for boss fights and content-type fights.
    -- Suppresses open-world trash pulls and target dummy sessions.
    local isLeaderboardEligible = result.isBoss
        or result.encType == "dungeon"
        or result.encType == "raid"
        or result.encType == "delve"

    if isLeaderboardEligible then
        Core.Emit(Core.EVENTS.GRADE_CALCULATED, result)
    end
end
