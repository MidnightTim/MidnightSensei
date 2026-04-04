--------------------------------------------------------------------------------
-- Midnight Sensei: Leaderboard.lua
-- Social leaderboard: Party / Guild / Friends
--
-- Protocol prefix: "MS_LB"
-- Message format (pipe-delimited):
--   SCORE|ver|class|spec|role|grade|score|duration|isBoss|bossName|encType|checksum
--   HELLO|ver|class|spec
--
-- Integrity: each score message includes a checksum = bit.bxor of
--   (score * 7 + duration * 3 + playerGUID_crc) so trivially doctored values
--   fail validation on the receiver's side.
--
-- Leaderboard categories:
--   "dungeon"  - boss fight inside an instance (5-man/M+)
--   "raid"     - boss fight inside a raid instance
--   "normal"   - non-boss combat
--
-- Weekly rolling average: each player entry stores a weekKey (YYYYWW).
--   On a new week the weekly avg resets. The leaderboard sorts by
--   weeklyAvg desc, then allTimeBest desc, making consistent weekly
--   performance matter more than a single lucky A+.
--------------------------------------------------------------------------------

MidnightSensei             = MidnightSensei             or {}
MidnightSensei.Core        = MidnightSensei.Core        or {}
MidnightSensei.Analytics   = MidnightSensei.Analytics   or {}
MidnightSensei.Leaderboard = MidnightSensei.Leaderboard or {}

local MS   = MidnightSensei
local LB   = MS.Leaderboard
local Core = MS.Core

local LB_PREFIX = "MS_LB"

--------------------------------------------------------------------------------
-- Week key helper
-- WoW weekly reset: Tuesday 7:00 AM PDT (UTC-7) = Tuesday 14:00 UTC
-- We compute which "WoW week" we're in by anchoring to that boundary.
-- A WoW week runs Tue 14:00 UTC → Tue 13:59 UTC the following week.
--------------------------------------------------------------------------------
local function GetWeekKey()
    local utcTime  = time()          -- seconds since epoch (UTC)
    -- Shift clock back by 14 hours so Tuesday 14:00 UTC becomes Tuesday 00:00
    local shifted  = utcTime - (14 * 3600)
    local t        = date("!*t", shifted)   -- UTC broken-down time of shifted clock
    -- Find how many days past the most recent Tuesday (weekday: 1=Sun…7=Sat; Tue=3)
    local wday     = t.wday   -- 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
    local daysSinceTue = (wday - 3 + 7) % 7
    -- Step back to the Tuesday of this WoW week
    local tueSec   = shifted - daysSinceTue * 86400
    local tue      = date("!*t", tueSec)
    -- Key = YYYYMMDD of that Tuesday (unique per WoW week)
    return string.format("%04d%02d%02d", tue.year, tue.month, tue.mday)
end

--------------------------------------------------------------------------------
-- Instance context snapshot
-- Called at fight start (PLAYER_REGEN_DISABLED) to capture full instance info.
-- Returns a context table: { encType, diffLabel, keystoneLevel }
--
-- encType:   "dungeon" | "raid" | "delve" | "normal"
-- diffLabel: "Normal" | "Heroic" | "Mythic" | "M+12" | "LFR" |
--            "Tier 8" (delve) | "World" etc.
-- keystoneLevel: number or nil
--------------------------------------------------------------------------------
local RAID_DIFF = {
    [17] = "LFR",
    [14] = "Normal",   -- Normal Raid (flex)
    [15] = "Heroic",
    [16] = "Mythic",
}
local DUNGEON_DIFF = {
    [1]  = "Normal",
    [2]  = "Heroic",
    [23] = "Mythic",   -- Mythic keystone / M+
    [8]  = "Mythic",   -- Regular Mythic (no key)
}

-- Known Delve difficultyIDs.
-- Legacy (pre-Midnight): 167–177 = Tier 1–11 (offset from 166)
-- Midnight 12.0: single diffID 208 with diffName="Delves"; tier from C_Delves API
local DELVE_DIFF_IDS = {
    [167] = true, [168] = true, [169] = true, [170] = true,
    [171] = true, [172] = true, [173] = true, [174] = true,
    [175] = true, [176] = true, [177] = true,
    [208] = true,   -- Midnight 12.0 unified delve difficultyID
}

-- Tier level API (C_Delves) is nil in Midnight 12.0 — Blizzard does not expose it.
-- Returns nil; callers fall back to instance name for display.
local function GetDelveTier() return nil end

local function GetInstanceContext()
    local instName, instType, diffID, diffName,
          maxPlayers, dynDiff, isDynamic, instMapID = GetInstanceInfo()

    local ctx = { encType = "normal", diffLabel = "World", keystoneLevel = nil, instanceName = "" }

    if not instType or instType == "none" then return ctx end

    if instType == "raid" then
        ctx.encType      = "raid"
        ctx.diffLabel    = RAID_DIFF[diffID] or diffName or "Raid"
        ctx.instanceName = instName or ""

    elseif instType == "party" then
        ctx.encType      = "dungeon"
        ctx.instanceName = instName or ""
        local keystoneLevel = nil
        if C_ChallengeMode and C_ChallengeMode.GetSlottedKeystoneInfo then
            local ok, _, _, ksLevel = pcall(C_ChallengeMode.GetSlottedKeystoneInfo)
            if ok and ksLevel and ksLevel > 0 then
                keystoneLevel       = ksLevel
                ctx.diffLabel       = "M+" .. ksLevel
                ctx.keystoneLevel   = ksLevel
            end
        end
        if not keystoneLevel then
            ctx.diffLabel = DUNGEON_DIFF[diffID] or diffName or "Dungeon"
        end

    elseif instType == "scenario" then
        local lowerDiff = (diffName or ""):lower()
        local lowerName = (instName or ""):lower()
        if DELVE_DIFF_IDS[diffID]
        or lowerDiff:find("delve") or lowerName:find("delve") then
            ctx.encType      = "delve"
            ctx.instanceName = instName or ""
            -- Try live Delve API first (Midnight 12.0 uses unified diffID 208)
            local tier = GetDelveTier()
            -- Legacy fallback: diffID 167-177 encode tier directly via offset
            if not tier and diffID >= 167 and diffID <= 177 then
                tier = diffID - 166
            end
            ctx.diffLabel = tier and ("Tier " .. tier) or (instName or diffName or "Delve")
        else
            ctx.encType      = "dungeon"
            ctx.instanceName = instName or ""
            ctx.diffLabel    = diffName or "Scenario"
        end
    end

    return ctx
end

-- Safe addon message send — wraps in pcall to suppress Lua errors.
-- In Midnight 12.0, SendAddonMessage("PARTY") from inside an instance generates
-- a protected-call error that the game prints to chat. We avoid it entirely
-- by never sending to PARTY when inside an instance; GUILD covers guild members
-- and the HELLO/SYNC flow handles the rest.
local function SafeSend(prefix, payload, channel)
    local ok, err = pcall(C_ChatInfo.SendAddonMessage, prefix, payload, channel)
    if not ok and Core.GetSetting("debugMode") then
        print("|cff888888MS LB:|r send failed (" .. channel .. "): " .. tostring(err))
    end
end

local function BroadcastToAll(payload)
    -- Always try guild channel
    if IsInGuild() then SafeSend(LB_PREFIX, payload, "GUILD") end

    -- For group channels: in an instance group (LFD/LFR) the PARTY channel is
    -- restricted and causes "not in a party" spam. Only send PARTY when we are
    -- in a regular (non-instance) group. Raid channel is always safe.
    if IsInRaid() then
        SafeSend(LB_PREFIX, payload, "RAID")
    elseif IsInGroup() and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        -- Regular party (not LFD/instance) — PARTY channel is valid here
        SafeSend(LB_PREFIX, payload, "PARTY")
    end
    -- If IsInGroup(LE_PARTY_CATEGORY_INSTANCE): we are in an LFD instance group.
    -- PARTY channel is restricted here. Guild channel already covers guild members.
    -- Non-guild LFD members won't see the score this fight, which is acceptable.
end

-- Convenience wrappers called from other modules
function LB.GetInstanceContext()
    return GetInstanceContext()
end

function LB.GetWeekKey()
    return GetWeekKey()
end

--------------------------------------------------------------------------------
-- Integrity system
--
-- What we can and cannot prevent:
--   CANNOT: A motivated attacker reading the Lua source to understand the
--           checksum formula. WoW addon files are plain text — no secret
--           can be hidden here.
--   CAN:    Detect casual file edits, copy-paste tampering, and simple
--           score inflation by making the checksum depend on data the
--           attacker also needs to fake consistently.
--
-- Checksum formula:
--   Components: score, duration, encType
--   Changing any value without updating the checksum produces a mismatch.
--   charName is sent in the message for display purposes only — it is NOT
--   included in the checksum because scores can be re-broadcast by peers
--   (REQ handler) and the re-broadcaster's charName would differ.

local function MakeChecksum(score, duration, encType)
    local a = (score               * 7)  % 251
    local b = (math.floor(duration) * 11) % 251
    local c = (#(encType or "")    * 17) % 251
    local raw = (a + b + c) % 251
    return string.format("%03d", raw)
end

local function ValidateChecksum(score, duration, encType, checksum)
    if not checksum then return false end
    local expected = MakeChecksum(score, duration, encType)
    local ok = (expected == checksum)
    if not ok and Core.GetSetting("debugMode") then
        -- Log to Analytics debug buffer if available
        if MS.Analytics and MS.Analytics.DebugLog then
            MS.Analytics.DebugLog("[CS] FAIL score=" .. score ..
                " dur=" .. math.floor(duration) ..
                " enc=" .. (encType or "?") ..
                " got=" .. (checksum or "nil") ..
                " exp=" .. expected)
        end
    end
    return ok
end

-- Per-sender rate limiter: max 20 SCORE messages per session
local senderRateLimit = {}
local RATE_LIMIT_MAX  = 20

local function CheckRateLimit(sender)
    senderRateLimit[sender] = (senderRateLimit[sender] or 0) + 1
    return senderRateLimit[sender] <= RATE_LIMIT_MAX
end

-- Plausibility gate: (minDuration, maxScore) pairs — score above maxScore
-- requires at least minDuration seconds
local PLAUSIBILITY = {
    { minDuration = 45, maxScore = 95 },
    { minDuration = 20, maxScore = 85 },
    { minDuration = 10, maxScore = 70 },
}

local function IsPlausible(score, duration)
    for _, rule in ipairs(PLAUSIBILITY) do
        if score > rule.maxScore and duration < rule.minDuration then
            return false
        end
    end
    return true
end

--------------------------------------------------------------------------------
-- Data stores
--------------------------------------------------------------------------------
local partyData   = {}   -- [playerName] = entry  (session-only)
local friendsData = {}   -- [playerName] = entry  (session-only)
-- Guild data lives in MidnightSenseiDB.leaderboard.guild

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function GetDB()
    if not MidnightSenseiDB then return nil end
    MidnightSenseiDB.leaderboard         = MidnightSenseiDB.leaderboard         or {}
    MidnightSenseiDB.leaderboard.guild   = MidnightSenseiDB.leaderboard.guild   or {}
    return MidnightSenseiDB.leaderboard
end

local function GetPlayerName()
    local name, realm = UnitFullName("player")
    realm = realm and realm ~= "" and realm or GetRealmName()
    return name .. "-" .. realm
end

local function ShortName(fullName)
    if not fullName then return "?" end
    return fullName:match("^([^%-]+)") or fullName
end

local function IsGuildMember(fullName)
    if not IsInGuild() then return false end
    local shortName = ShortName(fullName)
    local n = GetNumGuildMembers()
    for i = 1, n do
        local gName = GetGuildRosterInfo(i)
        if gName and gName:match("^([^%-]+)") == shortName then return true end
    end
    return false
end

-- Friends tab: BNet friend enumeration (BNGetFriendNumGameAccounts) returns 0
-- in Midnight 12.0 — Blizzard restricted this API. WhisperFriends is a no-op
-- until the API is restored. friendsData still populates if a friend sends via
-- a shared guild or party channel, or if Blizzard restores the whisper path.
local function BuildFriendsList() return {} end
local function IsBNetFriend(_) return false end
local function WhisperFriends(_) end  -- no-op: cannot enumerate friend characters

-- Update or create an entry, maintaining weekly avg and all-time best.
-- isBoss=true means this was an actual boss encounter; only boss fights
-- count toward weeklyAvg (hardcoded, not optional).
local function MergeEntry(existing, name, className, specName, role,
                           grade, score, duration, encType, weekKey, isBoss)
    local e = existing or {
        name         = name,
        className    = className or "?",
        specName     = specName  or "?",
        role         = role      or "?",
        grade        = grade,
        score        = score,
        duration     = duration,
        timestamp    = time(),
        online       = true,
        weekKey      = weekKey,
        weekScores   = {},
        weeklyAvg    = 0,
        allTimeBest  = score,
        dungeonBest  = 0,
        raidBest     = 0,
        delveBest    = 0,
        normalBest   = 0,
        dungeonAvg   = 0,
        raidAvg      = 0,
        dungeonCount = 0,
        raidCount    = 0,
    }

    -- Ensure weekScores exists — seed/HELLO entries are created without it
    if not e.weekScores then e.weekScores = {} end

    -- If new WoW week, reset weekly data
    if e.weekKey ~= weekKey then
        e.weekKey    = weekKey
        e.weekScores = {}
        e.weeklyAvg  = 0
    end

    -- Only boss fights count toward weekly avg
    if isBoss then
        table.insert(e.weekScores, score)
        if #e.weekScores > 50 then table.remove(e.weekScores, 1) end
        local sum = 0
        for _, s in ipairs(e.weekScores) do sum = sum + s end
        e.weeklyAvg = math.floor(sum / #e.weekScores)
    end

    -- All-time best (all fights)
    if score > (e.allTimeBest or 0) then e.allTimeBest = score end

    -- Category bests and averages
    if encType == "dungeon" then
        if score > (e.dungeonBest or 0) then e.dungeonBest = score end
        e.dungeonCount = (e.dungeonCount or 0) + 1
        local prevSum  = (e.dungeonAvg or 0) * ((e.dungeonCount or 1) - 1)
        e.dungeonAvg   = math.floor((prevSum + score) / e.dungeonCount)
    elseif encType == "raid" then
        if score > (e.raidBest or 0) then e.raidBest = score end
        e.raidCount = (e.raidCount or 0) + 1
        local prevSum = (e.raidAvg or 0) * ((e.raidCount or 1) - 1)
        e.raidAvg     = math.floor((prevSum + score) / e.raidCount)
    elseif encType == "delve" then
        if score > (e.delveBest or 0) then e.delveBest = score end
    else
        if score > (e.normalBest or 0) then e.normalBest = score end
    end

    -- Update displayed fields
    e.name      = name
    e.className = className or e.className
    e.specName  = specName  or e.specName
    e.role      = role      or e.role
    e.grade     = grade
    e.score     = score
    e.duration  = duration
    e.timestamp = time()
    e.online    = true

    return e
end

--------------------------------------------------------------------------------
-- Broadcast own score
--------------------------------------------------------------------------------

local function BroadcastScore(encounter)
    if not encounter or not encounter.finalScore then return end
    local charName  = UnitName("player") or "?"
    local encType   = encounter.encType  or "normal"
    local diffLabel = encounter.diffLabel or ""
    local ks        = encounter.keystoneLevel and tostring(encounter.keystoneLevel) or "0"
    local cs = MakeChecksum(encounter.finalScore,
                            math.floor(encounter.duration or 0),
                            encType)

    local payload = table.concat({
        "SCORE",
        Core.VERSION,
        encounter.className  or "?",
        encounter.specName   or "?",
        encounter.role       or "?",
        encounter.finalGrade or "?",
        tostring(encounter.finalScore or 0),
        tostring(math.floor(encounter.duration or 0)),
        encounter.isBoss and "1" or "0",
        (encounter.bossName or ""):gsub("|", "_"),
        encType,
        cs,
        diffLabel:gsub("|", "_"),
        ks,
        charName:gsub("|", "_"),
    }, "|")

    BroadcastToAll(payload)
    -- Also whisper BNet friends directly — they may not share guild or group
    WhisperFriends(payload)
end

Core.On(Core.EVENTS.GRADE_CALCULATED, BroadcastScore)

-- Auto-refresh leaderboard after each fight if it's open
Core.On(Core.EVENTS.GRADE_CALCULATED, function()
    C_Timer.After(0.5, function()
        LB.RefreshUI()
    end)
end)

--------------------------------------------------------------------------------
-- HELLO broadcast
--------------------------------------------------------------------------------
local function BroadcastHello()
    if not Core.ActiveSpec then return end
    local payload = table.concat({ "HELLO", Core.VERSION,
        Core.ActiveSpec.className or "?",
        Core.ActiveSpec.name      or "?" }, "|")
    BroadcastToAll(payload)
    WhisperFriends(payload)
end

-- Seed partyData with current group members on login/reload and when leaderboard opens.
-- partyData is session-only so it empties on reload; we refill from group unit tokens.
local function SeedPartyFromGroup()
    local n = GetNumGroupMembers()
    if n == 0 then return end
    local myShort = UnitName("player") or ""
    for i = 1, n do
        local unit = (IsInRaid() and "raid" or "party") .. i
        local name = UnitName(unit)
        -- Skip self — GetPartyData injects the self-entry separately
        if name and name ~= myShort then
            -- Key by short name to match how SCORE/HELLO sender arrives
            local key = name
            if not partyData[key] then
                partyData[key] = {
                    name        = name,
                    className   = UnitClass(unit) or "?",
                    specName    = "",
                    grade       = "--",
                    score       = 0,
                    online      = true,
                    timestamp   = 0,
                    weekKey     = GetWeekKey(),
                    weeklyAvg   = 0, allTimeBest = 0,
                    dungeonBest = 0, raidBest = 0, delveBest = 0, normalBest = 0,
                }
            end
        end
    end
end

Core.On(Core.EVENTS.SESSION_READY, function() C_Timer.After(4.0, BroadcastHello) end)
Core.On(Core.EVENTS.SESSION_READY, function()
    C_Timer.After(2.0, function()
        SeedPartyFromGroup()
        LB.RefreshUI()
    end)
end)
Core.On(Core.EVENTS.SPEC_CHANGED,  function() C_Timer.After(1.0, BroadcastHello) end)

--------------------------------------------------------------------------------
-- Incoming message parser
--------------------------------------------------------------------------------
local function OnAddonMessage(prefix, payload, channel, sender)
    if prefix ~= LB_PREFIX then return end
    local shortSelf = UnitName("player")
    if ShortName(sender) == shortSelf then return end

    local parts = {}
    for p in payload:gmatch("[^|]+") do table.insert(parts, p) end
    if #parts < 2 then return end

    local msgType = parts[1]

    if msgType == "SCORE" then
        -- Accept 12+ parts for backward compatibility with older clients.
        -- New format is 15 parts; older format was 12.
        if #parts < 12 then return end

        local className = parts[3]
        local specName  = parts[4]
        local role      = parts[5]
        local grade     = parts[6]
        local score     = tonumber(parts[7]) or 0
        local duration  = tonumber(parts[8]) or 0
        local isBoss    = (parts[9] == "1")
        local bossName  = parts[10] or ""
        local encType   = parts[11] or "normal"
        local checksum  = parts[12]
        local diffLabel = parts[13] or ""
        local ks        = tonumber(parts[14]) or 0
        local charName  = parts[15] or ShortName(sender)

        -- 1. Score range
        if score < 0 or score > 100 then return end

        -- 2. Checksum validation — skip for WHISPER channel.
        if channel ~= "WHISPER" then
            if not ValidateChecksum(score, duration, encType, checksum) then
                -- Always log to persistent buffer regardless of debugMode
                -- so failures are diagnosable after the fact via /ms debuglog
                if MidnightSenseiDB then
                    MidnightSenseiDB.debugLog = MidnightSenseiDB.debugLog or {}
                    local buf = MidnightSenseiDB.debugLog
                    table.insert(buf, date("%H:%M:%S") ..
                        " [CS] FAIL from=" .. ShortName(sender) ..
                        " score=" .. score ..
                        " dur=" .. math.floor(duration) ..
                        " enc=" .. (encType or "?") ..
                        " cs=" .. (checksum or "nil"))
                    while #buf > 50 do table.remove(buf, 1) end
                end
                if Core.GetSetting("debugMode") then
                    print("|cffFF4444MS:|r checksum fail from " .. ShortName(sender) ..
                          " — check /ms debuglog")
                end
                return
            end
        end

        -- 3. Plausibility (score too high for fight length)
        if not IsPlausible(score, duration) then
            if Core.GetSetting("debugMode") then
                print("|cffFF4444Midnight Sensei:|r Rejected score from " ..
                      ShortName(sender) .. " (implausible: " ..
                      score .. " in " .. duration .. "s)")
            end
            return
        end

        -- 4. Rate limit per sender per session
        if not CheckRateLimit(sender) then return end

        local weekKey = GetWeekKey()

        -- Route to party: check if sender is currently in our group,
        -- regardless of which channel the message arrived on.
        -- IsInGroup() fails for LFD groups, so check unit names directly.
        local addedToParty = false
        local myShort = UnitName("player") or ""
        if ShortName(sender) ~= myShort then
            for i = 1, GetNumGroupMembers() do
                local unit = (IsInRaid() and "raid" or "party") .. i
                local unitName = UnitName(unit)
                if unitName and ShortName(sender) == unitName then
                    local key = ShortName(sender)
                    partyData[key] = MergeEntry(partyData[key], sender,
                        className, specName, role, grade, score, duration,
                        encType, weekKey, isBoss)
                    partyData[key].diffLabel     = diffLabel
                    partyData[key].keystoneLevel = ks > 0 and ks or nil
                    addedToParty = true
                    break
                end
            end
        end

        -- Route to guild if applicable
        if IsInGuild() and IsGuildMember(sender) then
            local db = GetDB()
            if db then
                db.guild[sender] = MergeEntry(db.guild[sender], sender,
                    className, specName, role, grade, score, duration,
                    encType, weekKey, isBoss)
                db.guild[sender].diffLabel     = diffLabel
                db.guild[sender].keystoneLevel = ks > 0 and ks or nil
            end
        end

        -- Route to friends: check IsBNetFriend, or if message came via WHISPER channel
        -- (friends who aren't in same guild/group send via whisper)
        if IsBNetFriend(sender) or channel == "WHISPER" then
            friendsData[sender] = MergeEntry(friendsData[sender], sender,
                className, specName, role, grade, score, duration,
                encType, weekKey, isBoss)
            friendsData[sender].diffLabel     = diffLabel
            friendsData[sender].keystoneLevel = ks > 0 and ks or nil
        end

        LB.RefreshUI()

    elseif msgType == "REQ" then
        -- A peer is asking everyone to resend their last score (triggered by Refresh).
        -- Re-emit GRADE_CALCULATED with our last recorded encounter so it gets broadcast.
        C_Timer.After(0.5 + math.random() * 1.5, function()
            local lastEnc = MS.Analytics and MS.Analytics.GetLastEncounter
                            and MS.Analytics.GetLastEncounter()
            if lastEnc and lastEnc.finalScore then
                Core.Emit(Core.EVENTS.GRADE_CALCULATED, lastEnc)
            end
        end)

    elseif msgType == "HELLO" then
        -- Guild: create or update entry — always refresh class/spec from HELLO
        -- so stale data from alt characters or spec changes is corrected on login.
        if IsInGuild() and IsGuildMember(sender) then
            local db = GetDB()
            if db then
                if not db.guild[sender] then
                    db.guild[sender] = {
                        name        = sender,
                        className   = parts[3] or "?",
                        specName    = parts[4] or "?",
                        grade       = "--",
                        score       = 0,
                        online      = true,
                        timestamp   = time(),
                        weekKey     = GetWeekKey(),
                        weekScores  = {},
                        weeklyAvg   = 0,
                        allTimeBest = 0,
                        dungeonBest = 0, raidBest  = 0,
                        delveBest   = 0, normalBest = 0,
                        dungeonAvg  = 0, raidAvg    = 0,
                        dungeonCount = 0, raidCount = 0,
                    }
                else
                    -- Always update identity fields — player may have switched
                    -- characters or specs since the last persisted entry.
                    db.guild[sender].online    = true
                    if parts[3] and parts[3] ~= "?" then
                        db.guild[sender].className = parts[3]
                    end
                    if parts[4] and parts[4] ~= "?" then
                        db.guild[sender].specName  = parts[4]
                    end
                end

                -- GRM-style sync back
                local entry = db.guild[sender]
                if entry and (entry.allTimeBest or 0) > 0 then
                    C_Timer.After(2.0 + math.random() * 3.0, function()
                        local syncPayload = table.concat({
                            "SYNC", ShortName(sender),
                            tostring(entry.allTimeBest  or 0),
                            tostring(entry.weeklyAvg    or 0),
                            tostring(entry.dungeonBest  or 0),
                            tostring(entry.raidBest     or 0),
                            tostring(entry.delveBest    or 0),
                            entry.weekKey or GetWeekKey(),
                        }, "|")
                        if IsInGuild() then SafeSend(LB_PREFIX, syncPayload, "GUILD") end
                    end)
                end
            end
        end

        -- Party: add placeholder if sender is in our group (skip self)
        local myShort = UnitName("player") or ""
        if ShortName(sender) ~= myShort then
            for i = 1, GetNumGroupMembers() do
                local unit = (IsInRaid() and "raid" or "party") .. i
                local unitName = UnitName(unit)
                if unitName and ShortName(sender) == unitName then
                    local key = ShortName(sender)
                    if not partyData[key] then
                        partyData[key] = {
                            name      = ShortName(sender),
                            className = parts[3] or "?",
                            specName  = parts[4] or "?",
                            grade     = "--",
                            score     = 0,
                            online    = true,
                            timestamp = 0,
                            weekKey   = GetWeekKey(),
                            weeklyAvg = 0, allTimeBest = 0,
                            dungeonBest = 0, raidBest = 0, delveBest = 0, normalBest = 0,
                        }
                    else
                        partyData[key].online    = true
                        if parts[3] and parts[3] ~= "?" then partyData[key].className = parts[3] end
                        if parts[4] and parts[4] ~= "?" then partyData[key].specName  = parts[4] end
                    end
                    break
                end
            end
        end

        -- Friends: add a no-score placeholder if sender is a BNet friend
        -- or if this HELLO arrived via whisper (direct BNet friend path)
        if IsBNetFriend(sender) or channel == "WHISPER" then
            if not friendsData[sender] then
                friendsData[sender] = {
                    name      = sender,
                    className = parts[3] or "?",
                    specName  = parts[4] or "?",
                    grade     = "--",
                    score     = 0,
                    online    = true,
                    timestamp = 0,
                    weekKey   = GetWeekKey(),
                    weeklyAvg = 0, allTimeBest = 0,
                    dungeonBest = 0, raidBest = 0, delveBest = 0, normalBest = 0,
                }
            else
                friendsData[sender].online = true
            end

            -- If this arrived via whisper, whisper back our HELLO so they also
            -- get our entry (mutual handshake — otherwise only one side registers).
            if channel == "WHISPER" and Core.ActiveSpec then
                local replyPayload = table.concat({
                    "HELLO", Core.VERSION,
                    Core.ActiveSpec.className or "?",
                    Core.ActiveSpec.name      or "?",
                }, "|")
                -- Whisper back to the exact sender (Name-Realm format is fine for WHISPER)
                pcall(C_ChatInfo.SendAddonMessage, LB_PREFIX, replyPayload, "WHISPER", sender)

                -- Also resend our last score directly to them so their Friends tab populates
                C_Timer.After(0.5, function()
                    local lastEnc = MS.Analytics and MS.Analytics.GetLastEncounter
                                    and MS.Analytics.GetLastEncounter()
                    if lastEnc and lastEnc.finalScore then
                        Core.Emit(Core.EVENTS.GRADE_CALCULATED, lastEnc)
                    end
                end)
            end
        end

        LB.RefreshUI()

    elseif msgType == "SYNC" then
        -- A peer is sending us back our own historical data (GRM-style recovery).
        -- Format: SYNC|targetName|allTimeBest|weeklyAvg|dungeonBest|raidBest|delveBest|weekKey
        if #parts < 8 then return end
        local targetName  = parts[2]
        local myShortName = UnitName("player") or ""

        -- Only accept if this is addressed to us
        if targetName ~= myShortName then return end

        local allTimeBest = tonumber(parts[3]) or 0
        local weeklyAvg   = tonumber(parts[4]) or 0
        local dungeonBest = tonumber(parts[5]) or 0
        local raidBest    = tonumber(parts[6]) or 0
        local delveBest   = tonumber(parts[7]) or 0
        local weekKey     = parts[8] or GetWeekKey()

        -- Validate all values are in range
        if allTimeBest > 100 or dungeonBest > 100 or raidBest > 100 or delveBest > 100 then
            return
        end

        -- Only restore values that are *higher* than what we currently have
        -- (never let a peer downgrade our scores)
        local db = MidnightSenseiDB
        if not db then return end
        db.leaderboard = db.leaderboard or {}
        local lb = db.leaderboard
        lb.recoveredBests = lb.recoveredBests or {}
        local rb = lb.recoveredBests
        local changed = false

        if allTimeBest > (rb.allTimeBest or 0) then
            rb.allTimeBest = allTimeBest ; changed = true end
        if dungeonBest > (rb.dungeonBest or 0) then
            rb.dungeonBest = dungeonBest ; changed = true end
        if raidBest    > (rb.raidBest    or 0) then
            rb.raidBest    = raidBest    ; changed = true end
        if delveBest   > (rb.delveBest   or 0) then
            rb.delveBest   = delveBest   ; changed = true end

        if changed and Core.GetSetting("debugMode") then
            print("|cff00D1FFMidnight Sensei:|r Recovered leaderboard data from " ..
                  ShortName(sender))
        end
        LB.RefreshUI()
    end
end

--------------------------------------------------------------------------------
-- Guild online sync
--------------------------------------------------------------------------------
local function SyncGuildOnlineStatus()
    local db = GetDB()
    if not db then return end
    for name, entry in pairs(db.guild) do entry.online = false end
    local n = GetNumGuildMembers()
    for i = 1, n do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if name and online and db.guild[name] then
            db.guild[name].online = true
        end
    end
    LB.RefreshUI()
end

-- Weekly avg is always boss-only. Not optional.
-- For encounters without weekKey (older history), falls back to timestamp comparison.
local function ComputeWeeklyAvg(history, weekKey)
    if not history then return 0 end

    -- Derive the UTC epoch for the start of this WoW week so we can bucket
    -- old encounters that predate the weekKey field.
    -- WoW's time() returns UTC epoch. We use GetWeekKey's own logic in reverse:
    -- The weekKey is YYYYMMDD of the Tuesday at 14:00 UTC that started the week.
    -- We find it by scanning backwards from now until we hit that Tuesday.
    -- Simple approach: current time() minus the offset we already computed in GetWeekKey.
    local weekStart = 0
    local weekEnd   = 0
    if #weekKey == 8 then
        -- Walk back from now to find the epoch that matches this weekKey.
        -- Each WoW week is exactly 7 days. GetWeekKey returns the current week's key,
        -- so if weekKey == GetWeekKey() we can compute weekStart directly from now.
        local utcNow   = time()
        local shifted  = utcNow - (14 * 3600)
        local t        = date("!*t", shifted)
        local wday     = t.wday
        local daysSinceTue = (wday - 3 + 7) % 7
        -- weekStart = epoch of this week's Tuesday 14:00 UTC
        local thisWeekStart = utcNow - daysSinceTue * 86400
                            - (t.hour * 3600 + t.min * 60 + t.sec)
                            + (14 * 3600)  -- add 14h to get 14:00 UTC

        -- Find how many weeks ago this weekKey was
        local curKey = GetWeekKey()
        if weekKey == curKey then
            weekStart = thisWeekStart
        elseif weekKey < curKey then
            -- Walk back in 7-day steps until we find the right key
            local probe = thisWeekStart
            for _ = 1, 52 do  -- max 1 year lookback
                probe = probe - 7 * 86400
                local probeShifted = probe - (14 * 3600)
                local pTue = date("!*t", probeShifted)
                local pKey = string.format("%04d%02d%02d", pTue.year, pTue.month, pTue.mday)
                if pKey == weekKey then
                    weekStart = probe
                    break
                end
            end
        end
        weekEnd = weekStart + 7 * 86400
    end

    local sum, count = 0, 0
    for _, enc in ipairs(history) do
        if enc.isBoss then
            local inWeek = false
            if enc.weekKey and enc.weekKey ~= "" then
                inWeek = (enc.weekKey == weekKey)
            elseif enc.timestamp and weekStart > 0 then
                inWeek = (enc.timestamp >= weekStart and enc.timestamp < weekEnd)
            end
            if inWeek then
                sum   = sum   + (enc.finalScore or 0)
                count = count + 1
            end
        end
    end
    return count > 0 and math.floor(sum / count) or 0
end

--------------------------------------------------------------------------------
-- Public data getters
--------------------------------------------------------------------------------
function LB.GetPartyData()
    local result = {}
    local myName = GetPlayerName()
    local spec   = Core.ActiveSpec
    if spec then
        local history = MidnightSenseiDB and MidnightSenseiDB.encounters
        local lastEnc = history and history[#history]
        local wk      = GetWeekKey()
        local wAvg    = ComputeWeeklyAvg(history, wk)

        -- Compute all-time and category bests from full history
        local allBest, dungBest, raidBest, delvBest = 0, 0, 0, 0
        if history then
            for _, enc in ipairs(history) do
                local s = enc.finalScore or 0
                allBest = math.max(allBest, s)
                if     enc.encType == "dungeon" then dungBest = math.max(dungBest, s)
                elseif enc.encType == "raid"    then raidBest = math.max(raidBest, s)
                elseif enc.encType == "delve"   then delvBest = math.max(delvBest, s)
                end
            end
        end

        result[myName] = {
            name        = UnitName("player"),
            className   = spec.className or "?",
            specName    = spec.name      or "?",
            role        = spec.role      or "?",
            grade       = lastEnc and (lastEnc.finalGrade or lastEnc.grade) or "--",
            score       = lastEnc and lastEnc.finalScore  or 0,
            timestamp   = lastEnc and lastEnc.timestamp   or 0,
            isSelf      = true,
            online      = true,
            weekKey     = wk,
            weeklyAvg   = wAvg,
            allTimeBest = allBest,
            dungeonBest = dungBest,
            raidBest    = raidBest,
            delveBest   = delvBest,
            normalBest  = 0,
        }
    end
    for name, entry in pairs(partyData) do result[name] = entry end
    return result
end

function LB.GetGuildData()
    local db = GetDB()
    local guildData = db and db.guild or {}

    -- Always inject self so the player appears in their own guild tab
    if IsInGuild() then
        local myName = GetPlayerName()
        local spec   = Core.ActiveSpec
        if spec then
            local history = MidnightSenseiDB and MidnightSenseiDB.encounters
            local lastEnc = history and history[#history]
            local wk      = GetWeekKey()

            -- Boss-only weekly avg (always hardcoded)
            local wAvg = ComputeWeeklyAvg(history, wk)

            -- Category bests from full history
            local allBest, dungBest, raidBest, delvBest, normBest = 0, 0, 0, 0, 0
            if history then
                for _, enc in ipairs(history) do
                    local s = enc.finalScore or 0
                    allBest = math.max(allBest, s)
                    if     enc.encType == "dungeon" then dungBest = math.max(dungBest, s)
                    elseif enc.encType == "raid"    then raidBest = math.max(raidBest, s)
                    elseif enc.encType == "delve" and enc.isBoss then
                        -- Only boss delve encounters count as meaningful delve completions
                        delvBest = math.max(delvBest, s)
                    elseif enc.encType ~= "delve" then
                        normBest = math.max(normBest, s)
                    end
                end
            end

            local existing = guildData[myName]
            local selfEntry = {
                name          = UnitName("player"),
                className     = spec.className or "?",
                specName      = spec.name      or "?",
                role          = spec.role      or "?",
                grade         = lastEnc and (lastEnc.finalGrade or lastEnc.grade) or "--",
                score         = lastEnc and lastEnc.finalScore  or 0,
                timestamp     = lastEnc and lastEnc.timestamp   or 0,
                isSelf        = true,
                online        = true,
                weekKey       = wk,
                weeklyAvg     = wAvg,
                allTimeBest   = allBest,
                dungeonBest   = dungBest,
                raidBest      = raidBest,
                delveBest     = delvBest,
                normalBest    = normBest,
                diffLabel     = lastEnc and lastEnc.diffLabel    or "",
                keystoneLevel = lastEnc and lastEnc.keystoneLevel or nil,
            }

            -- Merge with persisted data and peer-recovered bests
            if existing then
                selfEntry.allTimeBest = math.max(selfEntry.allTimeBest, existing.allTimeBest or 0)
                selfEntry.dungeonBest = math.max(selfEntry.dungeonBest, existing.dungeonBest or 0)
                selfEntry.raidBest    = math.max(selfEntry.raidBest,    existing.raidBest    or 0)
                selfEntry.delveBest   = math.max(selfEntry.delveBest,   existing.delveBest   or 0)
            end
            local rb = MidnightSenseiDB
                       and MidnightSenseiDB.leaderboard
                       and MidnightSenseiDB.leaderboard.recoveredBests
            if rb then
                selfEntry.allTimeBest = math.max(selfEntry.allTimeBest, rb.allTimeBest or 0)
                selfEntry.dungeonBest = math.max(selfEntry.dungeonBest, rb.dungeonBest or 0)
                selfEntry.raidBest    = math.max(selfEntry.raidBest,    rb.raidBest    or 0)
                selfEntry.delveBest   = math.max(selfEntry.delveBest,   rb.delveBest   or 0)
            end

            local result = {}
            for k, v in pairs(guildData) do result[k] = v end
            result[myName] = selfEntry
            return result
        end
    end

    return guildData
end

function LB.GetFriendsData()
    return friendsData
end

-- Delve tab: shows the player's own delve encounter history sorted by score.
-- Respects contentFilter: "weekly" shows only this week's runs, "alltime" shows all.
function LB.GetDelveData()
    local result  = {}
    local history = MidnightSenseiDB and MidnightSenseiDB.encounters
    local wk      = GetWeekKey()

    if history then
        local myName = GetPlayerName()
        for i, enc in ipairs(history) do
            if enc.encType == "delve" and enc.isBoss then
                -- Weekly filter: only include runs from the current WoW week
                local inWeek = (enc.weekKey and enc.weekKey == wk)
                if contentFilter == "weekly" and not inWeek then
                    -- skip this run in weekly view
                else
                    local key = myName .. "_delve_" .. i
                    result[key] = {
                        name         = UnitName("player"),
                        className    = enc.className or "?",
                        specName     = enc.specName  or "?",
                        role         = enc.role      or "?",
                        grade        = enc.finalGrade or enc.grade or "?",
                        score        = enc.finalScore or 0,
                        weeklyAvg    = enc.finalScore or 0,
                        allTimeBest  = enc.finalScore or 0,
                        delveBest    = enc.finalScore or 0,
                        dungeonBest  = 0, raidBest = 0, normalBest = 0,
                        diffLabel    = enc.diffLabel    or "",
                        instanceName = enc.instanceName or "",
                        bossName     = enc.bossName     or "",
                        keystoneLevel = enc.keystoneLevel,
                        timestamp    = enc.timestamp or 0,
                        weekKey      = enc.weekKey   or "",
                        isSelf       = true,
                        online       = true,
                        isDelveRun   = true,
                    }
                end
            end
        end
    end

    -- Guild peers: always show their best delve regardless of filter
    local guildData = LB.GetGuildData()
    for name, entry in pairs(guildData) do
        if (entry.delveBest or 0) > 0 and not entry.isSelf then
            result[name .. "_best"] = {
                name        = entry.name,
                className   = entry.className,
                specName    = entry.specName,
                role        = entry.role,
                grade       = entry.grade,
                score       = entry.delveBest,
                weeklyAvg   = entry.delveBest,
                allTimeBest = entry.allTimeBest or 0,
                delveBest   = entry.delveBest,
                dungeonBest = 0, raidBest = 0, normalBest = 0,
                diffLabel   = "Best",
                timestamp   = entry.timestamp or 0,
                isSelf      = false,
                online      = entry.online,
            }
        end
    end

    return result
end

function LB.ClearGuildData()
    local db = GetDB()
    if db then db.guild = {} end
    LB.RefreshUI()
end

--------------------------------------------------------------------------------
-- Class colours
--------------------------------------------------------------------------------
local CLASS_COLORS = {
    WARRIOR={0.78,0.61,0.43}, PALADIN={0.96,0.55,0.73}, HUNTER={0.67,0.83,0.45},
    ROGUE={1.00,0.96,0.41},   PRIEST={1.00,1.00,1.00},  DEATHKNIGHT={0.77,0.12,0.23},
    SHAMAN={0.00,0.44,0.87},  MAGE={0.41,0.80,0.94},    WARLOCK={0.58,0.51,0.79},
    MONK={0.00,1.00,0.59},    DRUID={1.00,0.49,0.04},   DEMONHUNTER={0.64,0.19,0.79},
    EVOKER={0.20,0.58,0.50},
}
local function GetClassColor(cn)
    if not cn then return {0.9,0.9,0.9} end
    return CLASS_COLORS[cn:upper():gsub(" ","")] or {0.9,0.9,0.9}
end

--------------------------------------------------------------------------------
-- UI colours
--------------------------------------------------------------------------------
local COLOR = {
    FRAME_BG    = {0.04,0.04,0.06,0.90}, BORDER      = {0.30,0.30,0.40,0.60},
    BORDER_GOLD = {1.00,0.65,0.00,0.90}, TITLE_BG    = {0.12,0.12,0.18,0.95},
    TITLE_TEXT  = {1.00,0.65,0.00,1.00}, ACCENT      = {0.00,0.82,1.00,1.00},
    TEXT_MAIN   = {0.92,0.90,0.88,1.00}, TEXT_DIM    = {0.55,0.53,0.50,1.00},
    ROW_EVEN    = {0.08,0.08,0.12,0.50}, ROW_ODD     = {0.04,0.04,0.06,0.30},
    ROW_SELF    = {0.10,0.20,0.10,0.60}, ONLINE      = {0.20,0.85,0.20,1.00},
    OFFLINE     = {0.45,0.45,0.45,1.00}, TAB_ACTIVE  = {0.20,0.18,0.24,1.00},
    TAB_IDLE    = {0.10,0.10,0.14,1.00},
}

--------------------------------------------------------------------------------
-- UI helpers
--------------------------------------------------------------------------------
local lbFrame       = nil
local activeTab     = "party"   -- social tab: party | guild | friends
local contentFilter = "weekly"  -- content row: weekly | alltime | delve | dungeon | raid
local rowFrames     = {}

local function BD(f, bg, border)
    if not f.SetBackdrop then Mixin(f, BackdropTemplateMixin) end
    f:SetBackdrop({ bgFile="Interface/Tooltips/UI-Tooltip-Background",
                    edgeFile="Interface/Tooltips/UI-Tooltip-Border",
                    tile=true,tileSize=16,edgeSize=12,
                    insets={left=2,right=2,top=2,bottom=2} })
    local b=bg or COLOR.FRAME_BG; local e=border or COLOR.BORDER
    f:SetBackdropColor(b[1],b[2],b[3],b[4] or 1)
    f:SetBackdropBorderColor(e[1],e[2],e[3],e[4] or 1)
end

local function TF(parent, size, justify)
    local fs = parent:CreateFontString(nil,"OVERLAY")
    fs:SetFont("Fonts/FRIZQT__.TTF", size or 11, "")
    fs:SetJustifyH(justify or "LEFT")
    fs:SetTextColor(COLOR.TEXT_MAIN[1],COLOR.TEXT_MAIN[2],COLOR.TEXT_MAIN[3],1)
    return fs
end

local function GHex(score)
    if not score or score==0 then return "aaaaaa" end
    if score>=90 then return "33ee33" elseif score>=80 then return "88cc44"
    elseif score>=70 then return "cccc33" elseif score>=60 then return "ee8833"
    else return "ee3333" end
end

local function TAgo(ts)
    if not ts or ts==0 then return "" end
    local d=time()-ts
    if d<60 then return "just now" elseif d<3600 then return math.floor(d/60).."m ago"
    elseif d<86400 then return math.floor(d/3600).."h ago"
    else return math.floor(d/86400).."d ago" end
end

--------------------------------------------------------------------------------
-- Row builder — 5 columns: rank | name | spec | category stats | week avg
--------------------------------------------------------------------------------
local function GetRow(parent, idx)
    if rowFrames[idx] then return rowFrames[idx] end
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(22)
    row:SetPoint("LEFT",  parent,"LEFT",  0,0)
    row:SetPoint("RIGHT", parent,"RIGHT", 0,0)

    row.rankText  = TF(row,10,"CENTER");  row.rankText:SetPoint("LEFT",row,"LEFT",4,0);   row.rankText:SetWidth(20)
    row.onlineDot = row:CreateTexture(nil,"OVERLAY"); row.onlineDot:SetSize(6,6); row.onlineDot:SetPoint("LEFT",row,"LEFT",26,0)
    row.nameText  = TF(row,11,"LEFT");    row.nameText:SetPoint("LEFT",row,"LEFT",36,0);  row.nameText:SetWidth(108)
    row.specText  = TF(row,9,"LEFT");     row.specText:SetPoint("LEFT",row,"LEFT",148,0); row.specText:SetWidth(70)
    row.specText:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
    row.catText   = TF(row,9,"LEFT");     row.catText:SetPoint("LEFT",row,"LEFT",222,0);  row.catText:SetWidth(230)
    row.catText:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
    row.weekText  = TF(row,11,"RIGHT");   row.weekText:SetPoint("RIGHT",row,"RIGHT",-2,0); row.weekText:SetWidth(62)

    rowFrames[idx] = row
    return row
end

local function PopulateRows(scrollChild, entries)
    for _, r in ipairs(rowFrames) do r:Hide() end
    local yOff = 0
    for i, entry in ipairs(entries) do
        local row = GetRow(scrollChild, i)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT",  scrollChild,"TOPLEFT",  0,-yOff)
        row:SetPoint("TOPRIGHT", scrollChild,"TOPRIGHT", 0,-yOff)

        local bgc = entry.isSelf and COLOR.ROW_SELF
            or (i%2==0 and COLOR.ROW_EVEN or COLOR.ROW_ODD)
        row:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",tile=true,tileSize=16})
        row:SetBackdropColor(bgc[1],bgc[2],bgc[3],bgc[4] or 0.5)

        row.rankText:SetText(i)
        row.rankText:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)

        local cc  = GetClassColor(entry.className)
        local nm  = entry.isSelf and (ShortName(entry.name).." (you)") or ShortName(entry.name)
        row.nameText:SetText(nm); row.nameText:SetTextColor(cc[1],cc[2],cc[3],1)
        row.specText:SetText((entry.specName or "?").." "..(entry.className or ""))

        -- Category stats column — format: Diff/Tier · Instance · Boss
        local catStr = ""

        -- Helper: combine up to three parts with " - " separator, skipping blanks
        local function JoinLabel(a, b, c)
            local parts = {}
            if a and a ~= "" and a ~= "World" then table.insert(parts, a) end
            if b and b ~= "" then table.insert(parts, b) end
            if c and c ~= "" then table.insert(parts, c) end
            return #parts > 0 and table.concat(parts, " - ") or "--"
        end

        local diff  = (entry.diffLabel and entry.diffLabel ~= "" and entry.diffLabel ~= "World") and entry.diffLabel or nil
        local inst  = (entry.instanceName and entry.instanceName ~= "") and entry.instanceName or nil
        local boss  = (entry.bossName and entry.bossName ~= "") and entry.bossName or nil

        if contentFilter == "delve" then
            -- "Tier 8 - The Sinkhole - Zo'shurion"
            catStr = JoinLabel(diff, inst, boss)
            if entry.isDelveRun and entry.timestamp and entry.timestamp > 0 then
                catStr = catStr .. " |cff888888" .. TAgo(entry.timestamp) .. "|r"
            end
        elseif contentFilter == "dungeon" then
            -- "M+12 - Halls of Infusion - Khajin"  or  "Heroic - The Stonevault - Void Seamstress"
            catStr = JoinLabel(diff, inst, boss)
        elseif contentFilter == "raid" then
            -- "Mythic - Nerub-ar Palace - Queen Ansurek"
            catStr = JoinLabel(diff, inst, boss)
        elseif contentFilter == "alltime" or contentFilter == "weekly" then
            -- Show best available context
            catStr = JoinLabel(diff, inst, boss)
        else
            catStr = "--"
        end
        row.catText:SetText(catStr)

        -- Right column (grade/score value)
        local rightStr
        if contentFilter == "delve" then
            local v = entry.score or 0
            rightStr = v > 0 and ("|cff"..GHex(v)..v.."|r") or "|cff888888--|r"
        elseif contentFilter == "dungeon" then
            local v = entry.dungeonBest or 0
            rightStr = v > 0 and ("|cff"..GHex(v)..v.."|r") or "|cff888888--|r"
        elseif contentFilter == "raid" then
            local v = entry.raidBest or 0
            rightStr = v > 0 and ("|cff"..GHex(v)..v.."|r") or "|cff888888--|r"
        elseif contentFilter == "alltime" then
            local v = entry.allTimeBest or entry.score or 0
            rightStr = v > 0 and ("|cff"..GHex(v)..v.."|r") or "|cff888888--|r"
        else  -- weekly
            local wAvg = entry.weeklyAvg or 0
            local wk   = GetWeekKey()
            if wAvg > 0 then
                rightStr = "|cff"..GHex(wAvg)..wAvg.."|r"
                if entry.weekKey and entry.weekKey ~= wk then
                    rightStr = rightStr .. " |cff888888(prev)|r"
                end
            else
                rightStr = "|cff888888--this week--|r"
            end
        end
        row.weekText:SetText(rightStr)

        -- Online dot
        local isOnline = (entry.online ~= false)
        if activeTab == "party" or contentFilter == "delve" then isOnline = true end
        local dc = isOnline and COLOR.ONLINE or COLOR.OFFLINE
        row.onlineDot:SetColorTexture(dc[1],dc[2],dc[3],1)
        row.onlineDot:Show()
        row:Show()
        yOff = yOff + 22
    end
    scrollChild:SetHeight(math.max(yOff+8, 100))
end

--------------------------------------------------------------------------------
-- Sorting
--------------------------------------------------------------------------------
local function SortedEntries(dataTable)
    local list = {}
    for _, entry in pairs(dataTable) do table.insert(list, entry) end
    -- Sort key depends on contentFilter
    local key
    if     contentFilter == "alltime"  then key = "allTimeBest"
    elseif contentFilter == "dungeon"  then key = "dungeonBest"
    elseif contentFilter == "raid"     then key = "raidBest"
    elseif contentFilter == "delve"    then key = "score"       -- delve runs sort by score
    else                                    key = "weeklyAvg"   -- default: weekly
    end
    table.sort(list, function(a, b)
        local av = a[key] or a.score or 0
        local bv = b[key] or b.score or 0
        if av ~= bv then return av > bv end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

local function GetSocialData()
    if     activeTab == "guild"   then return LB.GetGuildData()
    elseif activeTab == "friends" then return LB.GetFriendsData()
    else                               return LB.GetPartyData() end
end

local function RefreshContent()
    if not lbFrame or not lbFrame.scrollChild then return end

    -- Delve is a separate data source; other filters show social data
    local rawData
    if contentFilter == "delve" then
        rawData = LB.GetDelveData()
    else
        rawData = GetSocialData()
    end

    PopulateRows(lbFrame.scrollChild, SortedEntries(rawData))

    -- Update social tab counts (skip friends — it has a fixed N/A label)
    local counts = { party=0, guild=0 }
    for _ in pairs(LB.GetPartyData())   do counts.party = counts.party + 1 end
    for _ in pairs(LB.GetGuildData())   do counts.guild = counts.guild + 1 end

    if lbFrame.socialTabs then
        for _, tab in ipairs(lbFrame.socialTabs) do
            if tab.key ~= "friends" then
                local c = counts[tab.key] or 0
                tab.label:SetText(tab.name .. " (" .. c .. ")")
            end
        end
    end

    -- Delve count for content row
    local delveCount = 0
    for _ in pairs(LB.GetDelveData()) do delveCount = delveCount + 1 end

    -- Update content row button labels and highlight
    if lbFrame.contentBtns then
        for _, cb in ipairs(lbFrame.contentBtns) do
            local active = (cb.filterKey == contentFilter)
            BD(cb, active and COLOR.TAB_ACTIVE or COLOR.TAB_IDLE, COLOR.BORDER)
            cb.label:SetTextColor(
                active and COLOR.ACCENT[1] or COLOR.TEXT_DIM[1],
                active and COLOR.ACCENT[2] or COLOR.TEXT_DIM[2],
                active and COLOR.ACCENT[3] or COLOR.TEXT_DIM[3], 1)
            -- Update Delve count in button label
            if cb.filterKey == "delve" then
                cb.label:SetText("Delves (" .. delveCount .. ")")
            end
        end
    end

    -- Update sort row highlight
    if lbFrame.sortBtns then
        for _, sb in ipairs(lbFrame.sortBtns) do
            local active = (sb.filterKey == contentFilter)
            BD(sb, active and COLOR.TAB_ACTIVE or COLOR.TAB_IDLE, COLOR.BORDER)
            sb.label:SetTextColor(
                active and COLOR.ACCENT[1] or COLOR.TEXT_DIM[1],
                active and COLOR.ACCENT[2] or COLOR.TEXT_DIM[2],
                active and COLOR.ACCENT[3] or COLOR.TEXT_DIM[3], 1)
        end
    end

    -- Column headers — reflect what each right-side column actually shows
    local catHdr, weekHdr
    if contentFilter == "delve" then
        catHdr = "TIER"
        weekHdr = "SCORE"
    elseif contentFilter == "dungeon" then
        catHdr = "DIFF / BOSS"
        weekHdr = "GRADE"
    elseif contentFilter == "raid" then
        catHdr = "DIFF / BOSS"
        weekHdr = "GRADE"
    elseif contentFilter == "alltime" then
        catHdr = "DIFFICULTY"
        weekHdr = "BEST"
    else  -- weekly
        catHdr = "DIFFICULTY"
        weekHdr = "WK AVG"
    end
    if lbFrame.hdrCat  then lbFrame.hdrCat:SetText(catHdr)   end
    if lbFrame.hdrWeek then lbFrame.hdrWeek:SetText(weekHdr) end

    -- Grey out social tabs when Delve is active (they don't apply)
    if lbFrame.socialTabs then
        for _, tab in ipairs(lbFrame.socialTabs) do
            local dim = isDelve
            tab.label:SetTextColor(
                dim and 0.35 or (tab.key == activeTab and COLOR.ACCENT[1] or COLOR.TEXT_DIM[1]),
                dim and 0.33 or (tab.key == activeTab and COLOR.ACCENT[2] or COLOR.TEXT_DIM[2]),
                dim and 0.30 or (tab.key == activeTab and COLOR.ACCENT[3] or COLOR.TEXT_DIM[3]), 1)
        end
    end
end

function LB.RefreshUI()
    if lbFrame and lbFrame:IsShown() then RefreshContent() end
end

local function SetActiveTab(key)
    activeTab = key
    if lbFrame and lbFrame.socialTabs then
        for _, tab in ipairs(lbFrame.socialTabs) do
            local isActive = (tab.key == key)
            BD(tab, isActive and COLOR.TAB_ACTIVE or COLOR.TAB_IDLE, COLOR.BORDER)
        end
    end
    RefreshContent()
end

local function SetContentFilter(key)
    contentFilter = key
    RefreshContent()
end

--------------------------------------------------------------------------------
-- Build frame
--------------------------------------------------------------------------------
local function CreateLeaderboardFrame()
    if lbFrame then return lbFrame end

    local FW, FH = 520, 480
    lbFrame = CreateFrame("Frame","MidnightSenseiLeaderboard",UIParent,"BackdropTemplate")
    lbFrame:SetSize(FW,FH)
    lbFrame:SetPoint("CENTER",UIParent,"CENTER",240,0)
    lbFrame:SetFrameStrata("HIGH")
    lbFrame:SetMovable(true); lbFrame:SetClampedToScreen(true); lbFrame:EnableMouse(true)
    BD(lbFrame)

    -- Title bar
    local tBar = CreateFrame("Frame",nil,lbFrame,"BackdropTemplate")
    tBar:SetPoint("TOPLEFT",lbFrame,"TOPLEFT",0,0)
    tBar:SetPoint("TOPRIGHT",lbFrame,"TOPRIGHT",0,0)
    tBar:SetHeight(26); BD(tBar, COLOR.TITLE_BG, COLOR.BORDER_GOLD)
    tBar:EnableMouse(true); tBar:RegisterForDrag("LeftButton")
    tBar:SetScript("OnDragStart",function() lbFrame:StartMoving() end)
    tBar:SetScript("OnDragStop", function() lbFrame:StopMovingOrSizing() end)

    local titleText = TF(tBar,12,"CENTER")
    titleText:SetPoint("CENTER"); titleText:SetTextColor(COLOR.TITLE_TEXT[1],COLOR.TITLE_TEXT[2],COLOR.TITLE_TEXT[3],1)
    titleText:SetText("Midnight Sensei - Leaderboard")

    local xBtn = CreateFrame("Button",nil,tBar)
    xBtn:SetSize(18,18); xBtn:SetPoint("RIGHT",tBar,"RIGHT",-4,0)
    local xFs = TF(xBtn,11,"CENTER"); xFs:SetPoint("CENTER"); xFs:SetText("X")
    xFs:SetTextColor(1,0.4,0.4,1)
    xBtn:SetScript("OnClick",function() lbFrame:Hide() end)

    -- ── Row 1: Social tabs (y = -26) — Party | Guild | Friends ─────────────
    -- Note: Friends tab is greyed out — BNGetFriendNumGameAccounts returns 0
    -- in Midnight 12.0, making cross-realm friend whisper enumeration impossible.
    -- Friends who share a guild or party still appear in those tabs.
    local socialDefs = {
        {key="party",   name="Party"},
        {key="guild",   name="Guild"},
        {key="friends", name="Friends", disabled=true},
    }
    local socialW = math.floor(FW / #socialDefs)
    lbFrame.socialTabs = {}
    for i, td in ipairs(socialDefs) do
        local tab = CreateFrame("Button", nil, lbFrame, "BackdropTemplate")
        tab:SetSize(socialW, 26)
        tab:SetPoint("TOPLEFT", lbFrame, "TOPLEFT", (i-1)*socialW, -26)
        BD(tab, COLOR.TAB_IDLE, COLOR.BORDER)
        tab.key  = td.key ; tab.name = td.name
        tab.label = TF(tab, 11, "CENTER") ; tab.label:SetPoint("CENTER")

        if td.disabled then
            -- Greyed out — BNet friend enumeration unavailable in Midnight 12.0
            tab.label:SetTextColor(0.35, 0.33, 0.30, 1)
            tab.label:SetText(td.name .. " |cff555555(N/A)|r")
            tab:EnableMouse(true)
            tab:SetScript("OnEnter", function()
                GameTooltip:SetOwner(tab, "ANCHOR_BOTTOM")
                GameTooltip:SetText("Friends (Unavailable)", 1, 0.8, 0.1)
                GameTooltip:AddLine("BNet friend enumeration is restricted in\nMidnight 12.0. Friends in your Guild or\nParty appear in those tabs instead.", 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end)
            tab:SetScript("OnLeave", function() GameTooltip:Hide() end)
            tab:SetScript("OnClick", function()
                -- Show a brief message in the scroll area instead of switching
                print("|cff00D1FFMidnight Sensei:|r Friends tab unavailable — BNet friend character enumeration is restricted in Midnight 12.0. Friends in your guild or party appear in those tabs.")
            end)
        else
            tab.label:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
            tab.label:SetText(td.name)
            tab:SetScript("OnClick", function()
                if contentFilter == "delve" then contentFilter = "weekly" end
                SetActiveTab(td.key)
            end)
        end
        table.insert(lbFrame.socialTabs, tab)
    end

    -- ── Row 2: Content filter (y = -52) — Delves | Dungeons | Raids ────────
    local contentDefs = {
        {key="delve",   name="Delves"},
        {key="dungeon", name="Dungeons"},
        {key="raid",    name="Raids"},
    }
    local contentW = math.floor(FW / #contentDefs)
    lbFrame.contentBtns = {}
    for i, cd in ipairs(contentDefs) do
        local btn = CreateFrame("Button", nil, lbFrame, "BackdropTemplate")
        btn:SetSize(contentW, 22)
        btn:SetPoint("TOPLEFT", lbFrame, "TOPLEFT", (i-1)*contentW, -52)
        BD(btn, COLOR.TAB_IDLE, COLOR.BORDER)
        btn.filterKey = cd.key
        btn.label = TF(btn, 10, "CENTER") ; btn.label:SetPoint("CENTER")
        btn.label:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
        btn.label:SetText(cd.name)
        btn:SetScript("OnClick", function() SetContentFilter(cd.key) end)
        table.insert(lbFrame.contentBtns, btn)
    end

    -- ── Row 3: Sort buttons (y = -74) — Week Avg | All-Time ─────────────────
    local sortDefs = {
        {key="weekly",  label="Week Avg"},
        {key="alltime", label="All-Time"},
    }
    local sortW = math.floor(FW / #sortDefs)
    lbFrame.sortBtns = {}
    for i, sd in ipairs(sortDefs) do
        local sb = CreateFrame("Button", nil, lbFrame, "BackdropTemplate")
        sb:SetSize(sortW, 20)
        sb:SetPoint("TOPLEFT", lbFrame, "TOPLEFT", (i-1)*sortW, -74)
        BD(sb, COLOR.TAB_IDLE, COLOR.BORDER)
        sb.filterKey = sd.key
        sb.label = TF(sb, 9, "CENTER") ; sb.label:SetPoint("CENTER")
        sb.label:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
        sb.label:SetText(sd.label)
        sb:SetScript("OnClick", function()
            contentFilter = sd.key
            RefreshContent()
        end)
        table.insert(lbFrame.sortBtns, sb)
    end

    -- ── Column headers (y = -96) ─────────────────────────────────────────────
    local hdr = CreateFrame("Frame", nil, lbFrame)
    hdr:SetPoint("TOPLEFT",  lbFrame, "TOPLEFT",   4, -96)
    hdr:SetPoint("TOPRIGHT", lbFrame, "TOPRIGHT", -20, -96)
    hdr:SetHeight(16)
    local function Hdr(t, anchor, x, w)
        local fs = TF(hdr, 9, anchor)
        fs:SetPoint(anchor, hdr, anchor, x, 0) ; fs:SetWidth(w)
        fs:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
        fs:SetText(t)
        return fs
    end
    Hdr("#",      "LEFT",   4,  20)
    Hdr("PLAYER", "LEFT",  36, 108)
    Hdr("SPEC",   "LEFT", 148,  70)
    lbFrame.hdrCat  = Hdr("DIFF / BOSS", "LEFT", 222, 230)
    lbFrame.hdrWeek = Hdr("WK AVG",      "RIGHT", -2,  62)

    -- ── Scroll (starts at y = -114) ──────────────────────────────────────────
    local sf = CreateFrame("ScrollFrame", "MidnightSenseiLBScroll", lbFrame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     lbFrame, "TOPLEFT",   4, -114)
    sf:SetPoint("BOTTOMRIGHT", lbFrame, "BOTTOMRIGHT", -22, 36)
    local sc = CreateFrame("Frame", nil, sf)
    sc:SetWidth(sf:GetWidth()) ; sc:SetHeight(200) ; sf:SetScrollChild(sc)
    lbFrame.scrollChild = sc

    -- Footer
    local footerText = TF(lbFrame,9,"LEFT")
    footerText:SetPoint("BOTTOMLEFT",lbFrame,"BOTTOMLEFT",8,12)
    footerText:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
    footerText:SetText("Week Avg = boss kills only  *  D=Dungeon  R=Raid  *  /ms lb")

    -- Refresh button — must use CreateFrame with BackdropTemplate AND EnableMouse
    -- so it has a proper hit region and receives clicks
    local refreshBtn = CreateFrame("Button", nil, lbFrame, "BackdropTemplate")
    refreshBtn:SetSize(68, 20)
    refreshBtn:SetPoint("BOTTOMRIGHT", lbFrame, "BOTTOMRIGHT", -6, 8)
    refreshBtn:EnableMouse(true)
    refreshBtn:RegisterForClicks("LeftButtonUp")
    BD(refreshBtn, COLOR.TAB_IDLE, COLOR.BORDER)
    local rFs = TF(refreshBtn, 10, "CENTER")
    rFs:SetPoint("CENTER")
    rFs:SetText("Refresh")
    refreshBtn:SetScript("OnEnter", function()
        BD(refreshBtn, COLOR.TAB_ACTIVE, COLOR.BORDER)
        rFs:SetTextColor(COLOR.ACCENT[1], COLOR.ACCENT[2], COLOR.ACCENT[3], 1)
    end)
    refreshBtn:SetScript("OnLeave", function()
        BD(refreshBtn, COLOR.TAB_IDLE, COLOR.BORDER)
        rFs:SetTextColor(COLOR.TEXT_MAIN[1], COLOR.TEXT_MAIN[2], COLOR.TEXT_MAIN[3], 1)
    end)
    refreshBtn:SetScript("OnClick", function()
        rFs:SetText("...")
        if activeTab == "guild" then SyncGuildOnlineStatus() end
        BroadcastHello()
        local reqPayload = "REQ|" .. Core.VERSION
        BroadcastToAll(reqPayload)
        C_Timer.After(1.5, function()
            RefreshContent()
            rFs:SetText("Refresh")
        end)
    end)

    -- Week info
    local weekInfo = TF(lbFrame,9,"RIGHT")
    weekInfo:SetPoint("BOTTOMRIGHT",lbFrame,"BOTTOMRIGHT",-72,12)
    weekInfo:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
    weekInfo:SetText("Week "..GetWeekKey())

    lbFrame:Hide()
    return lbFrame
end

function LB.Show()
    local frame = CreateLeaderboardFrame()
    SeedPartyFromGroup()   -- ensure current group is always shown when opening
    SetActiveTab(activeTab)
    frame:Show()
    RefreshContent()
end

function LB.Toggle()
    local frame = CreateLeaderboardFrame()
    if frame:IsShown() then frame:Hide() else LB.Show() end
end

function LB.HideFrame()
    if lbFrame then lbFrame:Hide() end
end

--------------------------------------------------------------------------------
-- Event frame
--------------------------------------------------------------------------------
local lbEventFrame = CreateFrame("Frame","MidnightSenseiLBEvents",UIParent)

lbEventFrame:SetScript("OnEvent",function(self,event,...)
    if event=="CHAT_MSG_ADDON" then
        OnAddonMessage(...)
    elseif event=="GUILD_ROSTER_UPDATE" then
        SyncGuildOnlineStatus()
    elseif event=="GROUP_ROSTER_UPDATE" then
        local current={}
        for i=1,GetNumGroupMembers() do
            local unit=(IsInRaid() and "raid" or "party")..i
            local name=UnitName(unit)
            if name then current[name]=true end
        end
        for name in pairs(partyData) do
            if not current[ShortName(name)] then partyData[name]=nil end
        end
        LB.RefreshUI()
    end
end)

lbEventFrame:RegisterEvent("CHAT_MSG_ADDON")
lbEventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
lbEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

C_ChatInfo.RegisterAddonMessagePrefix(LB_PREFIX)
